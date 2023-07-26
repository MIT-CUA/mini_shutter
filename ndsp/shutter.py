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


class Shutter:
    def __init__(self, data_buffer_size=1, recording_period=0.5, pd=None):
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

        try:
            self.i2c = busio.I2C(board.GP15, board.GP14)
            self.ads = ADS.ADS1115(self.i2c)
            self.chan = AnalogIn(self.ads, ADS.P0)
            self.pd = pd if pd is not None else True
        except:
            self.pd = False


        self.data_buffer_size = data_buffer_size
        self.recording_period = recording_period

        self.input_buffer = b""
        self.output_string_buffer = ""
        self.output_data_buffer = b""
        self.photodiode_buffer = [0] * self.data_buffer_size
        self.pd_buffer_pos = 0

        self.mode = 'c'
        self.opened = False
        self.last_oscillation = time.monotonic()

        self.log = []

        # flicker LED's and open shutter on startup
        self.led[0] = (5, 0, 0)
        time.sleep(0.1)
        self.led[0] = (0, 5, 0)
        time.sleep(0.1)
        self.led[0] = (0, 0, 5)
        time.sleep(0.1)
        self.led[0] = (0, 0, 0)
        
        self.open_shutter()

        self.start()

    def start(self):
        delta = self.recording_period / self.data_buffer_size
        
        last_print = time.monotonic()
        last_read = time.monotonic()

        while True:
            self.sw1.update()
            self.sw2.update()

            if self.sw1.fell:
                self.open_shutter()
            elif self.sw2.fell:
                self.close_shutter()

            self.receive_input()
            self.parse_input()

            self.input_buffer = b""

            if self.mode == 'b':
                self.oscillate()

            now = time.monotonic()
            if now - last_print >= self.recording_period:
                ind = self.pd_buffer_pos + 1

                for offset in range(self.data_buffer_size):
                    self.write_integer_to_buffer(self.photodiode_buffer[(ind + offset) % self.data_buffer_size])

                last_print = now

            now = time.monotonic()
            if now - last_read >= delta:
                last_read = now
                value = 0 if not self.pd else self.chan.value

                self.photodiode_buffer[self.pd_buffer_pos] = value
                self.pd_buffer_pos += 1
                self.pd_buffer_pos %= self.data_buffer_size

            self.send_output()

    def try_create_pd_connection(self):
        try:
            self.i2c = busio.I2C(board.GP15, board.GP14)
            self.ads = ADS.ADS1115(self.i2c)
            self.chan = AnalogIn(self.ads, ADS.P0)
            self.pd = True
        except:
            self.pd = False

        return self.pd

    def receive_input(self):
        if not supervisor.runtime.serial_bytes_available:
            self.input_buffer = b""
            return
        
        self.input_buffer = sys.stdin.readline().strip()

        # self.log.append(f'input received: {self.input_buffer}')

    def parse_input(self):
        if not self.input_buffer:
            return
        
        for ch in self.input_buffer:
            if ch == 's':
                self.mode = 's'
                self.stop()
            elif ch == 'o':
                self.open_shutter()
                self.write_string_to_buffer('open')
                self.mode = 'o'
            elif ch == 'c':
                self.close_shutter()
                self.write_string_to_buffer('closed')
                self.mode = 'c'
            elif ch == 'b':
                self.oscillate()
                self.write_string_to_buffer('osc')
                self.mode = 'b'
            elif ch == 'v':
                self.read_and_write_value()

    def process_buttons(self):
        self.sw1.update()		# button debouncing
        self.sw2.update()

        if not self.sw1.value:
            self.open_shutter()
            
            while not self.sw1.value:    # Wait for button to be released
                if not self.sw2.value:	# if both buttons pushed
                    self.mode = "b"
                
                self.sw1.update()
                self.sw2.update()
            
            return
            
        if not self.sw2.value:
            self.close_shutter()

            while not self.sw2.value:    # Wait for button to be released
                if not self.sw1.value:	# if both buttons pushed
                    self.mode = ""
                
                self.sw1.update()
                self.sw2.update()
            
            return

    def send_output(self):
        if not self.output_data_buffer:
            return
        
        out = b""

        len_d = len(self.output_data_buffer) // 2
        # unused for now
        # len_d = len(self.output_data_buffer)
        
        # Only send data if we actually have a (detected) photodiode
        out += (0 if not self.pd else len_d).to_bytes(2, 'big')
        if self.pd:
            out += self.output_data_buffer
        
        out += self.output_string_buffer.encode()

        sys.stdout.write(out)

        self.output_string_buffer = ""
        self.output_data_buffer = b""

    def send_log(self, kill=False):
        sys.stdout.write(('\n'.join(self.log) + '\n').encode())

        if kill:
            sys.exit()

    def write_string_to_buffer(self, s):
        self.output_string_buffer += s + '\n'

    def write_integer_to_buffer(self, i):
        self.output_data_buffer += i.to_bytes(2, 'big')

    def open_shutter(self):
        self.led[0] = (0, 255, 0)
        self.shutter_pin.value = True
        self.led[0] = (0, 0, 0)

    def close_shutter(self):
        self.led[0] = (255, 0, 0)
        self.shutter_pin.value = False
        self.led[0] = (0, 0, 0)

    def oscillate(self):
        now = time.monotonic()
    
        if now - self.last_oscillation >= 0.5:
            self.last_oscillation = now

            if self.opened:
                self.led[0] = (50, 0, 0)
                self.close_shutter()
                self.mode = 'c'
                self.opened = False
            else:
                self.led[0] = (0, 0, 50)
                self.open_shutter()
                self.mode = 'o'
                self.opened = True

    def read_and_write_value(self):
        self.write_string_to_buffer(f'val={0 if not self.pd else self.chan.value}')

    def stop(self):
        self.send_log(kill=True)
