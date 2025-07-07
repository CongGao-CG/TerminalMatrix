#!/bin/bash
# HPC Terminal Grid Launcher - Multiple options for different environments

ROWS=${1:-2}
COLS=${2:-2}

# Option 1: tmux (most common on HPC systems)
launch_tmux_grid() {
    echo "Launching tmux grid layout..."
    
    # Create new tmux session
    SESSION="grid-$$"
    tmux new-session -d -s "$SESSION"
    
    # Create the grid layout
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            # Skip first pane (already created)
            if [ $r -eq 0 ] && [ $c -eq 0 ]; then
                continue
            fi
            
            # Split horizontally for new rows
            if [ $c -eq 0 ]; then
                tmux split-window -v -t "$SESSION"
            # Split vertically for columns
            else
                tmux split-window -h -t "$SESSION"
            fi
            
            # Even out the layout after each split
            tmux select-layout -t "$SESSION" tiled
        done
    done
    
    # Attach to session
    tmux attach-session -t "$SESSION"
    
    echo "Session: $SESSION"
    echo "Commands: Ctrl-b arrow (navigate), Ctrl-b d (detach), tmux attach -t $SESSION (reattach)"
}

# Option 2: GNU Screen (alternative to tmux)
launch_screen_grid() {
    echo "Launching screen grid layout..."
    
    # Create screenrc for grid layout
    SCREENRC="/tmp/screenrc-grid-$$"
    cat > "$SCREENRC" << EOF
# Grid layout for screen
startup_message off
caption always "%{= kw}%-w%{= BW}%n %t%{-}%+w %-= @%H - %LD %d %LM - %c"

# Create initial regions
split -v
EOF
    
    # Add splits for grid
    for ((i=1; i<COLS; i++)); do
        echo "split -v" >> "$SCREENRC"
    done
    
    # Focus and create windows
    WINDOW=0
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            if [ $WINDOW -gt 0 ]; then
                echo "focus" >> "$SCREENRC"
                echo "screen -t \"Window $((WINDOW+1))\"" >> "$SCREENRC"
            fi
            ((WINDOW++))
        done
    done
    
    # Start screen with custom config
    screen -c "$SCREENRC"
    
    # Cleanup
    rm -f "$SCREENRC"
    
    echo "Commands: Ctrl-a Tab (navigate), Ctrl-a d (detach), screen -r (reattach)"
}

# Option 3: xterm (if X11 forwarding is available)
launch_xterm_grid() {
    echo "Launching xterm grid layout..."
    
    # Check for X11
    if [ -z "$DISPLAY" ]; then
        echo "Error: No DISPLAY variable set. Enable X11 forwarding with ssh -X"
        return 1
    fi
    
    # Get screen dimensions (approximate)
    WIDTH=$((800 / COLS))
    HEIGHT=$((600 / ROWS))
    
    # Launch xterm windows
    N=1
    for ((r=0; r<ROWS; r++)); do
        for ((c=0; c<COLS; c++)); do
            X=$((c * WIDTH))
            Y=$((r * HEIGHT))
            
            xterm -geometry "80x24+${X}+${Y}" -title "Terminal $N" &
            
            ((N++))
            sleep 0.1
        done
    done
    
    echo "Opened $((ROWS*COLS)) xterm windows"
}

# Option 4: SLURM interactive sessions (for HPC job allocation)
launch_slurm_sessions() {
    echo "Launching SLURM interactive sessions..."
    
    # Check if SLURM is available
    if ! command -v srun &> /dev/null; then
        echo "Error: SLURM not found"
        return 1
    fi
    
    # Launch multiple interactive sessions in tmux
    SESSION="slurm-grid-$$"
    tmux new-session -d -s "$SESSION"
    
    for ((i=0; i<ROWS*COLS; i++)); do
        if [ $i -gt 0 ]; then
            tmux split-window -t "$SESSION"
            tmux select-layout -t "$SESSION" tiled
        fi
        
        # Run srun in each pane (adjust parameters as needed)
        tmux send-keys -t "$SESSION:0.$i" "srun --pty bash" C-m
    done
    
    tmux attach-session -t "$SESSION"
}

# Option 5: Simple multiple SSH sessions (for cluster nodes)
launch_ssh_grid() {
    echo "Launching SSH grid to compute nodes..."
    
    # Example node list - modify for your cluster
    NODES=("node001" "node002" "node003" "node004")
    
    SESSION="ssh-grid-$$"
    tmux new-session -d -s "$SESSION"
    
    for ((i=0; i<ROWS*COLS && i<${#NODES[@]}; i++)); do
        if [ $i -gt 0 ]; then
            tmux split-window -t "$SESSION"
            tmux select-layout -t "$SESSION" tiled
        fi
        
        # SSH to each node
        tmux send-keys -t "$SESSION:0.$i" "ssh ${NODES[$i]}" C-m
    done
    
    tmux attach-session -t "$SESSION"
}

# Main menu
echo "HPC Terminal Grid Launcher"
echo "Grid size: ${ROWS}x${COLS}"
echo ""
echo "Available options:"
echo "1) tmux (recommended)"
echo "2) GNU screen"
echo "3) xterm (requires X11)"
echo "4) SLURM interactive sessions"
echo "5) SSH to compute nodes"
echo ""

# Auto-detect and suggest
if command -v tmux &> /dev/null; then
    echo "Detected: tmux available"
    DEFAULT=1
elif command -v screen &> /dev/null; then
    echo "Detected: screen available"
    DEFAULT=2
elif [ -n "$DISPLAY" ] && command -v xterm &> /dev/null; then
    echo "Detected: X11 forwarding enabled"
    DEFAULT=3
else
    echo "No terminal multiplexer detected. Consider installing tmux."
    DEFAULT=0
fi

read -p "Select option (1-5) [default: $DEFAULT]: " choice
choice=${choice:-$DEFAULT}

case $choice in
    1) launch_tmux_grid ;;
    2) launch_screen_grid ;;
    3) launch_xterm_grid ;;
    4) launch_slurm_sessions ;;
    5) launch_ssh_grid ;;
    *) echo "Invalid choice"; exit 1 ;;
esac