#!/bin/bash

# GNOME Terminal grid arrangement script
# Opens separate windows arranged in a grid

ROWS=${1:-2}
COLS=${2:-2}

echo "Creating ${ROWS}x${COLS} grid of GNOME Terminal windows..."

# Get screen dimensions using xrandr (more reliable than xdpyinfo)
if command -v xrandr &> /dev/null; then
    # Get primary monitor dimensions
    SCREEN_INFO=$(xrandr | grep primary | grep -oP '\d+x\d+\+\d+\+\d+')
    RESOLUTION=$(echo $SCREEN_INFO | cut -d'+' -f1)
    SCREEN_WIDTH=$(echo $RESOLUTION | cut -d'x' -f1)
    SCREEN_HEIGHT=$(echo $RESOLUTION | cut -d'x' -f2)
    echo "Primary monitor resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
else
    # Fallback dimensions
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
    echo "Using default resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
fi

# Calculate usable area (leaving space for panels/taskbars)
PANEL_HEIGHT=50  # Adjust based on your desktop environment
MARGIN=20        # Margin between windows

USABLE_WIDTH=$((SCREEN_WIDTH - MARGIN))
USABLE_HEIGHT=$((SCREEN_HEIGHT - PANEL_HEIGHT - MARGIN))

# Calculate window dimensions
WINDOW_WIDTH=$((USABLE_WIDTH / COLS - MARGIN))
WINDOW_HEIGHT=$((USABLE_HEIGHT / ROWS - MARGIN))

# Terminal character dimensions (gnome-terminal specific)
# These work well for default font sizes
TERM_COLS=$((WINDOW_WIDTH / 8))    # ~8 pixels per character
TERM_ROWS=$((WINDOW_HEIGHT / 17))  # ~17 pixels per line

# Open windows in grid
WINDOW_NUM=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        # Calculate position
        X=$((c * (WINDOW_WIDTH + MARGIN) + MARGIN))
        Y=$((r * (WINDOW_HEIGHT + MARGIN) + PANEL_HEIGHT))
        
        # Window title
        TITLE="Terminal ${WINDOW_NUM} [$((r+1)),$((c+1))]"
        
        # Launch gnome-terminal
        # Using -- to separate gnome-terminal options from command options
        gnome-terminal \
            --window \
            --geometry="${TERM_COLS}x${TERM_ROWS}+${X}+${Y}" \
            --title="${TITLE}" \
            --hide-menubar \
            -- bash -c "
                echo '═══════════════════════════════════════'
                echo ' Terminal ${WINDOW_NUM} - Position [$((r+1)),$((c+1))]'
                echo ' Size: ${TERM_COLS}x${TERM_ROWS}'
                echo ' Location: +${X}+${Y}'
                echo '═══════════════════════════════════════'
                echo ''
                exec bash
            " &
        
        # Increment window number
        WINDOW_NUM=$((WINDOW_NUM + 1))
        
        # Small delay to prevent window manager confusion
        sleep 0.3
    done
done

echo ""
echo "Successfully opened $((ROWS * COLS)) terminal windows!"
echo ""
echo "Tips:"
echo "  - Windows are arranged in a ${ROWS}x${COLS} grid"
echo "  - Each window shows its grid position"
echo "  - Use Alt+Tab to switch between windows"
echo "  - Use Alt+F4 to close individual windows"
echo ""

# Optional: Save configuration for reference
CONFIG_FILE="$HOME/.terminal_grid_config"
cat > "$CONFIG_FILE" << EOF
# Terminal Grid Configuration
# Generated: $(date)
ROWS=$ROWS
COLS=$COLS
SCREEN_WIDTH=$SCREEN_WIDTH
SCREEN_HEIGHT=$SCREEN_HEIGHT
WINDOW_WIDTH=$WINDOW_WIDTH
WINDOW_HEIGHT=$WINDOW_HEIGHT
TERM_COLS=$TERM_COLS
TERM_ROWS=$TERM_ROWS
EOF

echo "Configuration saved to: $CONFIG_FILE"