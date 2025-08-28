#!/bin/bash
user=$(id -u -n)
if [[ "$user" != "fuzz" ]]; then
    if [ $# -eq 0 ]; then
        echo "Please specify the container name to stop or run the command from the container"
        exit 1
    fi
    echo "test"
    docker exec $1 /usr/local/bin/stop-fuzz
    exit 0
else
    windows=$(tmux list-windows -t fuzz | wc -l)
    for win in $(seq 1 $windows); do
        panes=$(tmux list-panes -t fuzz:$win | wc -l)
        for pane in $(seq 1 $panes); do
            tmux send-keys -t fuzz:$win.$pane C-c
        done
    done

    sleep 3
fi
