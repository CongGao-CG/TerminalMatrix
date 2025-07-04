#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging Terminal in ${ROWS}x${COLS} grid..."

# Open Terminal if not running
open -a Terminal
sleep 1

# Create windows
TOTAL=$((ROWS * COLS))
for ((i=2; i<=TOTAL; i++)); do
    osascript -e 'tell app "System Events" to keystroke "n" using command down'
    sleep 0.3
done

# Arrange windows (rough positioning - adjust as needed)
WIDTH=$((2558 / COLS))
HEIGHT=$((1414 / ROWS))

WINDOW=$TOTAL
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$((1726 + c * WIDTH))
        Y=$((r * HEIGHT))
        
        osascript -e "tell app \"Terminal\" to set bounds of window $WINDOW to {$X, $Y, $((X+WIDTH)), $((Y+HEIGHT))}"
        
        WINDOW=$((WINDOW - 1))
    done
done

echo "Done!"
