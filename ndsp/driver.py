import serial
import time
from datetime import datetime
import threading
import os
import numpy
import sys
from influxdb_client import Point, WritePrecision, InfluxDBClient
from influxdb_client.client.write_api import SYNCHRONOUS

class ShutterHandler:
    '''
    Handles all communication with shutters and/or photodiodes.
    Writes data to InfluxDB.
    Accepts calibration functions to scale photodiode value to accurate power level.
    '''
    
    def __init__(
            self,
            photodiode=False,
            shutter=True,
            debug=False,
            serial_port='/dev/ttyACM0',
            baudrate=115200,
            timeout=0.1,
            check_delay=0.05,
            name='no_name_given'):
        '''
        Initialize all variables and serial connection.
        photodiode: boolean representing whether desired module has a photodiode
        shutter: boolean representing whether desired module has a shutter
        serial_port: string representing the serial port connection name
        baudrate: int representing the connection baudrate
        timeout: float representing how long until timeout when connecting
        check_delay: float representing how often to check for data from connection
        name: string, what files (e.g. calibrations/{name}_func.txt) are called and how its labeled in InfluxDB
        '''
        
        self.connection = serial.Serial(port=serial_port, baudrate=baudrate, timeout=timeout)
        self.check_delay = check_delay
        
        self.photodiode = photodiode
        self.shutter = shutter

        self.name = name

        self.has_avg = False
        self.avg = 0.0

        # Try to read calibrated function from file, otherwise just do a 1:1 mapping
        try:
            self.load_func()
        except:
            self.func = lambda v: v            

        if debug:
            self._comm_thread = threading.Thread(target=self.send_through, daemon=True)
        else:
            self._comm_thread = threading.Thread(target=self.begin_communicating, daemon=True)

        if self.photodiode:
            self.last_data_frame = []

        self._comm_thread.start()
        self.writing = False

    def setfunc(self, func):
        # Set the current function based on input and then save it
        # func: function or tuple, can be callable or tuple representing coefficients (a, b)

        if callable(func):
            self.func = func
        elif isinstance(func, tuple):
            self.func = lambda v: func[0] * v + func[1]
        else:
            raise ValueError('Only accepts callable functions or coefficient tuples (a, b)')
        
        self.save_func()
        
    def save_func(self):
        # Save the current function to file ./calibrations/{name}_func.txt

        b = self.func(0)
        a = self.func(1) - b

        if not os.path.exists('./calibrations'):
            os.makedirs('./calibrations')

        with open(f'calibrations/{self.name}_func.txt', 'w') as f:
            f.write(f'{a} {b}')

    def load_func(self):
        # Load function from file corresponding to self.name
        
        with open(f'calibrations/{self.name}_func.txt', 'r') as f:
            a, b = map(float, f.readline().split(' '))
            self.func = lambda v: a * v + b

    def print_func(self):
        b = self.func(0)
        a = self.func(1) - b

        print(f'a: {a}, b: {b}')

    def start_writing(self, func=None, write_api=None, bucket='laser_power_monitors', org='Quanta Lab'):
        '''
        Start writing values to InfluxDB
        func: callable, can be used instead of setfunc or load_func
        write_api: InfluxDB write_api object, can give custom api if you want
        bucket: string representing what bucket in InfluxDB to write to
        org: string representing organization in InfluxDB
        '''
        
        if self.writing:
            print('Already writing.')
            return
        if not self.photodiode:
            print('No photodiode to measure with')
            return
        
        if callable(func):
            self.func = func
        
        if write_api is None:
            token = "ZrEoGqLx_FTx6_ZIXeRcUd7t-79XJw-u9j4McL55iKyPCyuWk9Tdwz33ig2pU09LG1jJT0Lz4oDFX6UMqoyW1w=="
            client = InfluxDBClient(url='http://192.168.5.232:8086', token=token)

            write_api = client.write_api(write_options=SYNCHRONOUS)
        
        self.writing = True
        self._write_thread = threading.Thread(target=self.write_to_influx, args=(write_api, bucket, org), daemon=True)
        self._write_thread.start()

    def write_to_influx(self, write_api, bucket, org):
        # Thread which is started by start_writing

        while True:
            try:
                if self.has_avg:
                    avg = self.avg
                    self.has_avg = False

                    point = (Point(bucket)
                             .tag('sensors', self.name)
                             .field('Photodiode value', max(0.0, self.func(avg)))
                             .time(datetime.utcnow(), WritePrecision.NS)
                             )
                    
                    write_api.write(bucket, org, point)

                    print(f'Successfully wrote to InfluxDB: {max(0.0, self.func(avg))}')
            except Exception as e:
                print(f'Error while writing to InfluxDB:\n{e}')

            time.sleep(2)

    def send_through(self):
        # Send through what is recieved from the shutter straight to stdout without parsing

        while True:
            while self.connection.in_waiting > 0:
                print(self.connection.read_until(expected='\r\n').decode(), end='')

            time.sleep(self.check_delay)
    
    def begin_communicating(self):
        # Communicate (usually with a photodiode), parse communications and send things
        
        if not self.photodiode:
            # Since we don't have a photodiode just read data forever.
            # This only ends once self.disconnect() is called.
            self.send_through()

        while True:
            if self.connection.in_waiting > 0:
                all = self.connection.read_all().replace(b'\r\n', b'\n')

                if all[-2:] != b'\n\n':
                    print('########### Invalid transmission recieved ###########')
                    continue
                
                recs = [i + b'\n\n' for i in all[:-2].split(b'\n\n')]

                for rec in recs:
                    if rec[0] == 0 and rec[1] == 0 and rec[2] == 127:
                        # Recieved string transmission
                        print(rec[3:-1].decode(), end='')
                    elif rec[0] == 0 and rec[1] == 127:
                        # Recieved data transmission
                        data = [int.from_bytes(rec[i:i+2], 'big') for i in range(2, len(rec[2:-1]), 2)]
                        self.last_data_frame = data.copy()
                        self.has_avg = True
                        try:
                            self.avg = sum(data) / len(data)
                        except ZeroDivisionError:
                            self.has_avg = False

                        print(f'{datetime.now()}\tdata ({len(data)}): {data}')
                    else:
                        print('########### Invalid transmission ###########')

            time.sleep(self.check_delay)

    def stop(self):
        # Forces RP2040 into REPL
        self.connection.write(b's\n')
    
    def disconnect(self):
        # Closes serial connection
        self.connection.close()
        sys.exit()

    def open(self):
        # Opens shutter
        self.connection.write(b'o\n')

    def close(self):
        # Closes shutter
        self.connection.write(b'c\n')

    def oscillate(self):
        # Oscillates shutter every 0.5s
        self.connection.write(b'b\n')

    def read_value(self):
        # Read and print singular photodiode value
        self.connection.write(b'v\n')

    def reload(self):
        # Reloads RP2040 from REPL into main.py
        self.connection.write(b'\x04') # Sends ctrl+D

    def kill(self):
        # Kills process running on RP2040 and forces into REPL (quickly)
        self.connection.write(b'\x03') # Sends ctrl+C

    def log(self):
        # Sends log of actions back through serial connection
        self.connection.write(b'l\n')

    def write_char(self, ch):
        # Write a single arbitrary character followed by '\r' to RP2040
        self.connection.write((ch + '\n').encode())

    def write(self, path):
        if not os.path.isfile(path):
            with open(path, 'w+') as _:
                pass

        with open(path, 'a') as out:
            out.write(f'{datetime.now()}: {self.last_data_frame}\n')
