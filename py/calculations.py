#!/usr/bin/env python
'''General file for calculating values used in the design.'''


import numpy as np


def calculate_pll_config():
    '''Sweep through all trim codes, giving ideal integer division to achieve a
    16MHz clock frequency.

    Details on configuration values can be found here:
    https://caravel-harness.readthedocs.io/en/latest/housekeeping-spi.html
    '''
    print('Sweep through all trim codes, giving ideal integer division to '
          'achieve a 16MHz resulting clock. Only divisions by 2-7 are '
          'possible.')
    for i in range(27):
        d = 4.67e-9 + i*250e-12  # delay
        f = 1/d
        div = f / 16e6  # division to get desired clock
        err = 100 * (div - np.round(div)) / np.round(div)
        code_hex = (1 << i) - 1
        print('code {:02} (0x{:7x}), {:.03f} MHz, ideal div of {:.03f}, '
              '{:.03f}% error'.format(i, code_hex, f / 1e6, div, err))

if __name__ == '__main__':
    calculate_pll_config()
