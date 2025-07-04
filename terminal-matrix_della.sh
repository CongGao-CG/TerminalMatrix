#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging Terminal in ${ROWS}x${COLS} grid..."

# Check if wmctrl is installed
if ! command -v wmctrl &> /dev/null; then
    echo ""
    echo "WARNING: wmctrl is not installed. Windows will open but won't be automatically arranged."
    echo ""
    echo "To install wmctrl on RHEL 9.5:"
    echo "  sudo dnf install wmctrl"
    echo "  # or"
    echo "  sudo yum install wmctrl"
    echo ""
    echo "Continuing without automatic arrangement..."
    echo ""
    ARRANGE_WINDOWS=false
else
    ARRANGE_WINDOWS=true
fi

# Check for X11 display
if [ -z "$DISPLAY" ]; then
    echo "Error: No X11 display found. Are you running this in a graphical session?"
    exit 1
fi

# Detect terminal emulator
TERMINAL=""
for term in gnome-terminal konsole xfce4-terminal mate-terminal xterm; do
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
    # Get primary monitor dimensions
    SCREEN_INFO=$(xrandr | grep ' connected primary' || xrandr | grep ' connected' | head -1)
    RESOLUTION=$(echo "$SCREEN_INFO" | grep -oP '\d+x\d+\+\d+\+\d+' | head -1 | cut -d'+' -f1)
    SCREEN_WIDTH=$(echo "$RESOLUTION" | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo "$RESOLUTION" | cut -d'x' -f2)
elif command -v xdpyinfo &> /dev/null; then
    SCREEN_WIDTH=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
    SCREEN_HEIGHT=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)
else
    # Default fallback
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
fi

echo "Screen dimensions: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

# Calculate window dimensions
# Leave some space for taskbar and window decorations
TASKBAR_HEIGHT=50
DECORATION_WIDTH=10
DECORATION_HEIGHT=40
GAP=5  # Gap between windows

USABLE_WIDTH=$((SCREEN_WIDTH - (COLS - 1) * GAP))
USABLE_HEIGHT=$((SCREEN_HEIGHT - TASKBAR_HEIGHT - (ROWS - 1) * GAP))

WIDTH=$((USABLE_WIDTH / COLS - DECORATION_WIDTH))
HEIGHT=$((USABLE_HEIGHT / ROWS - DECORATION_HEIGHT))

# Create windows
TOTAL=$((ROWS * COLS))
WINDOW_PIDS=()

echo "Creating $TOTAL terminal windows..."

for ((i=1; i<=TOTAL; i++)); do
    case $TERMINAL in
        gnome-terminal)
            gnome-terminal --title="Terminal $i" --window &
            ;;
        konsole)
            konsole --title "Terminal $i" &
            ;;
        xfce4-terminal)
            xfce4-terminal --title="Terminal $i" &
            ;;
        mate-terminal)
            mate-terminal --title="Terminal $i" &
            ;;
        xterm)
            xterm -title "Terminal $i" &
            ;;
    esac
    
    WINDOW_PIDS+=($!)
    sleep 0.3  # Give window time to open
done

# Wait a bit for all windows to be created
sleep 1

# Arrange windows if wmctrl is available
if [ "$ARRANGE_WINDOWS" = true ]; then
    echo "Arranging windows..."
    
    # Get list of our terminal windows
    # Filter by the terminal application name and sort by creation time
    WINDOW_LIST=$(wmctrl -l -p | grep -i "$TERMINAL" | tail -$TOTAL)
    
    # Convert to array of window IDs
    WINDOW_IDS=()
    while IFS= read -r line; do
        WID=$(echo "$line" | awk '{print $1}')
        WINDOW_IDS+=("$WID")
    done <<< "$WINDOW_LIST"
    
    # Position windows in grid
    WINDOW_INDEX=0
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $WINDOW_INDEX -lt ${#WINDOW_IDS[@]} ]; then
                X=$((c * (WIDTH + DECORATION_WIDTH + GAP)))
                Y=$((r * (HEIGHT + DECORATION_HEIGHT + GAP)))
                
                # Move and resize window
                # Format: gravity,x,y,width,height
                wmctrl -i -r "${WINDOW_IDS[$WINDOW_INDEX]}" -e 0,$X,$Y,$WIDTH,$HEIGHT
                
                WINDOW_INDEX=$((WINDOW_INDEX + 1))
            fi
        done
    done
    
    echo "Done! Windows arranged in ${ROWS}x${COLS} grid."
else
    echo "Done! $TOTAL terminal windows opened."
    echo "Please arrange them manually or install wmctrl for automatic arrangement."
fi

echo ""
echo "Tips:"
echo "  • Switch windows: Alt+Tab"
echo "  • Switch to specific window: Click with mouse"
if [ "$TERMINAL" = "gnome-terminal" ]; then
    echo "  • New tab in window: Ctrl+Shift+T"
    echo "  • Close tab/window: Ctrl+Shift+W"
fi