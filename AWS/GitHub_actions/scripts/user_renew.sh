#!/bin/bash

# Threshold for the number of days
threshold=356

input="$1"
output="$2"

# Current date
date=$(date '+%Y-%m-%d')

user_found=false

# Loop through each line in the input file
while read -r line; do
    # Extract the username and date from the line
    username=$(echo "$line" | awk '{print $1}')
    cert_date=$(echo "$line" | awk '{print $2}')

    # Calculate the number of days passed
    date_sec=$(date -d "$date" +%s)
    cert_date_sec=$(date -d "$cert_date" +%s)
    days_passed=$(( ( $date_sec - $cert_date_sec ) / 86400 ))

    # Check if the days_passed is greater than the threshold
    if [ "$days_passed" -gt "$threshold" ]; then
        echo "$username" >> "$output"
        # Flag variable to check if any users meet the threshold
        user_found=true
    fi
done < "$input"

# Check if any users meet the threshold
if [ "$user_found" = true ]; then
    echo "Task completed."
    echo "The following users meet the threshold:"
    cat "$output"
else
    echo "No users found with a certificate that is going to expire."
fi
