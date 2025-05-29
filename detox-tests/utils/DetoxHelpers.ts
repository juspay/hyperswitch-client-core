const DEFAULT_TIMEOUT = 30000;

export async function waitForVisibility(element: Detox.IndexableNativeElement, timeout = DEFAULT_TIMEOUT) {
    await waitFor(element)
        .toBeVisible()
        .withTimeout(timeout);
}

export async function typeTextInInput(element: Detox.IndexableNativeElement, text: string) {
    device.getPlatform() == "ios" ?
        await element.typeText(text) : await element.replaceText(text);
}

export async function waitForElementWithRetry(element: Detox.IndexableNativeElement, timeout = 60000, retries = 3) {
    for (let i = 0; i < retries; i++) {
        try {
            await waitFor(element).toExist().withTimeout(timeout / retries);
            await waitFor(element).toBeVisible().withTimeout(timeout / retries);
            return;
        } catch (error) {
            if (i === retries - 1) throw error;
            // Add delay between retries and disable/enable synchronization
            await device.disableSynchronization();
            await new Promise(resolve => setTimeout(resolve, 2000));
            await device.enableSynchronization();
        }
    }
}

export async function scrollToElementAndWait(element: Detox.IndexableNativeElement, scrollView?: Detox.IndexableNativeElement, timeout = 60000) {
    try {
        await waitFor(element).toBeVisible().withTimeout(5000);
    } catch (error) {
        if (scrollView) {
            await scrollView.scroll(200, 'down');
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        await waitFor(element).toBeVisible().withTimeout(timeout);
    }
}
