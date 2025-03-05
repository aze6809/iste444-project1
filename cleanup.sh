#!/bin/bash

# This will clean up the output files if you don't want them.
# The git ignore will make sure they don't get pushed.

echo "Cleaning up compiled binaries..."

rm -f bandwidth_hog bandwidth_hog_burst cpu_hog disk_hog memory_hog memory_hog_leak

echo "Cleanup complete!"
ls  -al