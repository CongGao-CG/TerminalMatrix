#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging Terminal in ${ROWS}x${COLS} grid..."

# Check for required tools
if ! command -v wmctrl &> /dev/null && ! command -v xdotool &> /dev/null; then
    echo "Error: Please install wmctrl or xdotool for window management"
    echo "  Ubuntu/Debian: sudo apt-get install wmctrl"
    echo "  Fedora: sudo dnf install wmctrl"
    echo "  Arch: sudo pacman -S wmctrl"
    exit 1
fi

# Detect terminal emulator
TERMINAL=""
for term in gnome-terminal konsole xfce4-terminal mate-terminal lxterminal xterm; do
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
if command -v xdpyinfo &> /dev/null; then
    SCREEN_WIDTH=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
    SCREEN_HEIGHT=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)
elif command -v xrandr &> /dev/null; then
    SCREEN_DIMS=$(xrandr | grep -o 'current [0-9]* x [0-9]*' | awk '{print $2, $4}')
    SCREEN_WIDTH=$(echo $SCREEN_DIMS | cut -d' ' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_DIMS | cut -d' ' -f2)
else
    # Default fallback dimensions
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
fi

# Calculate window dimensions
WIDTH=$((SCREEN_WIDTH / COLS))
HEIGHT=$((SCREEN_HEIGHT / ROWS))

# Account for window decorations and panels (adjust these values as needed)
WIDTH=$((WIDTH - 10))
HEIGHT=$((HEIGHT - 50))

# Create and position windows
TOTAL=$((ROWS * COLS))
WINDOW_IDS=()

for ((i=1; i<=TOTAL; i++)); do
    # Open new terminal window
    case $TERMINAL in
        gnome-terminal)
            gnome-terminal --geometry=80x24 &
            ;;
        konsole)
            konsole --geometry=80x24 &
            ;;
        xfce4-terminal)
            xfce4-terminal --geometry=80x24 &
            ;;
        mate-terminal)
            mate-terminal --geometry=80x24 &
            ;;
        lxterminal)
            lxterminal --geometry=80x24 &
            ;;
        xterm)
            xterm -geometry 80x24 &
            ;;
    esac
    
    sleep 0.5
    
    # Get the window ID of the most recently created window
    if command -v wmctrl &> /dev/null; then
        WINDOW_ID=$(wmctrl -l | tail -1 | awk '{print $1}')
        WINDOW_IDS+=("$WINDOW_ID")
    fi
done

# Wait a bit for all windows to fully open
sleep 1

# Position windows
if command -v wmctrl &> /dev/null; then
    WINDOW_INDEX=0
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $WINDOW_INDEX -lt ${#WINDOW_IDS[@]} ]; then
                X=$((c * WIDTH))
                Y=$((r * HEIGHT))
                
                # Move and resize window
                wmctrl -i -r "${WINDOW_IDS[$WINDOW_INDEX]}" -e 0,$X,$Y,$WIDTH,$HEIGHT
                
                WINDOW_INDEX=$((WINDOW_INDEX + 1))
            fi
        done
    done
elif command -v xdotool &> /dev/null; then
    # Alternative using xdotool
    echo "Using xdotool for positioning (less precise)..."
    
    # Get all terminal windows
    WINDOW_LIST=$(xdotool search --class "$TERMINAL" | tail -$TOTAL)
    
    WINDOW_INDEX=0
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $WINDOW_INDEX -lt $TOTAL ]; then
                X=$((c * WIDTH))
                Y=$((r * HEIGHT))
                
                # Get window ID from list
                WINDOW_ID=$(echo "$WINDOW_LIST" | sed -n "$((WINDOW_INDEX+1))p")
                
                if [ -n "$WINDOW_ID" ]; then
                    xdotool windowmove "$WINDOW_ID" $X $Y
                    xdotool windowsize "$WINDOW_ID" $WIDTH $HEIGHT
                fi
                
                WINDOW_INDEX=$((WINDOW_INDEX + 1))
            fi
        done
    done
fi

echo "Done!"