#
# mini_shutterpy: run 4mm coreless DC motor (used for an optical shutter)
# either back and forth - opening and closing repeatedly
# or button pushes to open & close
#

import time
import board
import pwmio
import usb_hid
import neopixel
import supervisor
from digitalio import DigitalInOut, Direction, Pull
from adafruit_debouncer import Debouncer

BUTTON_PIN = board.GP27
the_button = DigitalInOut(BUTTON_PIN)		# button digital input
the_button.direction = Direction.INPUT
the_button.pull = Pull.UP

BUTTON_PIN2 = board.GP15
the_button2 = DigitalInOut(BUTTON_PIN2)		# button digital input
the_button2.direction = Direction.INPUT
the_button2.pull = Pull.UP

# motor_open = DigitalInOut(board.GP7)
# motor_close = DigitalInOut(board.GP6)

motor_open_pins  = [ board.GP0, board.GP1, board.GP2 ]
motor_close_pins = [ board.GP4, board.GP5, board.GP6 ]
motor_open  = [ pwmio.PWMOut(m, frequency=500, duty_cycle=0) for m in motor_open_pins ]
motor_close = [ pwmio.PWMOut(m, frequency=500, duty_cycle=0) for m in motor_close_pins ]

sw1 = Debouncer(the_button)
sw2 = Debouncer(the_button2)

led = neopixel.NeoPixel(board.GP16, 1)
led.brightness = 0.3

print("mini_shutter.py")

def shutter_open():
    led[0] = (25, 0, 0)
    for m in motor_close:
        m.duty_cycle = 0
    for cycle in range(32768, 65535, 1000):
        for m in motor_open:
            m.duty_cycle = cycle
    time.sleep(0.3)
    for m in motor_open:
        m.duty_cycle = 10000	# keep slightly powered
    led[0] = (0, 0, 0)
    print("open")
    
def shutter_close():
    led[0] = (0, 25, 0)
    for m in motor_open:
        m.duty_cycle = 0
    for cycle in range(32768, 65535, 1000):
        for m in motor_close:
            m.duty_cycle = cycle
    time.sleep(0.3)
    for m in motor_close:
        m.duty_cycle = 0
    led[0] = (0, 0, 0)
    print("close")

def process_buttons():
    sw1.update()		# button debouncing
    sw2.update()
    if not sw1.value:
        shutter_open()
        while not sw1.value:    # Wait for button to be released
            sw1.update()
            pass
        
    if not sw2.value:
        shutter_close()
        while not sw2.value:    # Wait for button to be released
            sw2.update()
            pass

def oscillate():
    shutter_open()
    time.sleep(0.5)
    shutter_close()
    time.sleep(0.5)

while True:
    process_buttons()
    # oscillate()
