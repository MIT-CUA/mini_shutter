#
# mini_shutter2.py: run 4mm coreless DC motor (used for an optical shutter)
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

# BUTTON_PIN = board.GP27
BUTTON_PIN = board.GP12
the_button = DigitalInOut(BUTTON_PIN)		# button digital input
the_button.direction = Direction.INPUT
the_button.pull = Pull.UP

# BUTTON_PIN2 = board.GP15
BUTTON_PIN2 = board.GP10
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

print("mini_shutter2.py")
print("(h) help")

def shutter_open():
    led[0] = (5, 0, 0)
    for m in motor_close:
        m.duty_cycle = 0
    for cycle in range(32768, 65535, 1000):
        for m in motor_open:
            m.duty_cycle = cycle
    time.sleep(0.3)
    for m in motor_open:
        # m.duty_cycle = 10000	# keep slightly powered
        m.duty_cycle = 0	# unpowered
    led[0] = (0, 0, 0)
    print("open")
    
def shutter_close():
    led[0] = (0, 5, 0)
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

mode = ""
opened = False
last_time = time.monotonic()

def oscillate():
    global opened, last_time
    now = time.monotonic()
    if now-last_time < 0.5:
        return
    last_time = now
    if opened:
        shutter_close()
        opened = False
    else:
        shutter_open()
        opened = True

def process_input():
    global mode
    if not supervisor.runtime.serial_bytes_available:
        return
    value = input().strip()
    if value=="r":
        print("running oscillation...")
        mode = "osc"
    elif value=="o":
        mode = ""
        shutter_open()
    elif value=="c":
        mode = ""
        shutter_close()
    elif value=="s":
        mode = ""
        print("stopped")
    elif value=="h":
        print("(o) open, (c) close, (r) run oscillate, (s) stop")

while True:
    process_buttons()
    process_input()
    if mode=="osc":
        oscillate()
