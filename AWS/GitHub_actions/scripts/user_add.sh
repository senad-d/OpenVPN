#!/bin/bash

# Assign input and output file names to variables.
input="$1"
output="$2"

# Loop through each line in the input file
while IFS= read -r user; do
  # Check if the user already exists in the output file
  if ! grep -q "^$user$" "$output"; then
    # If not, append the user to the output file
    echo "$user" >> "$output"
    echo "Added user: $user"
  fi
done < "$input"

echo "Task completed."
