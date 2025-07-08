#!/bin/bash
# Xterm grid launcher for HPC systems - Enhanced version
#
# Cell dimensions: This script supports manual cell width/height settings.
# A “cell” is a single character space in the terminal. For example:
#   – 8×16 pixels per cell is common for bitmap fonts
#   – 10×20 pixels per cell provides more spacing
# The script calculates how many characters fit in each window based on these dimensions.

###############################################################################
# 1. DEFAULTS & CONFIGURATION
###############################################################################

# Grid size (rows × columns)
ROWS=${1:-2}
COLS=${2:-2}

# Built-in colour schemes
declare -A COLORS
COLORS[1]="black:white"      # Classic
COLORS[2]="#1e1e1e:#00ff00"  # Matrix green
COLORS[3]="#002b36:#839496"  # Solarized dark
COLORS[4]="#000080:#ffffff"  # Navy blue
COLORS[5]="#2e3440:#d8dee9"  # Nord theme

# User-tweakable settings (may also be overridden by env-vars or CLI flags)
COLOR_SCHEME=${XTERM_COLOR:-1}
FONT_FAMILY=${XTERM_FONT:-"Monospace"}
FONT_SIZE=${XTERM_FONT_SIZE:-10}
SCROLLBACK=${XTERM_SCROLLBACK:-10000}

# >>> UPDATED DEFAULT CELL SIZE <<<
CELL_WIDTH=${XTERM_CELL_WIDTH:-9}     # pixels per character cell (width)
CELL_HEIGHT=${XTERM_CELL_HEIGHT:-19}  # pixels per character cell (height)

###############################################################################
# 2. HELP
###############################################################################

show_help() {
cat << EOF
Xterm Grid Launcher for HPC Systems
===================================

Usage: $0 [ROWS] [COLS] [OPTIONS]

Arguments
  ROWS                  Number of terminal rows (default: 2)
  COLS                  Number of terminal columns (default: 2)

Options
  -h, --help            Show this help and exit
  -c, --color N         Colour scheme (1-5, default: 1)
  -f, --font NAME       Font family (default: Monospace)
  -s, --font-size PT    Font size in points (default: 10)
  -t, --title TEXT      Window-title prefix
  -e, --exec CMD        Command to run inside each xterm
  -w, --working-dir DIR Working directory for each xterm
  -g, --geometry WxH    Force character geometry (chars × lines)
      --cell-width PX   Pixel width of one character cell (default: 9)
      --cell-height PX  Pixel height of one character cell (default: 19)
  -m, --monitor N       Place grid on monitor N (multi-monitor)

Environment variables
  XTERM_COLOR           Default colour scheme (1-5)
  XTERM_FONT            Default font family
  XTERM_FONT_SIZE       Default font size
  XTERM_SCROLLBACK      Scrollback buffer size
  XTERM_CELL_WIDTH      Default cell width (px)
  XTERM_CELL_HEIGHT     Default cell height (px)
  SCREEN_WIDTH          Override detected screen width (px)
  SCREEN_HEIGHT         Override detected screen height (px)

Examples
  $0                       # 2×2 grid, defaults
  $0 3 3 -c 2              # 3×3 grid, Matrix theme
  $0 4 4 -e htop           # 4×4 grid running htop
  $0 --cell-width 10 --cell-height 20
  $0 -f "DejaVu Sans Mono" -s 12

EOF
exit 0
}

###############################################################################
# 3. ARGUMENT PARSING
###############################################################################

TITLE_PREFIX="Terminal"
EXEC_COMMAND=""
WORKING_DIR=""
FORCE_GEOMETRY=""
MONITOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)          show_help ;;
        -c|--color)         COLOR_SCHEME="$2"; shift 2 ;;
        -f|--font)          FONT_FAMILY="$2"; shift 2 ;;
        -s|--font-size)     FONT_SIZE="$2"; shift 2 ;;
        -t|--title)         TITLE_PREFIX="$2"; shift 2 ;;
        -e|--exec)          EXEC_COMMAND="$2"; shift 2 ;;
        -w|--working-dir)   WORKING_DIR="$2"; shift 2 ;;
        -g|--geometry)      FORCE_GEOMETRY="$2"; shift 2 ;;
        --cell-width)       CELL_WIDTH="$2"; shift 2 ;;
        --cell-height)      CELL_HEIGHT="$2"; shift 2 ;;
        -m|--monitor)       MONITOR="$2"; shift 2 ;;
        *)  # numeric args for ROWS/COLS
            if [[ $1 =~ ^[0-9]+$ ]]; then
                if [[ -z $ROWS_SET ]]; then ROWS=$1; ROWS_SET=1
                elif [[ -z $COLS_SET ]]; then COLS=$1; COLS_SET=1
                fi
            fi
            shift ;;
    esac
done

###############################################################################
# 4. PREREQUISITE CHECKS
###############################################################################

command -v xterm >/dev/null || {
    echo "Error: xterm not found in PATH."; exit 1; }

