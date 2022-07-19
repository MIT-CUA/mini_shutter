# mini_shutter

Mini optical shutter using 4mm coreless DC motor and RP2040 driver using CircuitPython.  Allows a computer to control an optical shutter via a USB-C connection.

![Mini-shutter in action](images/VIDEO-shutter-demo.gif)

![Mini-shutter2 in action](images/VIDEO-mini-shutter2-2022-07-18a.gif)

Uses a Waveshare <a
href="https://www.waveshare.com/rp2040-zero.htm">RP2040-Zero board</a>
and <a
href="https://learn.adafruit.com/welcome-to-circuitpython/what-is-circuitpython">Adafruit's
CircuitPython</a>.

# Setup

Motor should be connected to GP7 and GP6.  Each motor wire should be connected to ground through a 1K resistor in parallel with a 7 microfarad capacitor.  DC pulses from the digital outputs will drive an initially high (well, max 20mA) current into the capacitor, driving the motor and charging the capacitor.  The capacitor will then discharge slowly through the resistor.  No H-bridge is needed with this design.

# Loading code

1. Copy adafruit-circuitpython-raspberry_pi_pico-en_US-7.2.5.uf2 to the boot RPI drive
2. Copy my-circuitpy-lib/* to CIRCUITPY/lib/
3. Copy mini_shutter2.py to CIRCUITPY/code.py

