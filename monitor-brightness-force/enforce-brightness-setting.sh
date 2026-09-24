#!/bin/bash

SERVICE="org.kde.org_kde_powerdevil"
DBUS_PATH="/org/kde/ScreenBrightness/display9"
INTERFACE="org.kde.ScreenBrightness.Display"

while true; do
    kde_value=$(busctl --user get-property \
        "$SERVICE" \
        "$DBUS_PATH" \
        "$INTERFACE" \
        Brightness |
        awk '{print $2}')

    target=$(( (kde_value + 50) / 100 ))

    ddcutil --display 1 setvcp 10 "$target"

    sleep 5
done