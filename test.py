#
# Copyright 2023, Colias Group, LLC
#
# SPDX-License-Identifier: BSD-2-Clause
#

import sys
import time
import argparse
import pexpect
from requests import Session


HTTP_URL_BASE = 'http://localhost:8080'


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('cmd', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    run(args)


def run(args):
    child = pexpect.spawn(args.cmd[0], args.cmd[1:], encoding='utf-8')
    child.logfile = sys.stdout
    child.expect('completed system invocations', timeout=5)

    time.sleep(1)

    flush_read(child)

    try:
        sess = Session()
        url = HTTP_URL_BASE
        r = sess.get(url, verify=False, timeout=5)
    except:
        pass

    child.expect('00000000: 4745 5420 2f20', timeout=5)

    flush_read(child)


def flush_read(child):
    while True:
        try:
            child.read_nonblocking(timeout=0)
        except pexpect.TIMEOUT:
            break


if __name__ == '__main__':
    main()
