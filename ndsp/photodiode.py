import time
import board
import busio
import neopixel
import supervisor
import sys
import adafruit_ads1x15.ads1115 as ADS
from adafruit_ads1x15.analog_in import AnalogIn
from digitalio import DigitalInOut, Direction, Pull
from adafruit_debouncer import Debouncer

class Photodiode:
    '''
    Class for a module with a photodiode and possibly a shutter
    Handles both recieving commands and sending data for photodiode.
    '''

    def __init__(self, data_buffer_size=1, recording_period=1.0, shutter=False, log_length=128, led_brightness=128):
        '''
        Initialize all board in and out pins and variables necesssary.
        data_buffer_size: int representing how many data points to read inbetween sends.
        recording_period: float representing how long to record before sending.
        shutter: boolean representing whether this module has a shutter.
        log_length: int representing how many log entries to keep track of
        led_brightness: int[0, 255] representing led brightness (so you can turn them off if you want)
        '''

        self.shutter = shutter
        
        if self.shutter:
            self.BUTTON_PIN1 = board.GP12
            self.BUTTON_PIN2 = board.GP10
            self.SHUTTER_PIN = board.GP7

            self.button1 = DigitalInOut(self.BUTTON_PIN1)
            self.button2 = DigitalInOut(self.BUTTON_PIN2)
            self.shutter_pin = DigitalInOut(self.SHUTTER_PIN)

            self.button1.direction = Direction.INPUT
            self.button1.pull = Pull.UP

            self.button2.direction = Direction.INPUT
            self.button2.pull = Pull.UP

            self.shutter_pin.direction = Direction.OUTPUT

            self.sw1 = Debouncer(self.button1)
            self.sw2 = Debouncer(self.button2)

            self.mode = 'c'
            self.opened = False
            self.last_oscillation = time.monotonic()

        self.led = neopixel.NeoPixel(board.GP16, 1)
        self.led.brightness = 0.3

        self.i2c = busio.I2C(board.GP15, board.GP14)
        self.ads = ADS.ADS1115(self.i2c)
        self.chan = AnalogIn(self.ads, ADS.P0)

        self.data_buffer_size = data_buffer_size
        self.recording_period = recording_period

        self.photodiode_buffer = [0] * self.data_buffer_size
        self.pd_buffer_pos = 0

        self.string_buffer = ''

        self.log = []
        self.log_length = log_length

        self.led_brightness = led_brightness

        # flicker LED's and open shutter if possible on startup
        self.led[0] = (25, 0, 0)
        time.sleep(0.1)
        self.led[0] = (0, 25, 0)
        time.sleep(0.1)
        self.led[0] = (0, 0, 25)
        time.sleep(0.1)
        self.led[0] = (0, 0, 0)
        
        if self.shutter:
            self.open_shutter()

        self.start()

    def start(self):
        delta = self.recording_period / self.data_buffer_size

        last_read = time.monotonic()
        last_send = time.monotonic()

        while True:
            self.sw1.update()
            self.sw2.update()

            if not self.sw1.value and not self.sw2.value:
                self.mode = 'b'
            elif self.sw1.fell:
                self.open_shutter()
                self.mode = 'o'
            elif self.sw2.fell:
                self.close_shutter()
                self.mode = 'c'

            self.parse_input(self.recieve_input())

            if self.mode == 'b':
                self.oscillate()

            # If sufficient time has passed read photodiode value and write into buffer
            now = time.monotonic()
            if now - last_read >= delta:
                last_read = now
                value = self.chan.value

                self.photodiode_buffer[self.pd_buffer_pos] = value
                self.pd_buffer_pos += 1
                self.pd_buffer_pos %= self.data_buffer_size

            # If sufficient time has passed send data buffer
            now = time.monotonic()
            if now - last_send >= self.recording_period:
                last_send = now

                to_send = []
                ind = self.pd_buffer_pos
                for offset in range(self.data_buffer_size):
                    to_send.append(self.photodiode_buffer[(ind + offset) % self.data_buffer_size])

                self.transmit_data(to_send)

    # All data transmissions will start with '\0\x7F' = '\x00\x7f' and end with '\n'
    def transmit_data(self, data):
        out = b'\x00\x7f'

        for i in data:
            out += i.to_bytes(2, 'big')
        
        out += b'\n\n'

        sys.stdout.write(out)

    # All string transmissions will start with '\0\0\x7F' = '\x00\x00\x7f' and end with '\n'
    def transmit_string(self, string):
        sys.stdout.write(f'\0\0\x7F{string}\n\n'.encode())

    def recieve_input(self):
        '''
        Get input. Uses sys.stdin.readline() which seems to be the most consistent
        '''

        if not supervisor.runtime.serial_bytes_available:
            return ''
        
        return sys.stdin.readline()
    
    def parse_input(self, inp):
        '''
        Parse the input which it gets and do actions on it. Must be '\n' separated if multiple.
        Can handle multiple at once but this will probably be rare.
        '''

        if not inp:
            return
        
        for ch in inp.strip().split('\n'):
            entry = f'Command recieved: {ch}'

            if not self.shutter and ch in ['o', 'c', 'b']:
                self.log.append(f'Command {ch} recieved but no shutter available\n')
                if len(self.log) > self.log_length:
                    self.log.remove(0)
                
                continue
            
            if ch == 's':
                self.mode = 's'
                self.stop()
            elif ch == 'o':
                self.open_shutter()
                entry += '\nShutter opened.'
                self.mode = 'o'
            elif ch == 'c':
                self.close_shutter()
                entry += '\nShutter closed.'
                self.mode = 'c'
            elif ch == 'b':
                self.oscillate()
                entry += '\nBegan oscillating.'
                self.mode = 'b'
            elif ch == 'v':
                entry += '\nSending single photodiode value.'
                self.transmit_string(f'Photodiode value: {self.chan.value}')
            elif ch == 'l':
                entry += '\nSending log.'
                self.log.append(entry)
                self.send_log()
                entry = 'Just sent log.'

            self.log.append(entry)

            if len(self.log) > self.log_length:
                self.log.remove(0)

    def stop(self):
        # Exits to REPL
        sys.exit()

    def send_log(self):
        # Sends log and clears
        self.transmit_string('\n'.join(self.log))
        self.log = []

    def open_shutter(self):
        if not self.shutter:
            return
        
        # Opens the shutter
        self.led[0] = (0, self.led_brightness, 0)
        self.shutter_pin.value = True
        self.led[0] = (0, 0, 0)
        
    def close_shutter(self):
        if not self.shutter:
            return
        
        # Closes the shutter
        self.led[0] = (self.led_brightness, 0, 0)
        self.shutter_pin.value = False
        self.led[0] = (0, 0, 0)
        
    def oscillate(self):
        # Oscillates every 0.5s. Called when self.mode == 'b' (Back and forth)
        now = time.monotonic()

        if now - self.last_oscillation >= 0.5:
            self.last_oscillation = now

            if self.opened:
                self.close_shutter()
                self.opened = False
            else:
                self.open_shutter()
                self.opened = True
