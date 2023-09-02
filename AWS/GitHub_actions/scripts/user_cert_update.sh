#!/bin/bash

# Assign the input and output file names to variables
input="$1"
output="$2"

# Loop through each line in the input file
while read -r user; do
    # Use awk to find and replace the date in the output file
    awk -v user="$user" -v date="$(date +'%Y-%m-%d')" '$1 == user { $2 = date } 1' "$output" > temp 
    # Move the temp file to the output file
    mv temp "$output"
done < "$input"

echo "Task completed."
