#!/bin/bash

# Konsole grid launcher - Opens konsole windows in grid layout

ROWS=${1:-2}
COLS=${2:-2}

# Check konsole
if ! command -v konsole &> /dev/null; then
    echo "Error: konsole not found"
    exit 1
fi

# Get screen dimensions
if command -v xrandr &> /dev/null; then
    # More reliable than xdpyinfo
    SCREEN=$(xrandr | grep primary | grep -o '[0-9]\+x[0-9]\+')
    SCREEN_WIDTH=${SCREEN%x*}
    SCREEN_HEIGHT=${SCREEN#*x}
else
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
fi

echo "Screen: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
echo "Creating ${ROWS}x${COLS} konsole grid..."

#############################################
# WINDOW SIZE CONFIGURATION
#############################################
# 
# Konsole geometry uses: WIDTHxHEIGHT+X+Y
# WIDTH/HEIGHT are in characters (not pixels!)
# X/Y are pixel positions
#
# To make windows BIGGER, increase these:
TERM_COLS=120    # Characters wide (try: 80, 100, 120, 150)
TERM_ROWS=40     # Characters tall (try: 24, 35, 40, 50)

# Screen layout (pixels)
MARGIN=10        # Edge margin
TASKBAR=40       # Bottom panel height
#############################################

# Calculate positions
USABLE_W=$((SCREEN_WIDTH - 2*MARGIN))
USABLE_H=$((SCREEN_HEIGHT - TASKBAR - 2*MARGIN))

STEP_X=$((USABLE_W / COLS))
STEP_Y=$((USABLE_H / ROWS))

# Launch windows
N=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$((MARGIN + c * STEP_X))
        Y=$((MARGIN + r * STEP_Y))
        
        konsole \
            --separate \
            --geometry "${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
            --hide-menubar \
            --hide-tabbar &
        
        ((N++))
        sleep 0.1
    done
done

echo "Opened $((ROWS*COLS)) windows (${TERM_COLS}×${TERM_ROWS} chars)"
echo ""
echo "If windows are too small:"
echo "  1. Edit script: increase TERM_COLS and TERM_ROWS"
echo "  2. Or reduce grid size: $0 2 2"
echo ""
echo "Close all: pkill konsole"