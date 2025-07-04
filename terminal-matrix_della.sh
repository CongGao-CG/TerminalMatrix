#!/bin/bash

ROWS=${1:-2}
COLS=${2:-2}

echo "Terminal Grid Launcher for Restricted Environments"
echo "=================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Option 1: Use tmux if available
if command_exists tmux; then
    echo "Found tmux - creating ${ROWS}x${COLS} grid..."
    
    SESSION_NAME="grid-$$"
    
    # Create new tmux session
    tmux new-session -d -s "$SESSION_NAME"
    
    # Create the grid layout
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $r -eq 0 ] && [ $c -eq 0 ]; then
                # First pane already exists
                continue
            elif [ $c -eq 0 ]; then
                # New row - split horizontally
                tmux split-window -v -t "$SESSION_NAME"
                tmux select-layout -t "$SESSION_NAME" tiled
            else
                # Same row - split vertically
                tmux split-window -h -t "$SESSION_NAME"
                tmux select-layout -t "$SESSION_NAME" tiled
            fi
        done
    done
    
    # Arrange panes evenly
    tmux select-layout -t "$SESSION_NAME" tiled
    
    # Attach to session
    echo "Attaching to tmux session..."
    tmux attach-session -t "$SESSION_NAME"
    
    exit 0
fi

# Option 2: Use GNU screen if available
if command_exists screen; then
    echo "Found screen - creating ${ROWS}x${COLS} grid..."
    echo ""
    echo "Note: screen doesn't support automatic grid layouts."
    echo "Creating a screen session with multiple windows instead."
    
    SCREENRC_TEMP="/tmp/screenrc-grid-$$"
    
    # Create temporary screenrc
    cat > "$SCREENRC_TEMP" << EOF
# Temporary screen configuration for grid
startup_message off
caption always "%{= kw}%-w%{= BW}%n %t%{-}%+w %-= %{g}%H %{Y}%l"

# Create windows
EOF
    
    TOTAL=$((ROWS * COLS))
    for ((i=0; i<TOTAL; i++)); do
        echo "screen -t \"Window-$((i+1))\"" >> "$SCREENRC_TEMP"
    done
    
    # Start screen with config
    screen -c "$SCREENRC_TEMP" -S "grid-$$"
    
    # Clean up
    rm -f "$SCREENRC_TEMP"
    
    exit 0
fi

# Option 3: Basic terminal approach (no multiplexer)
echo "No terminal multiplexer found (tmux or screen)."
echo ""
echo "Alternative options:"
echo ""

# Check if we can at least open multiple terminals
if [ -n "$DISPLAY" ]; then
    echo "1. X11 display detected. Trying to open multiple terminal windows..."
    
    # Try to find an available terminal emulator
    for term in xterm rxvt urxvt gnome-terminal konsole xfce4-terminal; do
        if command_exists "$term"; then
            echo "   Found: $term"
            echo "   Opening $((ROWS * COLS)) terminal windows..."
            
            for ((i=1; i<=ROWS*COLS; i++)); do
                case $term in
                    xterm|rxvt|urxvt)
                        $term -title "Terminal $i" -geometry 80x24 &
                        ;;
                    gnome-terminal|konsole|xfce4-terminal)
                        $term --title="Terminal $i" &
                        ;;
                esac
                sleep 0.2
            done
            
            echo "   Done! Please arrange windows manually."
            exit 0
        fi
    done
    
    echo "   No supported terminal emulator found."
fi

# Option 4: Suggest installation
echo "2. To get the best experience, ask your system administrator to install:"
echo "   - tmux (recommended): Creates proper split-pane layouts"
echo "   - screen: Creates multiple windows in one terminal"
echo "   - wmctrl: For automatic window positioning"
echo ""

# Option 5: Manual instructions
echo "3. Manual alternative - use your terminal's built-in features:"
echo "   - Many terminals support tabs (Ctrl+Shift+T)"
echo "   - Some support split panes (varies by terminal)"
echo "   - SSH clients like PuTTY can save multiple sessions"
echo ""

# Option 6: Check for module system (common on HPC)
if command_exists module; then
    echo "4. Module system detected. Try:"
    echo "   module avail tmux"
    echo "   module avail screen"
    echo "   module load tmux  # if available"
fi