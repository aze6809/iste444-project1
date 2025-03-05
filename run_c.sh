#!/bin/bash

# Closes all of the running programs that are running
cleanup() {
    echo "Cleaning up..."
    kill $BANDWIDTH_PID $BURST_PID $CPU_PID $DISK_PID $MEMORY_PID $LEAK_PID 2>/dev/null
    exit 0
}
trap cleanup EXIT

# Compile c programs
gcc bandwidth_hog.c -o bandwidth_hog
gcc bandwidth_hog_burst.c -o bandwidth_hog_burst
gcc cpu_hog.c -o cpu_hog
gcc disk_hog.c -o disk_hog
gcc memory_hog.c -o memory_hog
gcc memory_hog_leak.c -o memory_hog_leak

# Start all of the files in the background
./bandwidth_hog 127.0.0.1  &
BANDWIDTH_PID=$!

./bandwidth_hog_burst 127.0.0.1  &
BURST_PID=$!

./cpu_hog 127.0.0.1 &
CPU_PID=$!

./disk_hog 127.0.0.1 &
DISK_PID=$!

./memory_hog 127.0.0.1 &
MEMORY_PID=$!

./memory_hog_leak 127.0.0.1 &
LEAK_PID=$!