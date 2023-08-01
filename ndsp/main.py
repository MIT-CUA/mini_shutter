#
# camera_shutter.py: run DC solenoid camera shutter using RP2040
# there are two solenoids controlled:
#
# - shutter (top): GP7  -- open when high, closed when low
# (doesn't work) - filter  (bot): GP2 & GP4 -- direction changes inserted/removed
#

# in lib (on rp2040) or my-circuitpy-lib (on mini_shutter repo)
from shutter import Shutter

# how many values to send per recording_period (seconds)
# pd is whether is has a photodiode or not. Should be automatically detected
shutter = Shutter(data_buffer_size=2, recording_period=0.5)
shutter.start()

