#!/bin/bash
# Extended HPC Terminal Grid Launcher - Additional Options

ROWS=${1:-2}
COLS=${2:-2}
TOTAL=$((ROWS * COLS))

# Option 6: byobu (Enhanced tmux/screen wrapper)
launch_byobu_grid() {
    echo "Launching byobu grid layout..."
    
    if ! command -v byobu &> /dev/null; then
        echo "Error: byobu not found. Install with: module load byobu (or apt/yum install byobu)"
        return 1
    fi
    
    # Byobu with F2 for new windows, Shift+F2 for splits
    byobu new-session -d
    
    for ((i=1; i<TOTAL; i++)); do
        byobu send-keys F2  # Create new window
    done
    
    byobu attach-session
    
    echo "Use F2 (new window), Shift+F2 (split), F3/F4 (navigate)"
}

# Option 7: dvtm (Dynamic Virtual Terminal Manager - lightweight)
launch_dvtm_grid() {
    echo "Launching dvtm grid layout..."
    
    if ! command -v dvtm &> /dev/null; then
        echo "Error: dvtm not found. Very lightweight, often available on minimal systems"
        return 1
    fi
    
    # Create dvtm config
    cat > /tmp/dvtm-startup-$$ << 'EOF'
#!/bin/sh
# Auto-create grid layout
for i in $(seq 2 $1); do
    echo "create"
done
echo "focusnext"
EOF
    
    chmod +x /tmp/dvtm-startup-$$
    dvtm -c /tmp/dvtm-startup-$$ $TOTAL
    
    rm -f /tmp/dvtm-startup-$$
    
    echo "Use Ctrl+g (command mode), h/j/k/l (navigate)"
}

# Option 8: GNU Parallel for distributed commands
launch_parallel_commands() {
    echo "Launching parallel command execution..."
    
    if ! command -v parallel &> /dev/null; then
        echo "Error: GNU parallel not found. Load with: module load parallel"
        return 1
    fi
    
    # Example: Run commands on multiple nodes
    read -p "Enter command to run in parallel: " CMD
    
    # Generate node/task list
    seq 1 $TOTAL | parallel -j $TOTAL --tag "echo 'Task {}:'; $CMD"
}

# Option 9: Web-based terminal (ttyd)
launch_web_terminals() {
    echo "Launching web-based terminals..."
    
    if ! command -v ttyd &> /dev/null; then
        echo "ttyd not found. Checking for alternatives..."
        
        # Try gotty
        if command -v gotty &> /dev/null; then
            echo "Using gotty instead..."
            WEBCMD="gotty"
        else
            echo "No web terminal found. Install ttyd or gotty"
            return 1
        fi
    else
        WEBCMD="ttyd"
    fi
    
    # Launch multiple web terminals on different ports
    BASE_PORT=8080
    for ((i=0; i<TOTAL; i++)); do
        PORT=$((BASE_PORT + i))
        $WEBCMD -p $PORT bash &
        echo "Terminal $((i+1)) at http://localhost:$PORT"
    done
    
    echo "Access terminals in your browser (use SSH tunnel: ssh -L 8080-$((BASE_PORT+TOTAL)):localhost:8080-$((BASE_PORT+TOTAL)) user@hpc)"
}

# Option 10: Python-based terminal multiplexer
launch_python_grid() {
    echo "Launching Python-based grid..."
    
    cat > /tmp/term_grid_$$.py << 'EOF'
#!/usr/bin/env python3
import os
import sys
import subprocess
import curses
from threading import Thread
import pty
import select
import termios
import tty

def create_terminal_grid(rows, cols):
    """Simple terminal grid using Python"""
    
    # For simplicity, launch tmux if available, else use subprocess
    try:
        subprocess.run(['tmux', '-V'], check=True, capture_output=True)
        # Use tmux via Python
        os.system(f'tmux new-session -d -s pygrid')
        for i in range(1, rows * cols):
            os.system(f'tmux split-window -t pygrid')
            os.system(f'tmux select-layout -t pygrid tiled')
        os.system(f'tmux attach-session -t pygrid')
    except:
        print("tmux not available, using alternative...")
        # Launch multiple terminals in subprocesses
        procs = []
        for i in range(rows * cols):
            proc = subprocess.Popen(['bash'], 
                                    stdin=subprocess.PIPE,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE)
            procs.append(proc)
        
        print(f"Launched {len(procs)} bash processes")
        print("Note: This is a simple implementation. Use tmux for better experience.")

if __name__ == "__main__":
    rows = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    cols = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    create_terminal_grid(rows, cols)
EOF
    
    python3 /tmp/term_grid_$$.py $ROWS $COLS
    rm -f /tmp/term_grid_$$.py
}

