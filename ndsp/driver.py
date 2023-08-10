import serial
import time
from datetime import datetime
import threading
import os
import numpy
import sys
from influxdb_client import Point, WritePrecision
import asyncio

class InfluxDBWriter:
    def __init__(self, obj, bucket, org, write_api):
        assert isinstance(obj, ShutterHandler)
        self.handler = obj

        self.bucket = bucket
        self.org = org
        self.write_api = write_api

        asyncio.run(self.start())

    async def start(self):
        while True:
            try:
                if self.handler.has_avg:
                    avg = self.handler.avg
                    self.handler.has_avg = False

                    point = (Point(self.bucket)
                             .tag('sensors', self.handler.name)
                             .field('Photodiode value', avg)
                             .time(datetime.utcnow(), WritePrecision.NS)
                             )

                    self.write_api.write(self.bucket, self.org, point)
                    print(f'Successfully wrote to InfluxDB: {avg}')
            except Exception as e:
                print(f'Error while writing to InfluxDB:\n{e}')

            await asyncio.sleep(1)

class ShutterHandler:
    '''
    Handles all communication with shutters and/or photodiodes
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
        '''
        
        self.connection = serial.Serial(port=serial_port, baudrate=baudrate, timeout=timeout)
        self.check_delay = check_delay
        
        self.photodiode = photodiode
        self.shutter = shutter

        self.name = name

        self.has_avg = False
        self.avg = 0.0

        if debug:
            self._comm_thread = threading.Thread(target=self.send_through, daemon=True)
            self._comm_thread.start()

        if self.photodiode:
            self.last_data_frame = []
            
        self._comm_thread = threading.Thread(target=self.begin_communicating, daemon=True)
        self._comm_thread.start()

    def send_through(self):
        while True:
            while self.connection.in_waiting > 0:
                print(self.connection.read_until(expected='\r\n').decode(), end='')

            time.sleep(self.check_delay)
    
    def begin_communicating(self):
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
