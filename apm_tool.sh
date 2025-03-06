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
compile_programs(){
    echo "Compiling Programs ..."

    gcc bandwidth_hog.c -o bandwidth_hog
    gcc bandwidth_hog_burst.c -o bandwidth_hog_burst
    gcc cpu_hog.c -o cpu_hog
    gcc disk_hog.c -o disk_hog
    gcc memory_hog.c -o memory_hog
    gcc memory_hog_leak.c -o memory_hog_leak
}

# Start all of the files in the background.
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

process_level_metrics(){
    echo "Getting the process level metrics ..."

    # Get the cpu and mem used for each process with the process id and append to the csv.
    apm1_cpu=$(ps -p $BANDWIDTH_PID -o %cpu=)
    apm1_mem=$(ps -p $BANDWIDTH_PID -o %mem=)
    echo "$elapsed_time,$apm1_cpu,$apm1_mem" >> bandwidth_hog_metrics.csv

    apm2_cpu=$(ps -p $BURST_PID -o %cpu=)
    apm2_mem=$(ps -p $BURST_PID -o %mem=)
    echo "$elapsed_time,$apm2_cpu,$apm2_mem" >> bandwidth_hog_burst_metrics.csv

    apm3_cpu=$(ps -p $CPU_PID -o %cpu=)
    apm3_mem=$(ps -p $CPU_PID -o %mem=)
    echo "$elapsed_time,$apm3_cpu,$apm3_mem" >> cpu_hog_metrics.csv

    apm4_cpu=$(ps -p $DISK_PID -o %cpu=)
    apm4_mem=$(ps -p $DISK_PID -o %mem=)
    echo "$elapsed_time,$apm4_cpu,$apm4_mem" >> disk_hog_metrics.csv

    apm5_cpu=$(ps -p $MEMORY_PID -o %cpu=)
    apm5_mem=$(ps -p $MEMORY_PID -o %mem=)
    echo "$elapsed_time,$apm5_cpu,$apm5_mem" >> memory_hog_metrics.csv

    apm6_cpu=$(ps -p $LEAK_PID -o %cpu=)
    apm6_mem=$(ps -p $LEAK_PID -o %mem=)
    echo "$elapsed_time,$apm6_cpu,$apm6_mem" >> memory_hog_leak_metrics.csv
}

system_level_metrics() {

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

get_metrics_loop() {
    # Run the metrics in a loop
    local minutes=$1
    loopEnd=$(( $minutes * 12 )) #  (minutes) * 60 / 5 second intervals 
    count=0
    while [ $count -le $loopEnd ] 
    do
        # calculate seconds to pass on 
        passOnSeconds=$((count * 5))
    
        # call your functions to do the metrics
        process_level_metrics
        # system_level_metrics
      
        # seconds is count * 5
        count=$(( count + 1 ))
        sleep 5
    done
}

# Compile and start the programs.
compile_programs
start_programs

# Get all of the data.
# process_level_metrics &
# system_level_metrics &
get_metrics_loop 2 &
network_bandwidth_utilization &
hard_disk_access_rates &
hard_disk_utilization &

sleep 1
echo ""
echo "Monitoring started. Press Ctrl+C to stop."
wait