# Option 11: ClusterSSH / PSSH (Parallel SSH)
launch_clusterssh() {
    echo "Launching ClusterSSH/PSSH grid..."
    
    # Check for various parallel SSH tools
    if command -v cssh &> /dev/null; then
        PSSH_CMD="cssh"
    elif command -v pssh &> /dev/null; then
        PSSH_CMD="pssh"
    elif command -v pdsh &> /dev/null; then
        PSSH_CMD="pdsh"
    else
        echo "No parallel SSH tool found. Install clusterssh, pssh, or pdsh"
        return 1
    fi
    
    # Get node list
    if [ -n "$SLURM_NODELIST" ]; then
        # Use SLURM allocated nodes
        NODES=$(scontrol show hostnames $SLURM_NODELIST | head -n $TOTAL)
    else
        # Manual node entry
        echo "Enter node names (space-separated):"
        read -a NODES
    fi
    
    case $PSSH_CMD in
        cssh)
            cssh ${NODES[@]}
            ;;
        pdsh)
            # pdsh interactive mode
            PDSH_RCMD_TYPE=ssh pdsh -w $(IFS=,; echo "${NODES[*]}") -R exec bash -l
            ;;
        pssh)
            # Create hosts file
            printf '%s\n' "${NODES[@]}" > /tmp/hosts_$$
            pssh -h /tmp/hosts_$$ -i -t 0 bash
            rm -f /tmp/hosts_$$
            ;;
    esac
}

# Option 12: MPI-based terminal spawning
launch_mpi_terminals() {
    echo "Launching MPI-based terminals..."
    
    if ! command -v mpirun &> /dev/null; then
        echo "Error: MPI not found. Load with: module load mpi"
        return 1
    fi
    
    cat > /tmp/mpi_term_$$.c << 'EOF'
#include <mpi.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    char terminal[256];
    sprintf(terminal, "xterm -T 'MPI Rank %d' -e bash &", rank);
    
    if (getenv("DISPLAY") != NULL) {
        system(terminal);
    } else {
        printf("Rank %d: No DISPLAY, running in console\n", rank);
        system("bash");
    }
    
    MPI_Finalize();
    return 0;
}
EOF
    
    mpicc -o /tmp/mpi_term_$$ /tmp/mpi_term_$$.c
    mpirun -np $TOTAL /tmp/mpi_term_$$
    
    rm -f /tmp/mpi_term_$$ /tmp/mpi_term_$$.c
}

# Option 13: Job array visualization
launch_job_array_monitor() {
    echo "Launching job array monitor..."
    
    if ! command -v squeue &> /dev/null; then
        echo "Error: SLURM not available"
        return 1
    fi
    
    # Submit a job array
    read -p "Enter job array command (or press enter for demo): " JOB_CMD
    JOB_CMD=${JOB_CMD:-"sleep 60"}
    
    # Create job script
    cat > /tmp/array_job_$$.sh << EOF
#!/bin/bash
#SBATCH --array=1-$TOTAL
#SBATCH --job-name=grid_array
#SBATCH --output=grid_%a.out

echo "Task \$SLURM_ARRAY_TASK_ID starting on \$(hostname)"
$JOB_CMD
EOF
    
    # Submit and monitor
    JOB_ID=$(sbatch /tmp/array_job_$$.sh | awk '{print $4}')
    
    # Monitor in tmux grid
    tmux new-session -d -s "monitor-$JOB_ID"
    
    for ((i=0; i<TOTAL; i++)); do
        if [ $i -gt 0 ]; then
            tmux split-window -t "monitor-$JOB_ID"
            tmux select-layout -t "monitor-$JOB_ID" tiled
        fi
        
        TASK_ID=$((i + 1))
        tmux send-keys -t "monitor-$JOB_ID:0.$i" \
            "watch -n 1 'squeue -j ${JOB_ID}_${TASK_ID}; echo ---; tail -20 grid_${TASK_ID}.out'" C-m
    done
    
    tmux attach-session -t "monitor-$JOB_ID"
    
    rm -f /tmp/array_job_$$.sh
}

