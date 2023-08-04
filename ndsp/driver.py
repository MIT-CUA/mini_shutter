import serial
import time
from datetime import datetime
import threading
import os
import numpy
import matplotlib
from matplotlib import pyplot as plt


class MiniShutter:
    """For controlling mini shutter
    
    see https://github.mit.edu/quanta/mini_shutter for detail on the shutters
    """
    def __init__(self, serial_port='/dev/ttyACM6', baudrate=9600, timeout=0.1, check_delay=0.1):
        self.shutter = serial.Serial(port=serial_port, baudrate=baudrate, timeout=timeout)

        self.check_delay = check_delay

        self.last_data_frame = []
        self.Y = [0] * 64

        self._read_thread = threading.Thread(target=self.begin_reading, daemon=True)
        self._read_thread.start()

    # reads serial data from shutter (such as print statements)
    # includes data this sends to it
    def begin_reading(self):
        while True:
            len_d = int.from_bytes(self.shutter.read(2), 'big')

            data = []
            if len_d > 256:
                print('got garbage input') # here I am assuming that no more than 256 data points are being sent at once
            else:
                data = [0 for _ in range(len_d)]
            
                for i in range(len_d - 1, -1, -1):
                    data[i] = int.from_bytes(self.shutter.read(2), 'big')

            while self.shutter.in_waiting > 0:
                ch = self.shutter.read(1)
                try:
                    print(ch.decode(), end="")
                except:
                    print('couldn\'t parse')

            if data:
                print(f'{datetime.now()}\t\tdata ({len(data)}): {data}')
                self.last_data_frame = data.copy()

            time.sleep(self.check_delay)

    def write(self, path):
        if not os.path.isfile(path):
            with open(path, 'w+') as _:
                pass

        with open(path, 'a') as out:
            out.write(f'{datetime.now()}: {self.last_data_frame}\n')

    def stats(self):
        arr = numpy.array(self.last_data_frame)

        print(f'len: {len(arr)}, avg: {arr.mean()}, stdev: {arr.std()}')

    def stop(self):
        self.shutter.write(b"s\r")

    def open(self):
        self.shutter.write(b"o\r")

    def close(self):
        self.shutter.write(b"c\r")
        
    def oscillate(self):
        self.shutter.write(b"b\r")

    def read_value(self):
        self.shutter.write(b"v\r")

    def write_string(self, s):
        self.shutter.write(f'{s}\r'.encode())

    # Reload rp2040 if in REPL (Im pretty sure)
    def reload(self):
        # This sends ctrl+D (EOT) which is the reload command
        self.shutter.write(b'\x04')

    # Stop the currently running program on the rp2040
    def kill_program(self):
        # This sends ctrl+C, should stop execution
        # not
        self.shutter.write(b'\x03')
        
    def help(self):
        self.shutter.write(b"h\r")

    def log(self):
        self.shutter.write(b"l\r")
