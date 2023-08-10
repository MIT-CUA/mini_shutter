# File runs on RP2040 boot, sets some settings
import supervisor
import time

supervisor.disable_autoreload()
supervisor.set_rgb_status_brightness(255)
