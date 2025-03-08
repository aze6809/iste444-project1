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

init_process_level_metrics(){
    echo "Collecting process-level metrics ..."

    mkdir -p trial-run

    echo "seconds,CPU,memory" >trial-run/bandwidth_hog_metrics.csv
    echo "seconds,CPU,memory" >trial-run/bandwidth_hog_burst_metrics.csv
    echo "seconds,CPU,memory" >trial-run/cpu_hog_metrics.csv
    echo "seconds,CPU,memory" >trial-run/disk_hog_metrics.csv
    echo "seconds,CPU,memory" >trial-run/memory_hog_metrics.csv
}

process_level_metrics(){
    elapsed_time=$1
 
    # Get the cpu and mem used for each process with the process id and append to the csv.
    apm1_cpu=$(ps -p $BANDWIDTH_PID -o %cpu=)
    apm1_mem=$(ps -p $BANDWIDTH_PID -o %mem=)
    echo "$elapsed_time,$apm1_cpu,$apm1_mem" >> trial-run/bandwidth_hog_metrics.csv

    apm2_cpu=$(ps -p $BURST_PID -o %cpu=)
    apm2_mem=$(ps -p $BURST_PID -o %mem=)
    echo "$elapsed_time,$apm2_cpu,$apm2_mem" >> trial-run/bandwidth_hog_burst_metrics.csv

    apm3_cpu=$(ps -p $CPU_PID -o %cpu=)
    apm3_mem=$(ps -p $CPU_PID -o %mem=)
    echo "$elapsed_time,$apm3_cpu,$apm3_mem" >> trial-run/cpu_hog_metrics.csv

    apm4_cpu=$(ps -p $DISK_PID -o %cpu=)
    apm4_mem=$(ps -p $DISK_PID -o %mem=)
    echo "$elapsed_time,$apm4_cpu,$apm4_mem" >> trial-run/disk_hog_metrics.csv

    apm5_cpu=$(ps -p $MEMORY_PID -o %cpu=)
    apm5_mem=$(ps -p $MEMORY_PID -o %mem=)
    echo "$elapsed_time,$apm5_cpu,$apm5_mem" >> trial-run/memory_hog_metrics.csv

    apm6_cpu=$(ps -p $LEAK_PID -o %cpu=)
    apm6_mem=$(ps -p $LEAK_PID -o %mem=)
    echo "$elapsed_time,$apm6_cpu,$apm6_mem" >> trial-run/memory_hog_leak_metrics.csv
}

init_system_level_metrics(){
    echo "Collecting system-level metrics ..."

    mkdir -p trial-run

    # Initialize CSV file
    echo "seconds,RX data rate,TX data rate,disk writes,available disk capacity" >trial-run/system_metrics.csv

    # Get initial network statistics
    prev_rx=$(awk '/eth0|wlan0/ {print $2}' /proc/net/dev | paste -sd+ - | bc)
    prev_tx=$(awk '/eth0|wlan0/ {print $10}' /proc/net/dev | paste -sd+ - | bc)
}

system_level_metrics() {
    elapsed_time=$1

    # Get current network stats
    curr_rx=$(awk '/eth0|wlan0/ {print $2}' /proc/net/dev | paste -sd+ - | bc)
    curr_tx=$(awk '/eth0|wlan0/ {print $10}' /proc/net/dev | paste -sd+ - | bc)

    # Calculate RX and TX rates (bytes per second)
    rx_rate=$(((curr_rx - prev_rx) / 5))
    tx_rate=$(((curr_tx - prev_tx) / 5))

    # Update previous values
    prev_rx=$curr_rx
    prev_tx=$curr_tx

    # Get disk writes
    disk_writes=$(iostat -d | awk 'NR>3 {sum += $3} END {print sum}')

    # Get available disk capacity
    available_disk=$(df -h / | awk 'NR==2 {print $4}')

    # Write to CSV file
    echo "$elapsed_time,$rx_rate,$tx_rate,$disk_writes,$available_disk" >>trial-run/system_metrics.csv
}

network_bandwidth_utilization() {
    echo "Collecting network bandwidth utilization using ifstat ..."

    # Find the correct `ens<ID>` interface
    NETWORK_IFACE=$(ip -o link show | awk -F': ' '/ens[0-9]+/{print $2; exit}')

    if [[ -z "$NETWORK_IFACE" ]]; then
        echo "Error: No ens<ID> interface found. Exiting..."
        exit 1
    fi

    echo "Using network interface: $NETWORK_IFACE"

    # Display the computer's IP address and the gateway IP
    COMPUTER_IP=$(ip -o -4 addr show "$NETWORK_IFACE" | awk '{print $4}' | cut -d'/' -f1)
    GATEWAY_IP=$(ip route | awk '/default/ {print $3}')

    echo "Computer IP: $COMPUTER_IP"
    echo "Gateway IP: $GATEWAY_IP"

    # Start ifstat for real-time monitoring on the chosen interface
    ifstat "$NETWORK_IFACE"
}

hard_disk_access_rates() {
    echo "Getting access rates ..."
    #Gets JUST the kB_wrtn/s value for the main device
    kb_written=$(iostat /dev/mapper/rl-root | awk 'NR>6{print $6}')
    echo "kB written to hard disk per second $kb_written"
}

hard_disk_utilization() {
    echo "Testing the hard disk utilization ..."
    #Gets JUST the amount of space left available on the disk
    disk_use=$(df / | awk 'NR>1{print $4}')
    echo "Hard disk utilization: $disk_use"
}

get_metrics_loop() {
    # Run the metrics in a loop
    local minutes=$1
    loopEnd=$(( $minutes * 12 )) #  (minutes) * 60 / 5 second intervals 
    count=0
    init_process_level_metrics
    init_system_level_metrics

    while [ $count -le $loopEnd ] 
    do
        # calculate seconds to pass on 
        passOnSeconds=$((count * 5))
        echo ""
        echo "Time Elapsed: $((count * 5)) seconds"

        # call your functions to do the metrics
        process_level_metrics $(($count * 5)) 
        system_level_metrics $(($count * 5)) 
        network_bandwidth_utilization 
        hard_disk_access_rates 
        hard_disk_utilization 
      
        # seconds is count * 5
        count=$(( count + 1 ))
        sleep 5
    done
}

# Compile and start the programs.
compile_programs
start_programs

echo ""
echo "Monitoring started. Press Ctrl+C to stop."

get_metrics_loop 15