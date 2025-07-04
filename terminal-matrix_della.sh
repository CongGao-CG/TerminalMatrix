#!/bin/bash

# Terminal grid arrangement script for Linux using tmux
# Works without requiring sudo/package installation

ROWS=${1:-2}
COLS=${2:-2}

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is not available on this system"
    echo "Trying alternative method with xterm..."
    
    # Alternative: Try to use xterm if available
    if command -v xterm &> /dev/null; then
        echo "Opening ${ROWS}x${COLS} xterm windows..."
        WIDTH=$((1920 / COLS))  # Adjust based on your screen resolution
        HEIGHT=$((1080 / ROWS))  # Adjust based on your screen resolution
        
        for ((r=0; r<ROWS; r++)); do
            for ((c=0; c<COLS; c++)); do
                X=$((c * WIDTH))
                Y=$((r * HEIGHT))
                xterm -geometry 80x24+${X}+${Y} &
                sleep 0.1
            done
        done
        echo "Done! Opened $((ROWS * COLS)) xterm windows"
    else
        echo "Neither tmux nor xterm is available. Please contact your system administrator."
        exit 1
    fi
    exit 0
fi

# Using tmux for terminal grid
SESSION_NAME="grid_$$"  # Use PID to make session name unique

echo "Creating ${ROWS}x${COLS} terminal grid using tmux..."

# Kill existing session if it exists
tmux kill-session -t $SESSION_NAME 2>/dev/null

# Create new tmux session
tmux new-session -d -s $SESSION_NAME

# Function to create panes in a window
create_grid_in_window() {
    local rows=$1
    local cols=$2
    
    # Create horizontal splits first (rows)
    for ((r=1; r<rows; r++)); do
        # Calculate percentage for even splits
        percentage=$((100 - (100 / (rows - r + 1))))
        tmux split-window -v -p $percentage
    done
    
    # Now split each row into columns
    # Total panes after row splits
    total_row_panes=$rows
    
    for ((pane=0; pane<total_row_panes; pane++)); do
        # Select the pane
        tmux select-pane -t $pane
        
        # Create column splits in this pane (except the last column)
        for ((c=1; c<cols; c++)); do
            percentage=$((100 - (100 / (cols - c + 1))))
            tmux split-window -h -p $percentage
        done
    done
    
    # Select first pane
    tmux select-pane -t 0
}

# Create the grid
create_grid_in_window $ROWS $COLS

# Optional: Run a command in each pane (uncomment and modify as needed)
# TOTAL_PANES=$((ROWS * COLS))
# for ((i=0; i<TOTAL_PANES; i++)); do
#     tmux send-keys -t $SESSION_NAME:0.$i "echo 'Pane $i'" C-m
# done

# Attach to the session
echo "Attaching to tmux session..."
tmux attach-session -t $SESSION_NAME

# Note: When you're done, you can exit tmux with Ctrl-B then D (detach)
# Or kill the session with: tmux kill-session -t $SESSION_NAME