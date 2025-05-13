// Setup file for Jest
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { device } = require('detox');

// Run our debug setup script
require('../debug-setup');

module.exports = async () => {
    // Ensure artifacts directory exists
    const artifactsDir = path.join(process.cwd(), 'artifacts');
    if (!fs.existsSync(artifactsDir)) {
        fs.mkdirSync(artifactsDir, { recursive: true });
    }

    // Capture ADB devices list and save to file
    try {
        const adbDevices = execSync('adb devices', { encoding: 'utf8' });
        fs.writeFileSync(path.join(artifactsDir, 'adb-devices.txt'), adbDevices);
        console.log('📱 ADB devices list captured');
    } catch (error) {
        console.error('⚠️ Failed to capture ADB devices list', error);
    }

    // Try to take an initial screenshot of the device
    try {
        await device.takeScreenshot('initial_device_state');
        console.log('📸 Initial device screenshot taken');
    } catch (error) {
        console.error('⚠️ Failed to take initial device screenshot', error);
    }

    console.log('✅ Jest setup complete');
}; 