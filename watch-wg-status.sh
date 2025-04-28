#!/bin/bash

REFRESH_INTERVAL="${1:-10}"

refresh_screen() {
    echo -ne "\033[H"
}

clear

while true; do
    refresh_screen

    CURRENT_TIME=$(date +"%Y-%m-%d %H:%M:%S")
    ACTIVE_PEERS=0
    DEAD_PEERS=0

    WG_OUTPUT=$(docker exec wireguard-server wg show)

    echo "WireGuard Monitor  |  Refresh every ${REFRESH_INTERVAL}s  |  Last updated: $CURRENT_TIME"
    echo "-------------------------------------------------------------------------------------------"
    echo

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*interface:\ (.+) ]]; then
            echo -e "\e[1m$line\e[0m"
        elif [[ "$line" =~ ^[[:space:]]*peer:\ ([A-Za-z0-9+/=]+) ]]; then
            echo -e "\e[33m$line\e[0m"
        elif [[ "$line" =~ ^[[:space:]]*latest\ handshake:\ (.+)\ ago ]]; then
            handshake="${BASH_REMATCH[1]}"
            hours=0
            minutes=0
            seconds=0

            # Parse carefully now
            if [[ "$handshake" =~ ([0-9]+)\ hours ]]; then
                hours=${BASH_REMATCH[1]}
            fi
            if [[ "$handshake" =~ ([0-9]+)\ minutes ]]; then
                minutes=${BASH_REMATCH[1]}
            fi
            if [[ "$handshake" =~ ([0-9]+)\ seconds ]]; then
                seconds=${BASH_REMATCH[1]}
            fi

            total_seconds=$((hours * 3600 + minutes * 60 + seconds))

            if (( total_seconds <= 300 )); then
                echo -e "\e[32m$line\e[0m"
                ((ACTIVE_PEERS++))
            else
                echo -e "\e[31m$line\e[0m"
                ((DEAD_PEERS++))
            fi

        elif [[ "$line" =~ ^[[:space:]]*latest\ handshake:\ \(none\) ]]; then
            echo -e "\e[31m$line\e[0m"
            ((DEAD_PEERS++))
        elif [[ "$line" =~ ^[[:space:]]*transfer:\ (.+) ]]; then
            echo -e "\e[36m$line\e[0m"
        elif [[ "$line" =~ ^[[:space:]]*persistent\ keepalive:\ (.+) ]]; then
            echo -e "\e[34m$line\e[0m"
        else
            echo "$line"
        fi
    done <<< "$WG_OUTPUT"

    echo
    echo -e "\e[1mActive peers: \e[32m$ACTIVE_PEERS\e[0m  |  Dead peers: \e[31m$DEAD_PEERS\e[0m"
    echo

    ROWS=$(tput lines)
    for ((i=REFRESH_INTERVAL; i>0; i--)); do
        tput cup $((ROWS-1)) 0
        echo -ne "Next refresh in ${i}s...     "
        sleep 1
    done
done
