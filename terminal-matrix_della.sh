#!/bin/bash

# Konsole grid launcher - Opens konsole windows in grid layout

ROWS=${1:-2}
COLS=${2:-2}

# Check konsole
if ! command -v konsole &> /dev/null; then
    echo "Error: konsole not found"
    exit 1
fi

WIDTH=$((1726 / COLS))
HEIGHT=$((992 / ROWS))
wHEIGHT=$((992 / ROWS - 30))
# Launch windows
N=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$(( c * WIDTH))
        Y=$(( r * HEIGHT))
        
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
echo ""
echo "If windows are too small:"
echo "  1. Edit script: increase WIDTH and HEIGHT"
echo "  2. Or reduce grid size: $0 2 2"
echo ""
echo "Close all: pkill konsole"
