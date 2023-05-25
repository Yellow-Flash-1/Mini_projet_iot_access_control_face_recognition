#!/bin/bash

# Test GPIO pins
echo "Testing GPIO pins..."
for pin in {2..27}; do
    gpio -g mode $pin out
    gpio -g write $pin 1
    echo "GPIO pin $pin set to high"
done
echo "GPIO pin testing complete."

# Test wireless connectivity
echo "Testing Wi-Fi..."
wifi_result=$(iwgetid)
if [ $? -eq 0 ]; then
    echo "Wi-Fi is working."
    echo "Connected to: $wifi_result"
else
    echo "Wi-Fi is not working."
fi

# Test Bluetooth
echo "Testing Bluetooth..."
bt_result=$(hciconfig)
if [ $? -eq 0 ]; then
    echo "Bluetooth is working."
else
    echo "Bluetooth is not working."
fi

echo "Testing complete."
