// This file is used to set up debugging for Detox tests
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Create artifacts directory if it doesn't exist
const artifactsDir = path.join(process.cwd(), 'artifacts');
if (!fs.existsSync(artifactsDir)) {
    fs.mkdirSync(artifactsDir, { recursive: true });
}

// Function to run a command and capture output
function runCommand(cmd) {
    try {
        return execSync(cmd, { encoding: 'utf8' });
    } catch (error) {
        return `Command failed: ${cmd}\nError: ${error.message}`;
    }
}

// Capture environment information
const envInfo = {
    date: new Date().toISOString(),
    nodeVersion: process.version,
    platform: process.platform,
    arch: process.arch,
    env: Object.keys(process.env).filter(key =>
        key.startsWith('DETOX') ||
        key.startsWith('ANDROID') ||
        key.startsWith('JAVA') ||
        key === 'PATH'
    ).reduce((obj, key) => {
        obj[key] = process.env[key];
        return obj;
    }, {}),
};

// Capture device information if running on Android
if (process.env.ANDROID_HOME) {
    try {
        envInfo.adbDevices = runCommand('adb devices');
        envInfo.androidEmulators = runCommand('emulator -list-avds');
    } catch (error) {
        envInfo.adbError = error.message;
    }
}

// Save environment info to file
fs.writeFileSync(
    path.join(artifactsDir, 'environment-info.json'),
    JSON.stringify(envInfo, null, 2)
);
