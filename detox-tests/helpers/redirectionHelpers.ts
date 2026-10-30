import { device } from 'detox';

export const handleExternalAppSwitch = async (flowType: string) => {
    console.log(`waiting external app switch for ${flowType}`);
    // delay for app transition
    await new Promise(r => setTimeout(r, 2000));
}

export const simulateDeepLinkReturn = async (url: string) => {
    console.log('simulating deep link -> ', url);
    
    await device.openURL({ url });
    
    // wait for app to foreground
    await new Promise(r => setTimeout(r, 3000));
}
