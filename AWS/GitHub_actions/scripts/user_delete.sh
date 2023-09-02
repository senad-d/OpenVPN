#!/bin/bash

input="$1"
output="$2"

# Read user names from the input file into an array
input_users=()
while IFS= read -r line; do
    input_users+=("$line")
done < "$input"

# Create a temporary file for modifying the output file
temp_file=$(mktemp)

# Loop through each line in the output file
while IFS= read -r line; do
    # Check if the line is in the list of users to remove
    if ! [[ "${input_users[*]}" =~ $line ]]; then
        # Append the line to the temporary file
        echo "$line" >> "$temp_file"
    else
        echo "Removed user: $line"
    fi
done < "$output"

# Overwrite the output file with the temporary file
mv "$temp_file" "$output"

echo "Task completed."
