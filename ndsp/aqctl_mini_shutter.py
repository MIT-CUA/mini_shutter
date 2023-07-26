#!/usr/bin/env python3
import argparse
import logging
from sipyco.pc_rpc import simple_server_loop
from sipyco import common_args
from driver import MiniShutter 

logger = logging.getLogger(__name__)


def get_argparser():
    parser = argparse.ArgumentParser(
        description="ARTIQ controller for the Mini Shutter",
    )
    common_args.simple_network_args(
        parser,
        3478,
    )
    common_args.verbosity_args(parser)
    parser.add_argument(
        "--serial-port",
        help="Which USB port the Arduino is located at.",
        default='/dev/ttyACM6',
        type=str
    )
    return parser


def main():
    args = get_argparser().parse_args()
    common_args.init_logger_from_args(args)
    dev = MiniShutter(args.serial_port)
    try:
        simple_server_loop(
            {"mini_shutter": dev},
            common_args.bind_address_from_args(args),
            args.port,
        )
    finally:
        dev.stop()


if __name__ == "__main__":
    main()
