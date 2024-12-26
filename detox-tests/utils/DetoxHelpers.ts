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
