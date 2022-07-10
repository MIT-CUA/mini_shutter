#
# mini_shutterpy: run 4mm coreless DC motor (used for an optical shutter)
# either back and forth - opening and closing repeatedly
# or button pushes to open & close
#

import time
import board
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

motor_open = DigitalInOut(board.GP7)
motor_close = DigitalInOut(board.GP6)
motor_open.direction = Direction.OUTPUT
motor_close.direction = Direction.OUTPUT
motor_open.value = False
motor_close.value = False

sw1 = Debouncer(the_button)
sw2 = Debouncer(the_button2)

led = neopixel.NeoPixel(board.GP16, 1)
led.brightness = 0.3

print("test_motor.py")

def shutter_open():
    led[0] = (255, 0, 0)
    motor_open.value = True
    time.sleep(0.1)
    motor_open.value = False
    led[0] = (0, 0, 0)
    print("open")
    
def shutter_close():
    led[0] = (0, 255, 0)
    motor_close.value = True
    time.sleep(0.1)
    motor_close.value = False
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
