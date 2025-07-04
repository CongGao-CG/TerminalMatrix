#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging Terminal in ${ROWS}x${COLS} grid..."

# Preserve terminal environment variables
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM}"

# Ensure X resources are loaded (for xterm/urxvt)
if [ -f "$HOME/.Xresources" ] && command -v xrdb &> /dev/null; then
    xrdb -merge "$HOME/.Xresources" 2>/dev/null
fi

# Detect available terminal emulator
TERMINAL=""
if command -v gnome-terminal &> /dev/null; then
    TERMINAL="gnome-terminal"
    # Try to detect current profile for gnome-terminal
    if [ -n "$GNOME_TERMINAL_PROFILE" ]; then
        TERMINAL_PROFILE="--profile=$GNOME_TERMINAL_PROFILE"
    fi
elif command -v konsole &> /dev/null; then
    TERMINAL="konsole"
elif command -v xterm &> /dev/null; then
    TERMINAL="xterm"
elif command -v urxvt &> /dev/null; then
    TERMINAL="urxvt"
elif command -v terminator &> /dev/null; then
    TERMINAL="terminator"
else
    echo "Error: No supported terminal emulator found"
    exit 1
fi

echo "Using terminal: $TERMINAL"

# Detect available window management tools
HAS_XDOTOOL=false
HAS_WMCTRL=false
if command -v xdotool &> /dev/null; then
    HAS_XDOTOOL=true
    echo "Found xdotool for window management"
fi
if command -v wmctrl &> /dev/null; then
    HAS_WMCTRL=true
    echo "Found wmctrl for window management"
fi

# Get screen dimensions
if command -v xdpyinfo &> /dev/null; then
    SCREEN_DIM=$(xdpyinfo | grep dimensions | sed -r 's/^[^0-9]*([0-9]+x[0-9]+).*$/\1/')
    SCREEN_WIDTH=$(echo $SCREEN_DIM | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_DIM | cut -d'x' -f2)
elif command -v xrandr &> /dev/null; then
    # Fallback to xrandr
    SCREEN_DIM=$(xrandr | grep ' connected' | head -1 | grep -o '[0-9]\+x[0-9]\+')
    SCREEN_WIDTH=$(echo $SCREEN_DIM | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_DIM | cut -d'x' -f2)
else
    # Default values if we can't detect
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
    echo "Warning: Could not detect screen size, using default ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
fi

# Calculate window dimensions
WIDTH=$((SCREEN_WIDTH / COLS))
HEIGHT=$((SCREEN_HEIGHT / ROWS))

# Adjust for window decorations and panels
WIDTH=$((WIDTH - 10))
HEIGHT=$((HEIGHT - 50))

echo "Screen: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}, Window size: ${WIDTH}x${HEIGHT}"

# Function to open terminal with geometry
open_terminal_with_geometry() {
    local x=$1
    local y=$2
    local w=$3
    local h=$4
    
    case $TERMINAL in
        gnome-terminal)
            # gnome-terminal uses character-based geometry
            local cols=$((w / 8))  # Approximate character width
            local rows=$((h / 16)) # Approximate character height
            # Use --window to ensure profile is loaded
            gnome-terminal --window --geometry="${cols}x${rows}+${x}+${y}" &
            ;;
        konsole)
            # Load default profile
            konsole --profile "$USER" --geometry "${w}x${h}+${x}+${y}" &
            ;;
        xterm)
            # xterm uses character-based geometry
            local cols=$((w / 8))
            local rows=$((h / 16))
            # Load X resources for proper colors
            xterm -ls -geometry "${cols}x${rows}+${x}+${y}" &
            ;;
        urxvt)
            # urxvt uses character-based geometry
            local cols=$((w / 8))
            local rows=$((h / 16))
            # Load X resources
            urxvt -ls -geometry "${cols}x${rows}+${x}+${y}" &
            ;;
        terminator)
            terminator --geometry="${w}x${h}+${x}+${y}" &
            ;;
    esac
    
    sleep 0.5
}

# Function to move window using available tools
move_window() {
    local window_id=$1
    local x=$2
    local y=$3
    local w=$4
    local h=$5
    
    if [ "$HAS_XDOTOOL" = true ]; then
        xdotool windowmove "$window_id" "$x" "$y"
        xdotool windowsize "$window_id" "$w" "$h"
    elif [ "$HAS_WMCTRL" = true ]; then
        wmctrl -i -r "$window_id" -e "0,$x,$y,$w,$h"
    fi
}

# Create and position windows
TOTAL=$((ROWS * COLS))
declare -a WINDOW_IDS

# Method 1: Try to use terminal geometry options
if [ "$HAS_XDOTOOL" = false ] && [ "$HAS_WMCTRL" = false ]; then
    echo "No window management tools found, using terminal geometry options..."
    
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH))
            Y=$((r * HEIGHT))
            
            open_terminal_with_geometry $X $Y $WIDTH $HEIGHT
        done
    done
else
    # Method 2: Open terminals and then move them
    echo "Opening $TOTAL terminal windows..."
    
    # Get initial window list
    if [ "$HAS_XDOTOOL" = true ]; then
        BEFORE_WINDOWS=$(xdotool search --class "$TERMINAL" 2>/dev/null | sort)
    elif [ "$HAS_WMCTRL" = true ]; then
        BEFORE_WINDOWS=$(wmctrl -l | grep -i "$TERMINAL" | awk '{print $1}' | sort)
    fi
    
    # Open all terminals
    for ((i=1; i<=TOTAL; i++)); do
        case $TERMINAL in
            gnome-terminal)
                gnome-terminal --window &
                ;;
            konsole)
                konsole --profile "$USER" &
                ;;
            xterm)
                xterm -ls &
                ;;
            urxvt)
                urxvt -ls &
                ;;
            terminator)
                terminator &
                ;;
        esac
        sleep 0.3
    done
    
    # Wait a bit for all windows to open
    sleep 1
    
    # Get new window list
    if [ "$HAS_XDOTOOL" = true ]; then
        AFTER_WINDOWS=$(xdotool search --class "$TERMINAL" 2>/dev/null | sort)
        NEW_WINDOWS=$(comm -13 <(echo "$BEFORE_WINDOWS") <(echo "$AFTER_WINDOWS"))
    elif [ "$HAS_WMCTRL" = true ]; then
        AFTER_WINDOWS=$(wmctrl -l | grep -i "$TERMINAL" | awk '{print $1}' | sort)
        NEW_WINDOWS=$(comm -13 <(echo "$BEFORE_WINDOWS") <(echo "$AFTER_WINDOWS"))
    fi
    
    # Convert to array
    readarray -t WINDOW_IDS <<< "$NEW_WINDOWS"
    
    # Position windows
    echo "Positioning windows..."
    WINDOW_INDEX=0
    
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $WINDOW_INDEX -lt ${#WINDOW_IDS[@]} ]; then
                X=$((c * WIDTH))
                Y=$((r * HEIGHT))
                
                WINDOW_ID=${WINDOW_IDS[$WINDOW_INDEX]}
                if [ ! -z "$WINDOW_ID" ]; then
                    move_window "$WINDOW_ID" "$X" "$Y" "$WIDTH" "$HEIGHT"
                fi
                
                WINDOW_INDEX=$((WINDOW_INDEX + 1))
            fi
        done
    done
fi

echo "Done!"

# Optional: Focus on the first terminal
if [ "$HAS_XDOTOOL" = true ] && [ ${#WINDOW_IDS[@]} -gt 0 ]; then
    xdotool windowfocus "${WINDOW_IDS[0]}" 2>/dev/null
fi