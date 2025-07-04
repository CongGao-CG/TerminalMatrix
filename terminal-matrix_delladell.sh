#!/bin/bash

# Konsole grid launcher - Opens konsole windows in grid layout

ROWS=${1:-2}
COLS=${2:-2}

# Check konsole
if ! command -v konsole &> /dev/null; then
    echo "Error: konsole not found"
    exit 1
fi

WIDTH=$((2558 / COLS))
HEIGHT=$((1240 / ROWS))
wHEIGHT=$((1240 / ROWS - 28))
# Launch windows
N=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$(( c * WIDTH))
        Y=$(( r * HEIGHT + 28))
        
        konsole \
            --separate \
            --geometry "${WIDTH}x${wHEIGHT}+${X}+${Y}" \
            --hide-menubar \
            --hide-tabbar &
        
        ((N++))
        sleep 0.1
    done
done

echo "Opened $((ROWS*COLS)) windows (${WIDTH}×${HEIGHT} chars)"
echo "Close all: pkill konsole"
