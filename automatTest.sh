#!/bin/bash

# Number of times to execute the command
NUM_RUNS=50

# Command to execute
COMMAND="npx detox test --configuration android.emu.debug"

# Loop to execute the command specified number of times
for ((i=1; i<=NUM_RUNS; i++))
do
  echo "Executing run $i/$NUM_RUNS"
  $COMMAND

  # Check if the command failed
  if [ $? -ne 0 ]; then
    echo "Run $i failed. Exiting loop."
    exit 1
  fi

done

echo "All $NUM_RUNS runs completed successfully."