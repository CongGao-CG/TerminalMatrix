#!/usr/bin/env bash
set -euo pipefail

# Usage: ./tile_terminals.sh [ROWS] [COLS]
ROWS=${1:-2}
COLS=${2:-2}

# Which terminal emulator to launch?
TERMINAL_CMD=${TERMINAL_CMD:-gnome-terminal}

# Check dependencies
for cmd in xdpyinfo xdotool; do
  command -v $cmd >/dev/null 2>&1 || {
    echo "Error: '$cmd' is required. Install it (e.g. apt install xdpyinfo xdotool)" >&2
    exit 1
  }
done

# Get screen resolution
read SCREEN_W SCREEN_H < <(
  xdpyinfo \
    | awk '/dimensions/{ split($2,a,"x"); print a[1],a[2]; exit }'
)

TOTAL=$((ROWS * COLS))

echo "Opening $TOTAL terminals ($ROWS×$COLS)…"
for ((i=0; i<TOTAL; i++)); do
  $TERMINAL_CMD &
  sleep 0.2
done

# Give X a moment to map all windows
sleep 0.5

# Fetch the newest $TOTAL terminal windows
# (tail should pick the most recently opened ones)
WINDOW_IDS=($(xdotool search --onlyvisible --class gnome-terminal | tail -n $TOTAL))

# Compute each tile’s size
TILE_W=$(( SCREEN_W / COLS ))
TILE_H=$(( SCREEN_H / ROWS ))

# Tile them in row-major order
idx=0
for ((r=0; r<ROWS; r++)); do
  for ((c=0; c<COLS; c++)); do
    win=${WINDOW_IDS[$idx]}
    X=$(( c * TILE_W ))
    Y=$(( r * TILE_H ))
    xdotool windowsize $win $TILE_W $TILE_H
    xdotool windowmove $win $X $Y
    idx=$((idx+1))
  done
done

echo "Done: arranged $TOTAL windows in a ${ROWS}×${COLS} grid."