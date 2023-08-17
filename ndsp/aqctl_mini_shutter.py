#!/usr/bin/env python3
import argparse
import logging
from sipyco.pc_rpc import simple_server_loop
from sipyco import common_args
from driver import ShutterHandler

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
    parser.add_argument(
        '-s', '--shutter',
        help='If present, module has a shutter.',
        action='store_true'
    )
    parser.add_argument(
        '-d', '--photodiode',
        help='If present, module has photo(d)iode',
        action='store_true'
    )
    parser.add_argument(
        '--debug',
        help="Debug will simply read serial data without parsing.",
        action='store_true'
    )
    parser.add_argument(
        '--baudrate',
        help="Baudrate of serial connection",
        default=115200,
        type=int
    )
    parser.add_argument(
        '--timeout',
        help='Timeout time of serial connection',
        default=0.1,
        type=float
    )
    parser.add_argument(
        '--check-delay',
        help='How often to check for received data',
        default=0.1,
        type=float
    )
    parser.add_argument(
        '--name',
        help='Name for the shutter or power monitor',
        default='no_name_given',
        type=str
    )

    return parser


def main():
    args = get_argparser().parse_args()
    common_args.init_logger_from_args(args)

    if args.baudrate not in [50, 75, 110, 134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200]:
        args.baudrate = 115200

    print('Shutter handler made')
    dev = ShutterHandler(
        photodiode=args.photodiode,
        shutter=args.shutter,
        debug=args.debug,
        serial_port=args.serial_port,
        baudrate=args.baudrate,
        timeout=args.timeout,
        check_delay=args.check_delay,
        name=args.name)

    try:
        simple_server_loop(
            {"mini_shutter": dev},
            common_args.bind_address_from_args(args),
            args.port,
        )
    except Exception as e:
        print(f'Device disconnected with error:\n{e}')
        dev.disconnect()


if __name__ == "__main__":
    main()
