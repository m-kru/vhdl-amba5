[![Tests](https://github.com/m-kru/vhdl-amba5/actions/workflows/tests.yml/badge.svg?branch=master)](https://github.com/m-kru/vhdl-amba5/actions?query=master)

# vhdl-amba5

Library with VHDL cores implementing Advanced Microcontroller Bus Architecture 5 (AMBA5) specifications such as APB, AHB, and AXI.
Currently only APB is implemented.
All VHDL files are compatible with the standard revision 2008.
All the code simulates correctly with ghdl, nvc, questa and xsim simulators.

The internal build system is (HBS)[https://github.com/m-kru/hbs].
However, you can use any build system, simply copy required source files.
