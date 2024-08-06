#Analyzing Chase Bank login records

#!/bin/bash

#Declare 'logfile' variable to be read
logfile="/var/log/auth_log.log"

#Declare 'results' file variable to copy suspicious lines into
results="/home/ubuntu/suspicious_activity.log"

#Define array of suspicious keywords
suspiciousWords=("Failed" "Unauthorized" "error")

#Declare associative array to keep track of existing lines in 'results'
declare -A existing_suslogs


                        #-- Tracking lines in 'results' to prevent duplicate entries --#

if [ -f "$results" ]
then
        #While reading through 'results'...
        while IFS= read -r line
        do
                #put all lines found in 'results' file into 'existing_suslogs' array.
                existing_suslogs["$line"]=1

        done < "$results"
fi


                                #-- Processing lines of 'logfile' --#

#Setting a counter for echo output
counter=0

#While reading through lines of 'logfile'...
while IFS= read -r line
do
        #for each 'susword' in the 'suspiciousWords' array...
        for susword in "${suspiciousWords[@]}"
        do
                #if the line includes any 'susword'...
                if [[ "$line" == *"$susword"* ]]
                then
                        #check if the line doesn't already exist in the 'existing_suslogs' array...
                        if [ -z "${existing_suslogs["$line"]}" ]

                        then
                        #copy it to the 'results' file...
                        echo "$line" >> "$results"

                        #add it to the 'existing_suslogs' array...
                        existing_suslogs["$line"]=1

                        #and count how many new lines were entered.
                        ((counter++))

                        fi
                fi
        done

done < "$logfile"

echo "suspicious_activity.log has been updated with "$counter" new entries."
