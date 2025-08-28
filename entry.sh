#!/bin/bash

if [ -z "$FUZZ_CMD" ]; then
    echo "Please specify \$FUZZ_CMD"
    exit 1
fi

fuzz_input="/home/fuzz/samples"
# Check if resume file exists and if the user requested not to resume
if [[ -f /home/fuzz/output/fuzz1/fastresume.bin && $FUZZ_RESUME -eq 0 ]]; then
    fuzz_input="-"
fi

tmux new-session -s fuzz -d

# Determine number of windows
windows=$((FUZZ_CORES/4))
# Check if there is a partially filled window
if [[ $((FUZZ_CORES % 4)) -ne 0 && $FUZZ_CORES -gt 4 ]]; then
    ((windows++))
fi

# Create Windows
i=2
while [ $i -le $windows ]; do
    tmux new-window -t fuzz
    ((i++))
done

# Rename windows
i=1
while [ $i -le $windows ]; do
    # Check if we are on the last window and if it is not fully populated
    if [[ $i -eq $windows && $((FUZZ_CORES % 4)) -ne 0 ]]; then
        name="fuzz $((((i-1)*4)+1))-$((((i-1)*4)+(FUZZ_CORES % 4)))"
    else
        name="fuzz $((((i-1)*4)+1))-$((i*4))"
    fi

    tmux rename-window -t fuzz:$i "$name"
    ((i++))
done

# Create Panes
win=1
pane=1
echo "Creating panes"
while [ $pane -le $FUZZ_CORES ]; do
    case $(($pane % 4)) in
        2)
            tmux split-pane -v -t fuzz:$win.1
            ;;
        3)
            tmux split-pane -h -t fuzz:$win.1
            ;;
        0)
            tmux split-pane -h -t fuzz:$win.3
            ((win++))
            ;;
    esac

    ((pane++))
done

# Start Fuzz Tasks
win=1
pane=1
while [ $pane -le $FUZZ_CORES ]; do
    if [ $pane -eq 1 ]; then
        tmux send-keys -t fuzz:$win.1 "afl-fuzz -i $fuzz_input -o /home/fuzz/output -M fuzz$pane -s $FUZZ_SEED $FUZZ_ARGS -- $FUZZ_CMD" C-m
        ((pane++))
        continue
    fi

    case $(($pane % 4)) in
        1)
            tmux send-keys -t fuzz:$win.1 "afl-fuzz -i $fuzz_input -o /home/fuzz/output -S fuzz$pane -s $FUZZ_SEED $FUZZ_ARGS -- $FUZZ_CMD" C-m
            ;;
        2)
            tmux send-keys -t fuzz:$win.2 "afl-fuzz -i $fuzz_input -o /home/fuzz/output -S fuzz$pane -s $FUZZ_SEED $FUZZ_ARGS -- $FUZZ_CMD" C-m
            ;;
        3)
            tmux send-keys -t fuzz:$win.3 "afl-fuzz -i $fuzz_input -o /home/fuzz/output -S fuzz$pane -s $FUZZ_SEED $FUZZ_ARGS -- $FUZZ_CMD" C-m
            ;;
        0)
            tmux send-keys -t fuzz:$win.4 "afl-fuzz -i $fuzz_input -o /home/fuzz/output -S fuzz$pane -s $FUZZ_SEED $FUZZ_ARGS -- $FUZZ_CMD" C-m
            ((win++))
            ;;
    esac

    ((pane++))
done

tmux attach -t fuzz