[[ -z $DISPLAY ]] && {
    echo "Error: no DISPLAY set – X11 forwarding required."; exit 1; }

###############################################################################
# 5. SCREEN GEOMETRY
###############################################################################

if command -v xdpyinfo >/dev/null; then
    dims=$(xdpyinfo | awk '/dimensions:/ {print $2}')
    SCREEN_WIDTH=${SCREEN_WIDTH:-${dims%x*}}
    SCREEN_HEIGHT=${SCREEN_HEIGHT:-${dims#*x}}
fi
SCREEN_WIDTH=${SCREEN_WIDTH:-1920}
SCREEN_HEIGHT=${SCREEN_HEIGHT:-1080}

# Layout calculations
MARGIN=30
TASKBAR=30
USABLE_W=$SCREEN_WIDTH
USABLE_H=$((SCREEN_HEIGHT - TASKBAR))
WIN_W=$(( (USABLE_W + MARGIN) / COLS ))
WIN_H=$(( (USABLE_H + MARGIN) / ROWS ))

# Character geometry
if [[ -n $FORCE_GEOMETRY ]]; then
    CHAR_W=${FORCE_GEOMETRY%x*}
    CHAR_H=${FORCE_GEOMETRY#*x}
elif [[ -n $CELL_WIDTH && -n $CELL_HEIGHT ]]; then
    CHAR_W=$(( (WIN_W - MARGIN) / CELL_WIDTH ))
    CHAR_H=$(( (WIN_H - MARGIN) / CELL_HEIGHT ))
else
    pix=$((FONT_SIZE * 7 / 10))
    CHAR_W=$(( WIN_W / pix ))
    CHAR_H=$(( WIN_H / (FONT_SIZE + 4) ))
fi

# Parse colour scheme
IFS=':' read -r BG FG <<< "${COLORS[$COLOR_SCHEME]}"

###############################################################################
# 6. INFO DUMP
###############################################################################

echo "=== Xterm Grid Launcher ========================================="
echo "Grid:        ${ROWS}×${COLS}  (total $((ROWS*COLS)))"
echo "Screen:      ${SCREEN_WIDTH}×${SCREEN_HEIGHT}px"
echo "Window size: ${CHAR_W}×${CHAR_H} chars"
echo "Cell size:   ${CELL_WIDTH}×${CELL_HEIGHT}px"
echo "Font:        $FONT_FAMILY $FONT_SIZE pt"
echo "Colours:     bg=$BG  fg=$FG"
[[ $WORKING_DIR ]] && echo "Working dir: $WORKING_DIR"
[[ $EXEC_COMMAND ]] && echo "Command:     $EXEC_COMMAND"
echo "================================================================="

###############################################################################
# 7. LAUNCH FUNCTIONS
###############################################################################

PID_FILE="/tmp/xterm_grid_$$.pids"
: > "$PID_FILE"

launch_xterm () {
    local row=$1 col=$2 idx=$3
    local X=$(( col * WIN_W + MARGIN ))
    local Y=$(( row * WIN_H + MARGIN ))

    cmd=( xterm
          -geometry "${CHAR_W}x${CHAR_H}+${X}+${Y}"
          -title "${TITLE_PREFIX} ${idx} [$(($row+1)),$(($col+1))]"
          -bg "$BG" -fg "$FG"
          -fa "$FONT_FAMILY" -fs "$FONT_SIZE"
          -sb -sl "$SCROLLBACK" +si -bc )

    if [[ $WORKING_DIR ]]; then
        cmd+=( -e "cd \"$WORKING_DIR\" && bash" )
    elif [[ $EXEC_COMMAND ]]; then
        cmd+=( -e "$EXEC_COMMAND" )
    fi

    "${cmd[@]}" &
    echo $! >> "$PID_FILE"
}

###############################################################################
# 8. GRID LAUNCH
###############################################################################

echo "Launching xterms ..."
idx=1
for ((r=0; r<ROWS; r++)); do
    for ((c=0; c<COLS; c++)); do
        launch_xterm "$r" "$c" "$idx"
        ((idx++))
        sleep 0.05   # small pause for WM
    done
done

###############################################################################
# 9. MANAGEMENT SCRIPT
###############################################################################

cat > "/tmp/xterm_grid_$$.manage" <<EOF
#!/bin/bash
PID_FILE="$PID_FILE"
case "\$1" in
  list)
    for p in \$(cat "\$PID_FILE"); do
        ps -p \$p &>/dev/null \
          && echo "\$p running" \
          || echo "\$p terminated"
    done ;;
  kill)
    echo "Killing all xterms ..."
    kill \$(cat "\$PID_FILE") 2>/dev/null
    rm -f "\$PID_FILE" ;;
  *)  echo "Usage: \$0 {list|kill}" ;;
esac
EOF
chmod +x "/tmp/xterm_grid_$$.manage"

echo "All xterms launched.  PID list: $PID_FILE"
echo "Helper: /tmp/xterm_grid_$$.manage  {list|kill}"
echo "================================================================="

exit 0