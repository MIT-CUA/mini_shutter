# mini_shutter and camera_shutter

## mini_shutter

Mini optical shutter using 4mm coreless DC motor and RP2040 driver using CircuitPython.  Allows a computer to control an optical shutter via a USB-C connection.

![Mini-shutter in action](images/VIDEO-shutter-demo.gif)

![Mini-shutter2 in action](images/VIDEO-mini-shutter2-2022-07-18a.gif)

Uses a Waveshare <a
href="https://www.waveshare.com/rp2040-zero.htm">RP2040-Zero board</a>
and <a
href="https://learn.adafruit.com/welcome-to-circuitpython/what-is-circuitpython">Adafruit's
CircuitPython</a>.

Motor is an 0408 vibration motor, body diameter 4mm rated 3V, e.g. <a href="https://www.amazon.com/gp/product/B07PJDSRC7">this one from amazon</a>.

### Setup

Mini-shutter driver schematic:

![mini-shutter driver schematic](images/mini_shutter_driver_schematic.png)

Note that the resistors and capacitors are optional, and the header for an optional RC servo is not used.

### Loading code

1. Copy adafruit-circuitpython-raspberry_pi_pico-en_US-7.2.5.uf2 to the boot RPI-RP2 drive
2. Wait for RP2040 to re-mount itself as CIRCUITPY
3. Copy my-circuitpy-lib/* to CIRCUITPY/lib/
4. Copy mini_shutter2.py to CIRCUITPY/code.py

## camera_shutter

Camera optical shutter using DC rotating electromagnet digital camera shutter from ebay, e.g. <a href="https://www.ebay.com/itm/124456754185">this one</a>.

![Camera-shutter in action](images/VIDEO-camera-shutter-blinking-2022-08-17c.gif)

Note that this shutter is normally closed, and requires a voltage to open.  The shutter springs back closed by itself when the voltage is removed.

![camera shutter part](images/PHOTO-camera-shutter-part.png)

Also, the camera shutter module has another solenoid which moves some kind of filter (or polarizer) into (and out of) the beam path, when energized (or energized in the reverse direction).

## code

See [camera_shutter.py](camera_shutter.py). New code in [main.py](ndsp/main.py), [shutter.py](ndsp/shutter.py), [photodiode.py](ndsp/photodiode.py), and [boot.py](ndsp/boot.py).