# Option 14: Terminator (if available with X11)
launch_terminator_grid() {
    echo "Launching Terminator grid..."
    
    if [ -z "$DISPLAY" ]; then
        echo "Error: No DISPLAY. Need X11 forwarding"
        return 1
    fi
    
    if ! command -v terminator &> /dev/null; then
        echo "Error: terminator not found"
        return 1
    fi
    
    # Create terminator config for grid
    mkdir -p ~/.config/terminator
    cat > ~/.config/terminator/config_grid << EOF
[global_config]
[profiles]
  [[default]]
[layouts]
  [[grid]]
    [[[window0]]]
      type = Window
      parent = ""
    [[[child1]]]
      type = HPaned
      parent = window0
EOF
    
    terminator -l grid
}

# Option 15: Custom FIFO-based multiplexer
launch_fifo_mux() {
    echo "Launching FIFO-based multiplexer..."
    
    FIFO_DIR="/tmp/fifomux_$$"
    mkdir -p "$FIFO_DIR"
    
    # Create FIFOs for each terminal
    for ((i=0; i<TOTAL; i++)); do
        mkfifo "$FIFO_DIR/term_$i.in"
        mkfifo "$FIFO_DIR/term_$i.out"
        
        # Launch bash with FIFO redirection
        bash < "$FIFO_DIR/term_$i.in" > "$FIFO_DIR/term_$i.out" 2>&1 &
    done
    
    echo "FIFO multiplexer ready at $FIFO_DIR"
    echo "Send commands: echo 'command' > $FIFO_DIR/term_0.in"
    echo "Read output: cat $FIFO_DIR/term_0.out"
    
    # Simple controller
    cat << 'EOF' > "$FIFO_DIR/controller.sh"
#!/bin/bash
echo "FIFO Controller - Type 'exit' to quit"
while true; do
    read -p "Term[0-$((TOTAL-1))]> " term cmd
    if [ "$term" = "exit" ]; then break; fi
    if [ -p "$FIFO_DIR/term_$term.in" ]; then
        echo "$cmd" > "$FIFO_DIR/term_$term.in"
        timeout 1 cat "$FIFO_DIR/term_$term.out"
    fi
done
EOF
    
    chmod +x "$FIFO_DIR/controller.sh"
    "$FIFO_DIR/controller.sh"
    
    # Cleanup
    pkill -P $$
    rm -rf "$FIFO_DIR"
}

# Extended menu
echo "Extended HPC Terminal Grid Launcher"
echo "Grid size: ${ROWS}x${COLS} = $TOTAL terminals"
echo ""
echo "Additional options:"
echo "6)  byobu (user-friendly tmux/screen wrapper)"
echo "7)  dvtm (lightweight, no dependencies)"
echo "8)  GNU Parallel (distributed command execution)"
echo "9)  Web terminals (ttyd/gotty - browser-based)"
echo "10) Python-based multiplexer"
echo "11) ClusterSSH/PSSH (manage multiple nodes)"
echo "12) MPI terminal spawning"
echo "13) SLURM job array monitor"
echo "14) Terminator (X11 required)"
echo "15) FIFO-based multiplexer (custom solution)"
echo ""

read -p "Select option (6-15): " choice

case $choice in
    6)  launch_byobu_grid ;;
    7)  launch_dvtm_grid ;;
    8)  launch_parallel_commands ;;
    9)  launch_web_terminals ;;
    10) launch_python_grid ;;
    11) launch_clusterssh ;;
    12) launch_mpi_terminals ;;
    13) launch_job_array_monitor ;;
    14) launch_terminator_grid ;;
    15) launch_fifo_mux ;;
    *)  echo "Invalid choice"; exit 1 ;;
esac