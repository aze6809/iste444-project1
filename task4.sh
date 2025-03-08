#!/bin/bash

echo "Monitoring started. Press Ctrl+C to stop."
hard_disk_access_rates(){
    iostat /dev/mapper/rl-root | awk 'NR>6{print $6}'
	#df /

}

echo "Finished executing after 30 seconds."