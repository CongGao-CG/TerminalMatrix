#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Opening ${ROWS}x${COLS} = $((ROWS*COLS)) real terminal windows..."

# Check if we have X11 display
if [ -z "$DISPLAY" ]; then
    echo "Error: No X11 display found. This script requires a graphical environment."
    exit 1
fi

# Find available terminal emulator
TERMINAL=""
for term in gnome-terminal konsole xfce4-terminal mate-terminal terminator rxvt-unicode urxvt xterm; do
    if command -v $term &> /dev/null; then
        TERMINAL=$term
        break
    fi
done

if [ -z "$TERMINAL" ]; then
    echo "Error: No supported terminal emulator found"
    exit 1
fi

echo "Using terminal: $TERMINAL"

# Get screen dimensions
if command -v xrandr &> /dev/null; then
    SCREEN_INFO=$(xrandr | grep -oP 'current \K[0-9]+ x [0-9]+')
    SCREEN_WIDTH=$(echo $SCREEN_INFO | cut -d' ' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_INFO | cut -d' ' -f3)
else
    # Fallback dimensions
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
fi

# Calculate window dimensions (with some margin)
MARGIN=50  # pixels for taskbar and window decorations
WIDTH=$(( (SCREEN_WIDTH - MARGIN) / COLS ))
HEIGHT=$(( (SCREEN_HEIGHT - MARGIN) / ROWS ))

# Adjust for window decorations
WIDTH=$((WIDTH - 20))
HEIGHT=$((HEIGHT - 40))

echo "Screen: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
echo "Each window: ${WIDTH}x${HEIGHT}"

# Create windows in grid positions
WINDOW_NUM=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$((c * (WIDTH + 10) + 10))  # 10px gap between windows
        Y=$((r * (HEIGHT + 30) + 30)) # 30px for title bars
        
        TITLE="Terminal $WINDOW_NUM (R$((r+1))C$((c+1)))"
        
        case $TERMINAL in
            gnome-terminal)
                gnome-terminal --title="$TITLE" --geometry="${WIDTH}x${HEIGHT}+${X}+${Y}" &
                ;;
            konsole)
                konsole --title "$TITLE" --geometry "${WIDTH}x${HEIGHT}+${X}+${Y}" &
                ;;
            xfce4-terminal)
                xfce4-terminal --title="$TITLE" --geometry="${WIDTH}x${HEIGHT}+${X}+${Y}" &
                ;;
            terminator)
                terminator -T "$TITLE" --geometry="${WIDTH}x${HEIGHT}+${X}+${Y}" &
                ;;
            xterm)
                xterm -title "$TITLE" -geometry "80x24+${X}+${Y}" &
                ;;
            rxvt-unicode|urxvt)
                $TERMINAL -title "$TITLE" -geometry "80x24+${X}+${Y}" &
                ;;
            *)
                $TERMINAL &
                ;;
        esac
        
        WINDOW_NUM=$((WINDOW_NUM + 1))
        sleep 0.2  # Small delay to prevent overwhelming the system
    done
done

echo ""
echo "Opened $((ROWS * COLS)) terminal windows!"
echo ""
echo "Window switching shortcuts:"
echo "  Alt+Tab         - Switch between windows"
echo "  Alt+\`          - Switch between windows of same application"
echo "  Super+[1-9]     - Switch to workspace (if using multiple workspaces)"
echo "  Mouse click     - Focus on a window"
echo ""

# If wmctrl is available, show window list
if command -v wmctrl &> /dev/null; then
    echo "Window list:"
    sleep 1  # Wait for windows to open
    wmctrl -l | grep -E "(Terminal|terminal|xterm)"
fi