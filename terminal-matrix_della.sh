#!/bin/bash

# Multi-method terminal grid arrangement script for Linux HPC systems
# Tries different approaches based on what's available

ROWS=${1:-2}
COLS=${2:-2}

echo "Attempting to create ${ROWS}x${COLS} terminal grid..."

# Method 1: Try gnome-terminal with tabs (common on RHEL with GNOME)
if command -v gnome-terminal &> /dev/null; then
    echo "Using gnome-terminal..."
    
    # Create a single gnome-terminal with multiple tabs
    cmd="gnome-terminal"
    for ((i=1; i<=((ROWS * COLS)); i++)); do
        if [ $i -eq 1 ]; then
            cmd="$cmd --tab --title='Terminal $i'"
        else
            cmd="$cmd --tab --title='Terminal $i'"
        fi
    done
    
    eval $cmd &
    echo "Opened gnome-terminal with $((ROWS * COLS)) tabs"
    echo "Note: You'll need to arrange the tabs manually or use the terminal's built-in tiling"
    exit 0
fi

# Method 2: Try konsole (KDE terminal)
if command -v konsole &> /dev/null; then
    echo "Using konsole..."
    
    for ((i=1; i<=((ROWS * COLS)); i++)); do
        konsole --new-tab &
        sleep 0.2
    done
    
    echo "Opened $((ROWS * COLS)) konsole tabs"
    exit 0
fi

# Method 3: Try terminator (often available on Linux systems)
if command -v terminator &> /dev/null; then
    echo "Using terminator..."
    
    # Terminator supports layouts, but creating them programmatically is complex
    # So we'll just open it and let user split manually
    terminator &
    echo "Opened terminator. Use:"
    echo "  - Ctrl+Shift+O for horizontal split"
    echo "  - Ctrl+Shift+E for vertical split"
    echo "to create your ${ROWS}x${COLS} grid"
    exit 0
fi

# Method 4: Screen (alternative to tmux, often available on older systems)
if command -v screen &> /dev/null; then
    echo "Using GNU screen..."
    
    # Create a screen session
    SESSION_NAME="grid_$$"
    screen -dmS $SESSION_NAME
    
    # Create multiple windows
    for ((i=2; i<=((ROWS * COLS)); i++)); do
        screen -S $SESSION_NAME -X screen $i
    done
    
    echo "Created screen session with $((ROWS * COLS)) windows"
    echo "Attaching to screen session..."
    screen -r $SESSION_NAME
    echo "Use Ctrl-A + number to switch between windows"
    echo "Use Ctrl-A + D to detach"
    exit 0
fi

# Method 5: Basic xterm as fallback
if command -v xterm &> /dev/null; then
    echo "Using xterm (basic X11 terminal)..."
    
    # Try to detect screen dimensions
    if command -v xdpyinfo &> /dev/null; then
        SCREEN_DIM=$(xdpyinfo | grep dimensions | awk '{print $2}')
        SCREEN_WIDTH=$(echo $SCREEN_DIM | cut -d'x' -f1)
        SCREEN_HEIGHT=$(echo $SCREEN_DIM | cut -d'x' -f2)
    else
        # Default dimensions if we can't detect
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
    fi
    
    WIDTH=$((SCREEN_WIDTH / COLS - 20))   # Leave some margin
    HEIGHT=$((SCREEN_HEIGHT / ROWS - 40)) # Leave some margin
    
    # Calculate character dimensions (rough estimate)
    CHARS_WIDE=$((WIDTH / 9))   # Assuming ~9 pixels per character
    CHARS_HIGH=$((HEIGHT / 20)) # Assuming ~20 pixels per line
    
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * (WIDTH + 10)))
            Y=$((r * (HEIGHT + 30)))
            xterm -geometry ${CHARS_WIDE}x${CHARS_HIGH}+${X}+${Y} -title "Terminal $((r*COLS + c + 1))" &
            sleep 0.1
        done
    done
    
    echo "Opened $((ROWS * COLS)) xterm windows"
    exit 0
fi

# If we get here, no suitable method was found
echo "Error: No suitable terminal multiplexer or terminal emulator found."
echo "Available options on most HPC systems:"
echo "  1. Ask your system administrator to install tmux"
echo "  2. Use an existing terminal multiplexer if available"
echo "  3. Use your desktop environment's terminal with manual splitting"
echo ""
echo "You can check what's available with:"
echo "  which tmux screen gnome-terminal konsole xterm terminator"

exit 1