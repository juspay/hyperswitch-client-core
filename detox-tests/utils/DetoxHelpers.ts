const DEFAULT_TIMEOUT = 10000;

export async function waitForVisibility(element: Detox.IndexableNativeElement, timeout = DEFAULT_TIMEOUT) {
    await waitFor(element)
        .toBeVisible()
        .withTimeout(timeout);
}

export async function typeTextInInput(element: Detox.IndexableNativeElement, text: string) {
    device.getPlatform() == "ios" ?
        await element.typeText(text) : await element.replaceText(text);
}

/**
 * Takes a screenshot with a descriptive name
 * @param screenshotName Name of the screenshot (will be prefixed with platform and timestamped)
 * @param subFolder Optional subfolder to store screenshots in (will be created if it doesn't exist)
 */
export async function takeScreenshot(screenshotName: string, subFolder?: string) {
    const platform = device.getPlatform();
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const fileName = `${platform}_${screenshotName}_${timestamp}`;

    // This will save screenshots to artifacts directory when running in CI
    // or to the project root when running locally
    let fullPath = fileName;
    if (subFolder) {
        fullPath = `${subFolder}/${fileName}`;
    }

    try {
        await device.takeScreenshot(fullPath);
        console.log(`📸 Screenshot saved: ${fullPath}`);
    } catch (error) {
        console.error(`❌ Failed to take screenshot ${fullPath}:`, error);
    }
}
