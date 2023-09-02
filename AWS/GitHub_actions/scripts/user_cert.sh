#!/bin/bash

input="$1"
output="$2"

# Create a temporary file to store the updated output
temp_output=$(mktemp)

# Loop through each user in the input file
while IFS= read -r user; do
  # Check if the user exists in the output file
  if grep -q "^$user " "$output"; then
    # User exists, so copy the line as is
    grep "^$user " "$output" >> "$temp_output"
  else
    # User doesn't exist, so add the user and current date
    echo "$user $(date '+%Y-%m-%d')" >> "$temp_output"
    echo "Added date to user: $user"
  fi
done < "$input"

# Replace the original output file with the temporary file
mv "$temp_output" "$output"

# Remove users from the output file if they don't exist in the input file
grep -Ff "$input" "$output" > "$temp_output"
mv "$temp_output" "$output"

echo "Task completed."
