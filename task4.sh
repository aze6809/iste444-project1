#!/bin/bash

#!/bin/bash
echo "Monitoring started. Press Ctrl+C to stop."
hard_disk_access_rates(){
    iostat sda | awk '{print $1, $3}'
    iostat mapper/rl-root
    #iostat -d | awk 'NR>3 {sum += $3} END {print sum}'
}

end_time=$((SECONDS + 30))

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

