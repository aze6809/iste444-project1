#!/bin/bash

echo "Monitoring started. Press Ctrl+C to stop."
hard_disk_access_rates(){
    iostat /dev/mapper/rl-root | awk '{print $1, $3}'
	#df /

}

end_time=$((SECONDS + 30))

gcc disk_hog.c -o disk_hog

./disk_hog 8.8.8.8 & DISK_PID=$!

while [ $SECONDS -lt $end_time ]; do
    hard_disk_access_rates
    sleep 5
done

echo "Finished executing after 30 seconds."

# Run the metrics in a loop
    # loopEnd=$(( runtime * 12 )) # runtime (minutes) * 60 / 5 second intervals 
    # count=0
    # while [ $count -le $loopEnd ] 
    # do
    #     # calculate seconds to pass on 
    #     passOnSeconds=$((count * 5))
    
    #     # call your functions to do the metrics
    #     hard_disk_access_rates
    #     # seconds is count * 5
    #     count=$(( count + 1 ))
    #     sleep 5
    # done


# Run the metrics in a loop
    # loopEnd=$(( runtime * 12 )) # runtime (minutes) * 60 / 5 second intervals 
    # count=0
    # while [ $count -le $loopEnd ] 
    # do
    #     # calculate seconds to pass on 
    #     passOnSeconds=$((count * 5))
    
    #     # call your functions to do the metrics
    #     hard_disk_access_rates
    #     # seconds is count * 5
    #     count=$(( count + 1 ))
    #     sleep 5
    # done