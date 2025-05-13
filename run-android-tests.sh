#!/bin/bash

# Script to run Android Detox tests with proper environment setup

set -e  # Exit immediately if a command exits with a non-zero status

# Make the script executable
chmod +x ./setup-android-sdk.sh

# Source the Android SDK setup script
echo "Setting up Android SDK environment..."
source ./setup-android-sdk.sh

# Check if an emulator is running
if ! adb devices | grep -q "emulator"; then
  echo "No Android emulator seems to be running."
  echo "Please start an emulator before running this script."
  echo "You can use: emulator -avd Pixel_4_API_34 &"
  exit 1
fi

# Create artifacts directory
mkdir -p ./artifacts

# Run the tests
echo "Running Detox tests..."
npx detox test --configuration android.emu.debug --loglevel trace --record-logs all

# Print location of screenshots and artifacts
echo ""
echo "Test run complete."
echo "Screenshots and test artifacts can be found in:"
echo "$(pwd)/artifacts" 