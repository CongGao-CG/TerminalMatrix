#!/bin/bash
# Xterm grid launcher for HPC systems - Enhanced version

# Default grid size
ROWS=${1:-2}
COLS=${2:-2}

# Color schemes
declare -A COLORS
COLORS[1]="black:white"      # Classic
COLORS[2]="#1e1e1e:#00ff00"  # Matrix green
COLORS[3]="#002b36:#839496"  # Solarized dark
COLORS[4]="#000080:#ffffff"  # Navy blue
COLORS[5]="#2e3440:#d8dee9"  # Nord theme

# Configuration
COLOR_SCHEME=${XTERM_COLOR:-1}
FONT_FAMILY=${XTERM_FONT:-"Monospace"}
FONT_SIZE=${XTERM_FONT_SIZE:-10}
SCROLLBACK=${XTERM_SCROLLBACK:-10000}

# Help function
show_help() {
    cat << EOF
Xterm Grid Launcher for HPC Systems

Usage: $0 [ROWS] [COLS] [OPTIONS]

Arguments:
    ROWS    Number of rows (default: 2)
    COLS    Number of columns (default: 2)

Options:
    -h, --help              Show this help message
    -c, --color SCHEME      Color scheme (1-5, default: 1)
    -f, --font FONT         Font family (default: Monospace)
    -s, --font-size SIZE    Font size (default: 10)
    -t, --title PREFIX      Window title prefix
    -e, --exec COMMAND      Execute command in each terminal
    -w, --working-dir DIR   Set working directory
    -g, --geometry WxH      Force specific character dimensions
    -m, --monitor N         Place on monitor N (for multi-monitor setups)

Environment Variables:
    SCREEN_WIDTH           Override detected screen width
    SCREEN_HEIGHT          Override detected screen height
    XTERM_COLOR           Default color scheme (1-5)
    XTERM_FONT            Default font family
    XTERM_FONT_SIZE       Default font size
    XTERM_SCROLLBACK      Scrollback buffer lines

Examples:
    $0                    # 2x2 grid with defaults
    $0 3 3                # 3x3 grid
    $0 2 4 -c 2           # 2x4 grid with Matrix theme
    $0 4 4 -e htop        # 4x4 grid running htop
    $0 2 2 -w /scratch    # 2x2 grid in /scratch directory

Color Schemes:
    1 - Classic (black/white)
    2 - Matrix (dark/green)
    3 - Solarized dark
    4 - Navy blue
    5 - Nord theme

EOF
    exit 0
}

# Parse command line options
TITLE_PREFIX="Terminal"
EXEC_COMMAND=""
WORKING_DIR=""
FORCE_GEOMETRY=""
MONITOR=""

# Simple argument parsing
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -c|--color)
            COLOR_SCHEME="$2"
            shift 2
            ;;
        -f|--font)
            FONT_FAMILY="$2"
            shift 2
            ;;
        -s|--font-size)
            FONT_SIZE="$2"
            shift 2
            ;;
        -t|--title)
            TITLE_PREFIX="$2"
            shift 2
            ;;
        -e|--exec)
            EXEC_COMMAND="$2"
            shift 2
            ;;
        -w|--working-dir)
            WORKING_DIR="$2"
            shift 2
            ;;
        -g|--geometry)
            FORCE_GEOMETRY="$2"
            shift 2
            ;;
        -m|--monitor)
            MONITOR="$2"
            shift 2
            ;;
        *)
            # Assume numeric arguments are rows/cols
            if [[ $1 =~ ^[0-9]+$ ]]; then
                if [ -z "$ROWS_SET" ]; then
                    ROWS=$1
                    ROWS_SET=1
                elif [ -z "$COLS_SET" ]; then
                    COLS=$1
                    COLS_SET=1
                fi
            fi
            shift
            ;;
    esac
done

# Check prerequisites
if ! command -v xterm &> /dev/null; then
    echo "Error: xterm not found"
    echo ""
    echo "Installation options:"
    echo "  1. module load xterm"
    echo "  2. apt-get install xterm     (Debian/Ubuntu)"
    echo "  3. yum install xterm         (RHEL/CentOS)"
    echo "  4. conda install -c conda-forge xterm"
    exit 1
fi

if [ -z "$DISPLAY" ]; then
    echo "Error: No DISPLAY variable set"
    echo ""
    echo "X11 forwarding is required. Try:"
    echo "  1. ssh -X username@hpc-system"
    echo "  2. ssh -Y username@hpc-system  (if -X doesn't work)"
    echo "  3. Check if X11Forwarding is enabled in sshd_config"
    echo ""
    echo "To test X11: xeyes or xclock"
    exit 1
fi

# Try to detect screen dimensions
if command -v xdpyinfo &> /dev/null; then
    SCREEN_DIM=$(xdpyinfo 2>/dev/null | grep dimensions | sed 's/.*dimensions:\s*\([0-9]*x[0-9]*\).*/\1/')
    if [ -n "$SCREEN_DIM" ]; then
        AUTO_WIDTH=$(echo $SCREEN_DIM | cut -d'x' -f1)
        AUTO_HEIGHT=$(echo $SCREEN_DIM | cut -d'x' -f2)
        SCREEN_WIDTH=${SCREEN_WIDTH:-$AUTO_WIDTH}
        SCREEN_HEIGHT=${SCREEN_HEIGHT:-$AUTO_HEIGHT}
    fi
