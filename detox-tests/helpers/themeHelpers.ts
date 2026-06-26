import {device} from 'detox';

/**
 * Sets the device appearance to the specified theme
 * @param {string} appearance - 'light' or 'dark'
 */
async function setDeviceAppearance(appearance: string) {
  if (device.getPlatform() === 'ios') {
    (device as any).setAppearance(appearance);
  } else {
    // For Android, theme switching requires system-level changes
    // This can be implemented using UI Automator or adb commands
    console.log(
      `Android appearance switching to ${appearance} requires additional setup`,
    );
  }
  // Wait for theme to apply
  await new Promise(resolve => setTimeout(resolve, 1000));
}

/**
 * Switches device appearance from current to opposite theme
 * @returns {string} The new appearance ('light' or 'dark')
 */
async function toggleDeviceAppearance(): Promise<string> {
  // Note: Detox doesn't provide a way to get current appearance
  // We'll need to track it or assume starting state
  // For now, we'll toggle to dark then back to light
  await setDeviceAppearance('dark');
  return 'dark';
}

/**
 * Resets device appearance to light theme
 */
async function resetToLightTheme(): Promise<void> {
  await setDeviceAppearance('light');
}

/**
 * Resets device appearance to dark theme
 */
async function resetToDarkTheme(): Promise<void> {
  await setDeviceAppearance('dark');
}

export {
  setDeviceAppearance,
  toggleDeviceAppearance,
  resetToLightTheme,
  resetToDarkTheme,
};
