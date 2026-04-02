#!/bin/bash
# Extract the energy-rate directly from upower and round to 1 decimal place
power_w=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "energy-rate" | awk '{printf "%.1f", $2}')
power_w_long=$(upower -i /org/freedesktop/UPower/devices/battery_BAT1 | grep "energy-rate" | awk '{printf $2}')
echo "{\"text\": \"${power_w} W\", \"tooltip\": \"UPower Energy Rate: ${power_w_long} W\"}"