fi

# Default screen dimensions if detection failed
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}

# Calculate window layout
MARGIN=20
TASKBAR_HEIGHT=50
USABLE_WIDTH=$((SCREEN_WIDTH - MARGIN * 2))
USABLE_HEIGHT=$((SCREEN_HEIGHT - TASKBAR_HEIGHT - MARGIN))

WIN_WIDTH=$((USABLE_WIDTH / COLS))
WIN_HEIGHT=$((USABLE_HEIGHT / ROWS))

# Character dimensions (approximate)
if [ -n "$FORCE_GEOMETRY" ]; then
    CHAR_WIDTH=$(echo $FORCE_GEOMETRY | cut -d'x' -f1)
    CHAR_HEIGHT=$(echo $FORCE_GEOMETRY | cut -d'x' -f2)
else
    # Estimate based on font size
    CHAR_PIXELS=$((FONT_SIZE * 7 / 10))  # Rough estimate
    CHAR_WIDTH=$((WIN_WIDTH / CHAR_PIXELS))
    CHAR_HEIGHT=$((WIN_HEIGHT / (FONT_SIZE + 4)))
fi

# Parse color scheme
IFS=':' read -r BG_COLOR FG_COLOR <<< "${COLORS[$COLOR_SCHEME]}"

# Display configuration
echo "Xterm Grid Launcher Configuration:"
echo "=================================="
echo "Grid:        ${ROWS}x${COLS} = $((ROWS*COLS)) terminals"
echo "Screen:      ${SCREEN_WIDTH}x${SCREEN_HEIGHT} pixels"
echo "Window:      ${CHAR_WIDTH}x${CHAR_HEIGHT} characters"
echo "Font:        $FONT_FAMILY $FONT_SIZE pt"
echo "Colors:      $BG_COLOR (bg) / $FG_COLOR (fg)"
echo "Scrollback:  $SCROLLBACK lines"
[ -n "$WORKING_DIR" ] && echo "Working Dir: $WORKING_DIR"
[ -n "$EXEC_COMMAND" ] && echo "Command:     $EXEC_COMMAND"
echo "=================================="
echo ""

# Create PID tracking file
PID_FILE="/tmp/xterm_grid_$$_pids"
> "$PID_FILE"

# Function to launch xterm
launch_xterm() {
    local row=$1
    local col=$2
    local num=$3
    
    # Calculate position
    local x=$((col * WIN_WIDTH + MARGIN))
    local y=$((row * WIN_HEIGHT + MARGIN))
    
    # Build xterm command
    local xterm_cmd=(
        xterm
        -geometry "${CHAR_WIDTH}x${CHAR_HEIGHT}+${x}+${y}"
        -title "$TITLE_PREFIX $num [$((row+1)),$((col+1))]"
        -bg "$BG_COLOR"
        -fg "$FG_COLOR"
        -fa "$FONT_FAMILY"
        -fs "$FONT_SIZE"
        -sb
        -sl "$SCROLLBACK"
        +si  # Enable scroll on output
        -bc  # Turn on text cursor blinking
    )
    
    # Add optional parameters
    [ -n "$WORKING_DIR" ] && xterm_cmd+=(-e "cd '$WORKING_DIR' && bash")
    [ -n "$EXEC_COMMAND" ] && [ -z "$WORKING_DIR" ] && xterm_cmd+=(-e "$EXEC_COMMAND")
    
    # Launch xterm
    "${xterm_cmd[@]}" &
    
    # Save PID
    echo $! >> "$PID_FILE"
    
    return $!
}

# Launch grid
echo "Launching terminals..."
N=1

for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        launch_xterm $r $c $N
        ((N++))
        
        # Prevent window manager overload
        sleep 0.05
    done
done

# Get all PIDs
PIDS=($(cat "$PID_FILE"))

echo ""
echo "Successfully launched $((ROWS*COLS)) xterm windows"
echo "PIDs saved to: $PID_FILE"
echo ""
echo "Management commands:"
echo "  List:      ps -p ${PIDS[0]},${PIDS[1]}..."
echo "  Kill all:  kill \$(cat $PID_FILE)"
echo "  Kill one:  kill PID"
echo ""

# Optional: Create management script
MANAGE_SCRIPT="/tmp/xterm_grid_$$_manage.sh"
cat > "$MANAGE_SCRIPT" << EOF
#!/bin/bash
# Xterm grid management script
PID_FILE="$PID_FILE"

case "\$1" in
    list)
        echo "Active xterm PIDs:"
        for pid in \$(cat "\$PID_FILE"); do
            if ps -p \$pid > /dev/null 2>&1; then
                echo "  \$pid - running"
            else
                echo "  \$pid - terminated"
            fi
        done
        ;;
    kill)
        echo "Killing all xterm windows..."
        kill \$(cat "\$PID_FILE") 2>/dev/null
        rm -f "\$PID_FILE"
        ;;
    tile)
        echo "Re-tiling windows..."
        # This would require wmctrl or similar
        echo "Not implemented - requires window manager tools"
        ;;
    *)
        echo "Usage: \$0 {list|kill|tile}"
        ;;
esac
EOF

chmod +x "$MANAGE_SCRIPT"
echo "Management script: $MANAGE_SCRIPT {list|kill|tile}"
echo ""

# Wait for a moment to ensure all windows are opened
sleep 1

# Success message
echo "Grid layout complete!"