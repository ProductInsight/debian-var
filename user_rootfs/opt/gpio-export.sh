#!/bin/bash

# This script is run as root before X starts. It exports the GPIO pins
# to userspace and sets their permissions to allow access by the "gpio" group.

echo "Exporting GPIO pins..."

echo 2 > /sys/class/gpio/export
echo 0 > /sys/class/pwm/pwmchip0/export
echo 0 > /sys/class/pwm/pwmchip1/export
echo 0 > /sys/class/pwm/pwmchip2/export

sleep 1;

echo "Changing ownership of GPIO pins..."

chgrp -R gpio /sys/class/gpio/gpio2/*
chgrp -R gpio /sys/class/pwm/pwmchip0/pwm0
chgrp -R gpio /sys/class/pwm/pwmchip1/pwm0
chgrp -R gpio /sys/class/pwm/pwmchip2/pwm0

chmod -R g+rw /sys/class/gpio/gpio2/*
chmod -R g+rw /sys/class/pwm/pwmchip0/pwm0
chmod -R g+rw /sys/class/pwm/pwmchip1/pwm0
chmod -R g+rw /sys/class/pwm/pwmchip2/pwm0

echo "GPIO export complete."

