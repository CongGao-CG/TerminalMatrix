#!/bin/bash

# Terminal grid script for Linux
ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging Terminal in ${ROWS}x${COLS} grid..."

# Function to detect available terminal emulator
detect_terminal() {
    if command -v gnome-terminal >/dev/null 2>&1; then
        echo "gnome-terminal"
    elif command -v xterm >/dev/null 2>&1; then
        echo "xterm"
    elif command -v konsole >/dev/null 2>&1; then
        echo "konsole"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        echo "xfce4-terminal"
    elif command -v mate-terminal >/dev/null 2>&1; then
        echo "mate-terminal"
    else
        echo "none"
    fi
}

# Function to get screen dimensions
get_screen_size() {
    if command -v xrandr >/dev/null 2>&1; then
        # Get primary display resolution
        xrandr | grep primary | head -1 | sed 's/.*primary \([0-9]*\)x\([0-9]*\).*/\1 \2/'
    else
        # Fallback to common resolution
        echo "1920 1080"
    fi
}

TERMINAL=$(detect_terminal)

if [ "$TERMINAL" = "none" ]; then
    echo "Error: No supported terminal emulator found!"
    echo "Supported: gnome-terminal, xterm, konsole, xfce4-terminal, mate-terminal"
    exit 1
fi

echo "Using terminal: $TERMINAL"

# Get screen dimensions
read SCREEN_WIDTH SCREEN_HEIGHT <<< $(get_screen_size)
echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

# Calculate window dimensions
WINDOW_WIDTH=$((SCREEN_WIDTH / COLS))
WINDOW_HEIGHT=$((SCREEN_HEIGHT / ROWS))

# Adjust for window decorations and taskbars
WINDOW_HEIGHT=$((WINDOW_HEIGHT - 60))  # Account for title bar and taskbar

TOTAL=$((ROWS * COLS))

# Function to launch terminal with geometry
launch_terminal() {
    local x=$1
    local y=$2
    local width=$3
    local height=$4
    
    case $TERMINAL in
        "gnome-terminal")
            gnome-terminal --geometry="${width}x${height}+${x}+${y}" >/dev/null 2>&1 &
            ;;
        "xterm")
            xterm -geometry "${width}x${height}+${x}+${y}" >/dev/null 2>&1 &
            ;;
        "konsole")
            konsole --geometry "${width}x${height}+${x}+${y}" >/dev/null 2>&1 &
            ;;
        "xfce4-terminal")
            xfce4-terminal --geometry="${width}x${height}+${x}+${y}" >/dev/null 2>&1 &
            ;;
        "mate-terminal")
            mate-terminal --geometry="${width}x${height}+${x}+${y}" >/dev/null 2>&1 &
            ;;
    esac
}

# Create grid of terminals
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        X=$((c * WINDOW_WIDTH))
        Y=$((r * WINDOW_HEIGHT + 30))  # Add offset for menu bar
        
        echo "Creating terminal at position (${X}, ${Y}) with size ${WINDOW_WIDTH}x${WINDOW_HEIGHT}"
        
        # For gnome-terminal, we need character-based dimensions
        if [ "$TERMINAL" = "gnome-terminal" ]; then
            # Convert pixel dimensions to character dimensions (approximate)
            CHAR_WIDTH=$((WINDOW_WIDTH / 8))   # Approximate character width
            CHAR_HEIGHT=$((WINDOW_HEIGHT / 16)) # Approximate character height
            launch_terminal $X $Y $CHAR_WIDTH $CHAR_HEIGHT
        else
            launch_terminal $X $Y $WINDOW_WIDTH $WINDOW_HEIGHT
        fi
        
        sleep 0.5  # Give time for window to appear
    done
done

echo "Done! Created ${TOTAL} terminal windows in ${ROWS}x${COLS} grid."

# Optional: If wmctrl is available, we can fine-tune positioning
if command -v wmctrl >/dev/null 2>&1; then
    echo "Fine-tuning window positions with wmctrl..."
    sleep 2  # Wait for all windows to appear
    
    # Get list of terminal windows
    case $TERMINAL in
        "gnome-terminal")
            WINDOW_CLASS="gnome-terminal-server"
            ;;
        "xterm")
            WINDOW_CLASS="xterm"
            ;;
        "konsole")
            WINDOW_CLASS="konsole"
            ;;
        *)
            WINDOW_CLASS="terminal"
            ;;
    esac
    
    # Reposition windows more precisely
    wmctrl -l | grep -i "$WINDOW_CLASS" | tail -n $TOTAL | while read -r line; do
        WINDOW_ID=$(echo "$line" | awk '{print $1}')
        # You can add more precise positioning here if needed
    done
fi