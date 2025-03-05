#!/bin/bash

# Closes all of the running programs that are running
cleanup() {
    echo "Cleaning up..."
    kill $BANDWIDTH_PID $BURST_PID $CPU_PID $DISK_PID $MEMORY_PID $LEAK_PID 
    exit 0
}
trap cleanup EXIT

# Compile c programs
compile_programs(){
    echo "Compiling Programs ..."

    gcc bandwidth_hog.c -o bandwidth_hog
    gcc bandwidth_hog_burst.c -o bandwidth_hog_burst
    gcc cpu_hog.c -o cpu_hog
    gcc disk_hog.c -o disk_hog
    gcc memory_hog.c -o memory_hog
    gcc memory_hog_leak.c -o memory_hog_leak
}

# Start all of the files in the background
start_programs(){
    echo "Starting Programs ..."
    echo ""

    ./bandwidth_hog 8.8.8.8  &
    BANDWIDTH_PID=$!
    echo "bandwidth_hog : $BANDWIDTH_PID"

    ./bandwidth_hog_burst 8.8.8.8  &
    BURST_PID=$!
    echo "bandwidth_hog_burst : $BURST_PID"

    ./cpu_hog 8.8.8.8 &
    CPU_PID=$!
    echo "cpu_hop : $CPU_PID"

    ./disk_hog 8.8.8.8 &
    DISK_PID=$!
    echo "disk_hop : $DISK_PID"

    ./memory_hog 8.8.8.8 &
    MEMORY_PID=$!
    echo "memory_hog : $MEMORY_PID"

    ./memory_hog_leak 8.8.8.8 &
    LEAK_PID=$!
    echo "memory_hog_leak : $LEAK_PID"
    echo ""
}

process_level_metrics(){
    echo "Getting the process level metrics ..."

    # When was this function called, used to get the elapsed time.
    start_time=$(date +%s)

    # Header of the file
    echo "Time,APM 1 CPU,APM 1 Memory,APM 2 CPU,APM 2 Memory,APM 3 CPU,APM 3 Memory,APM 4 CPU,APM 4 Memory,APM 5 CPU,APM 5 Memory,APM 6 CPU,APM 6 Memory" > process_metrics.csv
    while true; do
        # Since this while loop runs every 5 seconds, elapsed time be += 5 every time.
        current_time=$(date +%s)
        elapsed_time=$(($current_time - $start_time))

        apm1_cpu=$(ps -p $BANDWIDTH_PID -o %cpu=)
        apm1_mem=$(ps -p $BANDWIDTH_PID -o %mem=)

        apm2_cpu=$(ps -p $BURST_PID -o %cpu=)
        apm2_mem=$(ps -p $BURST_PID -o %mem=)

        apm3_cpu=$(ps -p $CPU_PID -o %cpu=)
        apm3_mem=$(ps -p $CPU_PID -o %mem=)

        apm4_cpu=$(ps -p $DISK_PID -o %cpu=)
        apm4_mem=$(ps -p $DISK_PID -o %mem=)

        apm5_cpu=$(ps -p $MEMORY_PID -o %cpu=)
        apm5_mem=$(ps -p $MEMORY_PID -o %mem=)

        apm6_cpu=$(ps -p $LEAK_PID -o %cpu=)
        apm6_mem=$(ps -p $LEAK_PID -o %mem=)

        # Append to the csv
        echo "$elapsed_time,$apm1_cpu,$apm1_mem,$apm2_cpu,$apm2_mem,$apm3_cpu,$apm3_mem,$apm4_cpu,$apm4_mem,$apm5_cpu,$apm5_mem,$apm6_cpu,$apm6_mem" >> process_metrics.csv
        sleep 5
    done &
}

system_level_metrics(){
    echo "Getting the system level metrics ..."
}

network_bandwidth_utilization(){
    echo "Testing the network bandwidth utilization ..."
}

hard_disk_access_rates(){
    echo "Getting access rates ..."
}

hard_disk_utilization(){
    echo "Testing the hard disk utilization ..."
}

# Compile and start the programs
compile_programs
start_programs

# Get all of the data
process_level_metrics &
system_level_metrics &
network_bandwidth_utilization &
hard_disk_access_rates &
hard_disk_utilization &

sleep 3
echo ""
echo "Monitoring started. Press Ctrl+C to stop."
wait