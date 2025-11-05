#!/bin/bash

# Neurobionics Interface Board Configuration Script
# Runs on first boot to configure hardware interfaces

CONFIG_FILE="/boot/firmware/config.txt"
MARKER="# Neurobionics Interface Board Configuration"

# Check if configuration already exists
if grep -q "$MARKER" "$CONFIG_FILE" 2>/dev/null; then
    echo "Neurobionics Interface Board configuration already present in $CONFIG_FILE"
    exit 0
fi

echo "Adding Neurobionics Interface Board configuration to $CONFIG_FILE"

# Add configuration to config.txt
cat << 'EOF' >> "$CONFIG_FILE"

# Neurobionics Interface Board Configuration

# UART Configuration
dtoverlay=uart1-pi5
dtoverlay=uart2-pi5

# I2C Configuration
dtparam=i2c_arm=on,i2c_arm_baudrate=400000
dtoverlay=i2c2-pi5,pins_12_13,baudrate=400000
dtoverlay=i2c3-pi5,pins_14_15,baudrate=400000

# SPI Configuration
dtparam=spi=on
dtoverlay=spi1-3cs
EOF

echo "Configuration added successfully. Reboot required for changes to take effect."

# Disable this service so it doesn't run again
systemctl disable configure-interface-board.service

echo "Service disabled. Configuration complete." 