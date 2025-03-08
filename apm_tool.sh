#!/bin/bash

# Closes all of the running programs that are running.
cleanup() {
    echo ""
    echo "Cleaning up..."
    kill $BANDWIDTH_PID $BURST_PID $CPU_PID $DISK_PID $MEMORY_PID $LEAK_PID
    exit 0
}
trap cleanup EXIT

# Compile c programs.
compile_programs() {
    echo "Compiling Programs ..."

    gcc bandwidth_hog.c -o bandwidth_hog
    gcc bandwidth_hog_burst.c -o bandwidth_hog_burst
    gcc cpu_hog.c -o cpu_hog
    gcc disk_hog.c -o disk_hog
    gcc memory_hog.c -o memory_hog
    gcc memory_hog_leak.c -o memory_hog_leak
}

# Start all of the files in the background.
start_programs() {
    echo "Starting Programs ..."
    echo ""

    ./bandwidth_hog 8.8.8.8 &
    BANDWIDTH_PID=$!
    echo "bandwidth_hog : $BANDWIDTH_PID"

    ./bandwidth_hog_burst 8.8.8.8 &
    BURST_PID=$!
    echo "bandwidth_hog_burst : $BURST_PID"

    ./cpu_hog 8.8.8.8 &
    CPU_PID=$!
    echo "cpu_hog : $CPU_PID"

    ./disk_hog 8.8.8.8 &
    DISK_PID=$!
    echo "disk_hog : $DISK_PID"

    ./memory_hog 8.8.8.8 &
    MEMORY_PID=$!
    echo "memory_hog : $MEMORY_PID"

    ./memory_hog_leak 8.8.8.8 &
    LEAK_PID=$!
    echo "memory_hog_leak : $LEAK_PID"
    echo ""
}

init_process_level_metrics() {
    echo "Initializing process-level metrics ..."
    mkdir -p trial-run
    for proc in bandwidth_hog bandwidth_hog_burst cpu_hog disk_hog memory_hog memory_hog_leak; do
        echo "seconds,CPU,memory" >"trial-run/${proc}_metrics.csv"
    done
}

process_level_metrics() {
    elapsed_time=$1
    declare -A pids=(
        ["bandwidth_hog"]=$BANDWIDTH_PID
        ["bandwidth_hog_burst"]=$BURST_PID
        ["cpu_hog"]=$CPU_PID
        ["disk_hog"]=$DISK_PID
        ["memory_hog"]=$MEMORY_PID
        ["memory_hog_leak"]=$LEAK_PID
    )
    for proc in "${!pids[@]}"; do
        cpu=$(ps -p ${pids[$proc]} -o %cpu=)
        mem=$(ps -p ${pids[$proc]} -o %mem=)
        echo "$elapsed_time,$cpu,$mem" >>"trial-run/${proc}_metrics.csv"
    done
}

init_system_level_metrics() {
    echo "Initializing system-level metrics ..."
    echo "seconds,RX data rate,TX data rate,disk writes,available disk capacity" >trial-run/system_metrics.csv
}

system_level_metrics() {
    elapsed_time=$1

    # Find the network interface
    NETWORK_IFACE=$(ip -o link show | awk -F': ' '/ens[0-9]+/{print $2; exit}')
    if [[ -z "$NETWORK_IFACE" ]]; then
        echo "Error: No ens<ID> interface found. Exiting..."
        exit 1
    fi

    # Collect network bandwidth utilization (kB/s)
    ifstat_output=$(ifstat "$NETWORK_IFACE" 1 1 | awk 'NR==4 {print $6, $8}')
    rx_bytes=$(echo "$ifstat_output" | awk '{print $1}')
    tx_bytes=$(echo "$ifstat_output" | awk '{print $2}')

    # Convert bytes to kilobytes
    rx_rate=$(echo "scale=2; $rx_bytes / 1024" | bc)
    tx_rate=$(echo "scale=2; $tx_bytes / 1024" | bc)

    # Collect disk writes (kB/s)
    disk_writes=$(iostat -d /dev/mapper/rl-root | awk 'NR>3 {print $4}')

    # Collect available disk capacity (MB)
    available_disk=$(df -m / | awk 'NR==2 {print $4}')

    # Write to CSV file
    echo "$elapsed_time,$rx_rate,$tx_rate,$disk_writes,$available_disk" >>trial-run/system_metrics.csv
}

get_metrics_loop() {
    # Run the metrics in a loop
    local minutes=$1
    loopEnd=$(($minutes * 12)) #  (minutes) * 60 / 5 second intervals
    count=0
    init_process_level_metrics
    init_system_level_metrics

    while [ $count -le $loopEnd ]; do
        # calculate seconds to pass on
        passOnSeconds=$((count * 5))
        echo ""
        echo "Time Elapsed: $((count * 5)) seconds"

        # call your functions to do the metrics
        process_level_metrics $passOnSeconds
        system_level_metrics $passOnSeconds

        # seconds is count * 5
        count=$((count + 1))
        sleep 5
    done
}

# Compile and start the programs.
compile_programs
start_programs

echo ""
echo "Monitoring started. Press Ctrl+C to stop."

get_metrics_loop 15
