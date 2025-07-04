#!/bin/bash

# Terminal grid arrangement script for Linux - Opens separate windows
# Works with gnome-terminal, xterm, konsole, or other X11 terminals

# Usage: 
#   ./script.sh [ROWS] [COLS] [METHOD]
#   METHOD=xterm ./script.sh 2 2
#   ./script.sh 3 3 2  # 3x3 grid using method 2 (xterm)

ROWS=${1:-2}
COLS=${2:-2}
METHOD=${3:-auto}  # Can be: auto, gnome, xterm, konsole, 1, 2, 3, or terminal name

# Check environment variable (overrides command line)
if [ -n "$TERMINAL_METHOD" ]; then
    METHOD=$TERMINAL_METHOD
fi

echo "Arranging terminals in ${ROWS}x${COLS} grid with separate windows..."
echo "Method requested: $METHOD"

# List available terminals
echo ""
echo "Checking available terminals:"
echo -n "  1. gnome-terminal: "
command -v gnome-terminal &> /dev/null && echo "✓ available" || echo "✗ not found"
echo -n "  2. xterm:          "
command -v xterm &> /dev/null && echo "✓ available" || echo "✗ not found"
echo -n "  3. konsole:        "
command -v konsole &> /dev/null && echo "✓ available" || echo "✗ not found"
echo ""

# Try to detect screen dimensions
if command -v xdpyinfo &> /dev/null; then
    SCREEN_INFO=$(xdpyinfo | grep dimensions)
    SCREEN_DIM=$(echo $SCREEN_INFO | awk '{print $2}')
    SCREEN_WIDTH=$(echo $SCREEN_DIM | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $SCREEN_DIM | cut -d'x' -f2)
    echo "Detected screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
else
    # Default dimensions if we can't detect
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
    echo "Using default screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
fi

# Calculate window dimensions
USABLE_WIDTH=$((SCREEN_WIDTH - 50))
USABLE_HEIGHT=$((SCREEN_HEIGHT - 100))

WIDTH=$((USABLE_WIDTH / COLS))
HEIGHT=$((USABLE_HEIGHT / ROWS))

# Character dimensions for terminal
TERM_COLS=$((WIDTH / 9))
TERM_ROWS=$((HEIGHT / 20))

# Function to launch gnome-terminal windows
launch_gnome_terminals() {
    echo "Launching gnome-terminal windows..."
    WINDOW_NUM=1
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH + 10))
            Y=$((r * HEIGHT + 30))
            
            gnome-terminal \
                --geometry="${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
                --title="Terminal ${WINDOW_NUM} (${r},${c})" \
                -- bash -c "echo 'Terminal ${WINDOW_NUM} - Grid position (${r},${c})'; exec bash" &
            
            WINDOW_NUM=$((WINDOW_NUM + 1))
            sleep 0.2
        done
    done
}

# Function to launch xterm windows
launch_xterm_windows() {
    echo "Launching xterm windows..."
    WINDOW_NUM=1
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH + 10))
            Y=$((r * HEIGHT + 30))
            
            xterm \
                -geometry "${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
                -title "Terminal ${WINDOW_NUM} (${r},${c})" \
                -e bash -c "echo 'Terminal ${WINDOW_NUM} - Grid position (${r},${c})'; exec bash" &
            
            WINDOW_NUM=$((WINDOW_NUM + 1))
            sleep 0.1
        done
    done
}

# Function to launch konsole windows
launch_konsole_windows() {
    echo "Launching konsole windows..."
    WINDOW_NUM=1
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH + 10))
            Y=$((r * HEIGHT + 30))
            
            konsole \
                --geometry "${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
                --title "Terminal ${WINDOW_NUM} (${r},${c})" \
                --separate &
            
            WINDOW_NUM=$((WINDOW_NUM + 1))
            sleep 0.2
        done
    done
}

# Select method based on user choice
case "$METHOD" in
    gnome|gnome-terminal|1)
        if command -v gnome-terminal &> /dev/null; then
            launch_gnome_terminals
            echo "Done! Opened $((ROWS * COLS)) gnome-terminal windows"
        else
            echo "Error: gnome-terminal not found!"
            echo "Try: ./script.sh $ROWS $COLS 2  # for xterm"
            exit 1
        fi
        ;;
        
    xterm|2)
        if command -v xterm &> /dev/null; then
            launch_xterm_windows
            echo "Done! Opened $((ROWS * COLS)) xterm windows"
        else
            echo "Error: xterm not found!"
            echo "Try: ./script.sh $ROWS $COLS 1  # for gnome-terminal"
            exit 1
        fi
        ;;
        
    konsole|3)
        if command -v konsole &> /dev/null; then
            launch_konsole_windows
            echo "Done! Opened $((ROWS * COLS)) konsole windows"
        else
            echo "Error: konsole not found!"
            echo "Try: ./script.sh $ROWS $COLS 1  # for gnome-terminal"
            echo "Or:  ./script.sh $ROWS $COLS 2  # for xterm"
            exit 1
        fi
        ;;
        
    auto|*)
        # Auto-detection: use first available
        echo "Auto-detecting terminal emulator..."
        
        if command -v gnome-terminal &> /dev/null; then
            launch_gnome_terminals
            echo "Done! Opened $((ROWS * COLS)) gnome-terminal windows"
        elif command -v xterm &> /dev/null; then
            launch_xterm_windows
            echo "Done! Opened $((ROWS * COLS)) xterm windows"
        elif command -v konsole &> /dev/null; then
            launch_konsole_windows
            echo "Done! Opened $((ROWS * COLS)) konsole windows"
        else
            # Try other terminals
            TERMINALS=("x-terminal-emulator" "urxvt" "rxvt" "termite" "alacritty" "kitty")
            
            for term in "${TERMINALS[@]}"; do
                if command -v $term &> /dev/null; then
                    echo "Using $term..."
                    
                    WINDOW_NUM=1
                    for ((r=0; r<ROWS; r++)); do
                        for ((c=0; c<COLS; c++)); do
                            X=$((c * WIDTH + 10))
                            Y=$((r * HEIGHT + 30))
                            
                            $term -geometry "${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" &
                            
                            WINDOW_NUM=$((WINDOW_NUM + 1))
                            sleep 0.1
                        done
                    done
                    
                    echo "Done! Opened $((ROWS * COLS)) $term windows"
                    exit 0
                fi
            done
            
            echo "Error: No suitable terminal emulator found"
            echo "Please install one of: gnome-terminal, xterm, konsole"
            exit 1
        fi
        ;;
esac

echo ""
echo "Tips:"
echo "  - To use a specific terminal next time:"
echo "    ./$(basename $0) $ROWS $COLS 2     # Force xterm"
echo "    METHOD=xterm ./$(basename $0)       # Using environment variable"
echo "  - Close all windows: pkill gnome-terminal (or xterm, konsole)"