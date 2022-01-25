#!/bin/bash
#
# The sole purpose of this script is to paper around the challenge
# of getting the escaping of s/$/ correct in the makefile.
# https://www.makeuseof.com/boost-ubuntu-performance-on-raspberry-pi-4/
#
sudo sed -i -e 's/$/ zswap.enabled=1/' /boot/firmware/cmdline.txt
