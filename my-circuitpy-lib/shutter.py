import time
import board
import neopixel
import supervisor
import sys
from digitalio import DigitalInOut, Direction, Pull
from adafruit_debouncer import Debouncer

class Shutter:
    '''
    Class for a module with a shutter.
    Only handles recieving commands for shutter, sends no data besides logs (maybe)
    '''

    def __init__(self, log_length=128, led_brightness=128):
        '''
        Initialize all board pinouts and variables necessary
        log_length: int which represents maximum log entries to track, default 128
        '''

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

        self.led = neopixel.NeoPixel(board.GP16, 1)
        self.led.brightness = 0.3

        self.mode = 'c'
        self.opened = False
        self.last_oscillation = time.monotonic()

        self.log = []
        self.log_length = log_length

        self.led_brightness = led_brightness

        # flicker LED's and open shutter on startup
        self.led[0] = (25, 0, 0)
        time.sleep(0.1)
        self.led[0] = (0, 25, 0)
        time.sleep(0.1)
        self.led[0] = (0, 0, 25)
        time.sleep(0.1)
        self.led[0] = (0, 0, 0)

        self.open_shutter()
        self.start()

    def start(self):
        '''
        Begin the shutters main loop.
        Recieves inputs and opens/closes the shutters accordingly.
        '''
        
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

    def recieve_input(self):
        '''
        Get input. Uses input() which seems to be the best way (according to adafruit)
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

            if ch == 's':
                self.mode = 's'
                self.stop()
            elif ch == 'o':
                sys.stdout.write('open\n'.encode())
                self.open_shutter()
                entry += '\nShutter opened.'
                self.mode = 'o'
            elif ch == 'c':
                sys.stdout.write('close\n'.encode())
                self.close_shutter()
                entry += '\nShutter closed.'
                self.mode = 'c'
            elif ch == 'b':
                self.oscillate()
                entry += '\nBegan oscillating.'
                self.mode = 'b'
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
        sys.stdout.write(('\n'.join(self.log) + '\n').encode())
        self.log = []

    def open_shutter(self):
        # Opens the shutter
        self.led[0] = (0, self.led_brightness, 0)
        self.shutter_pin.value = True
        self.led[0] = (0, 0, 0)

    def close_shutter(self):
        # Closes the shutter
        self.led[0] = (self.led_brightness, 0, 0)
        self.shutter_pin.value = False
        self.led[0] = (0, 0, 0)
    
    def oscillate(self):
        # Oscillates every 0.5s. Called when self.mode == 'b' (back and forth)
        now = time.monotonic()

        if now - self.last_oscillation >= 0.5:
            self.last_oscillation = now

            if self.opened:
                self.close_shutter()
                self.opened = False
            else:
                self.open_shutter()
                self.opened = True
