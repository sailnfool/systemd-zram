#!/bin/bash
swapon --show
sudo systemctl daemon-reload
sudo systemctl stop systemd-zram
sudo systemctl start systemd-zram
sudo systemctl enable systemd-zram
swapon --show
