#!/bin/bash

# Terminal grid arrangement script for Linux - Opens separate windows
# Works with gnome-terminal, xterm, or other X11 terminals

ROWS=${1:-2}
COLS=${2:-2}

echo "Arranging terminals in ${ROWS}x${COLS} grid with separate windows..."

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
# Leave some space for window decorations and taskbar
USABLE_WIDTH=$((SCREEN_WIDTH - 50))
USABLE_HEIGHT=$((SCREEN_HEIGHT - 100))

WIDTH=$((USABLE_WIDTH / COLS))
HEIGHT=$((USABLE_HEIGHT / ROWS))

# Character dimensions for terminal (approximate)
TERM_COLS=$((WIDTH / 9))    # ~9 pixels per character width
TERM_ROWS=$((HEIGHT / 20))   # ~20 pixels per character height

# Adjust for window decorations
WIN_WIDTH=$((WIDTH - 10))
WIN_HEIGHT=$((HEIGHT - 30))

# Method 1: gnome-terminal (preferred for GNOME desktops)
if command -v gnome-terminal &> /dev/null; then
    echo "Using gnome-terminal to create separate windows..."
    
    WINDOW_NUM=1
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH + 10))
            Y=$((r * HEIGHT + 30))
            
            # Open gnome-terminal with specific geometry
            # Format: WIDTHxHEIGHT+X+Y
            gnome-terminal \
                --geometry="${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
                --title="Terminal ${WINDOW_NUM} (${r},${c})" \
                -- bash -c "echo 'Terminal ${WINDOW_NUM} - Grid position (${r},${c})'; exec bash" &
            
            WINDOW_NUM=$((WINDOW_NUM + 1))
            sleep 0.2  # Small delay to prevent window manager issues
        done
    done
    
    echo "Done! Opened $((ROWS * COLS)) gnome-terminal windows"
    exit 0
fi

# Method 2: xterm (fallback, available on most X11 systems)
if command -v xterm &> /dev/null; then
    echo "gnome-terminal not found, using xterm..."
    
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
    
    echo "Done! Opened $((ROWS * COLS)) xterm windows"
    exit 0
fi

# Method 3: konsole (for KDE)
if command -v konsole &> /dev/null; then
    echo "Using konsole..."
    
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
    
    echo "Done! Opened $((ROWS * COLS)) konsole windows"
    exit 0
fi

# Method 4: Generic terminal command (tries common terminal emulators)
TERMINALS=("x-terminal-emulator" "urxvt" "rxvt" "termite" "alacritty" "kitty")

for term in "${TERMINALS[@]}"; do
    if command -v $term &> /dev/null; then
        echo "Using $term..."
        
        WINDOW_NUM=1
        for ((r=0; r<ROWS; r++)); do
            for ((c=0; c<COLS; c++)); do
                X=$((c * WIDTH + 10))
                Y=$((r * HEIGHT + 30))
                
                # Most terminals support -geometry flag
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