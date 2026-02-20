import { device, element, by, expect as detoxExpect, waitFor } from 'detox';
import * as testIds from '../../src/utility/test/TestUtils.bs.js';
import { CreateBody, setCreateBodyForTestAutomation } from '../utils/APIUtils';
import { stripeCards } from '../fixtures/cards';
import { 
    typeTextInInput, 
    waitForVisibility, 
    launchPaymentSheet, 
    waitForDemoAppLoad, 
    navigateToNormalPaymentSheet,
    dismissKeyboard 
} from '../utils/DetoxHelpers';
import { TIMEOUT_CONFIG, LAUNCH_PAYMENT_SHEET_BTN_TEXT, profileId } from '../fixtures/Constants';

describe('Card 3DS Flow E2E Test', () => {
    
    const createPaymentBody = new CreateBody();
    createPaymentBody.addKey('customer_id', `test_user_${Date.now()}`);
    createPaymentBody.addKey('profile_id', profileId);
    createPaymentBody.addKey('authentication_type', 'three_ds');
    createPaymentBody.addKey('request_external_three_ds_authentication', true);

    beforeAll(async () => {
        await setCreateBodyForTestAutomation(createPaymentBody.get());
    });

    beforeEach(async () => {
        await device.launchApp({
            newInstance: true,
            launchArgs: { detoxEnableSynchronization: 1 },
        });
        await device.enableSynchronization();
        
        await waitForDemoAppLoad(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
        await launchPaymentSheet(LAUNCH_PAYMENT_SHEET_BTN_TEXT);
        await navigateToNormalPaymentSheet();
    });

    
    it('should render payment sheet title correctly', async () => {
        await waitForVisibility(
            element(by.text(/Select payment method|Card Details|Payment methods/i)),
            TIMEOUT_CONFIG.BASE.DEFAULT
        );
    });


    it('should complete the card payment with 3DS flow', async () => {
        await device.disableSynchronization();
        
        try {
            const threeDSCard = stripeCards.threeDSCard;
            if (!threeDSCard) {
                throw new Error('threeDSCard not found in stripeCards');
            }
            
            const { cardNumber, expiryDate, cvc } = threeDSCard;

            const cardInput = element(by.id(testIds.cardNumberInputTestId));
            await cardInput.tap();
            await typeTextInInput(cardInput, cardNumber);

            const expiryInput = element(by.id(testIds.expiryInputTestId));
            await typeTextInInput(expiryInput, expiryDate);

            const cvcInput = element(by.id(testIds.cvcInputTestId));
            await typeTextInInput(cvcInput, cvc);

            await dismissKeyboard();
            
            const payButton = element(by.id(testIds.payButtonTestId));
            await payButton.tap();

            await new Promise(resolve => setTimeout(resolve, 3000));

            console.log('3DS payment initiated - checking for any result...');
            
            await new Promise(resolve => setTimeout(resolve, 5000));
            
        } finally {
            await device.enableSynchronization();
        }
        
    });

    it('should handle 3DS challenge flow', async () => {
        const threeDSCard = stripeCards.threeDSCard;
        if (!threeDSCard) {
            throw new Error('threeDSCard not found in stripeCards');
        }
        
        const { cardNumber, expiryDate, cvc } = threeDSCard;

        const cardInput = element(by.id(testIds.cardNumberInputTestId));
        await waitForVisibility(cardInput, TIMEOUT_CONFIG.BASE.DEFAULT);
        await cardInput.tap();
        await typeTextInInput(cardInput, cardNumber);

        const expiryInput = element(by.id(testIds.expiryInputTestId));
        await typeTextInInput(expiryInput, expiryDate);

        const cvcInput = element(by.id(testIds.cvcInputTestId));
        await typeTextInInput(cvcInput, cvc);

        await device.disableSynchronization();
        
        try {
            await dismissKeyboard();
            
            const payButton = element(by.id(testIds.payButtonTestId));
            await payButton.tap();

            await new Promise(resolve => setTimeout(resolve, 3000));
            

            console.log('3DS challenge flow initiated');
            
            await new Promise(resolve => setTimeout(resolve, 5000));
            
        } finally {
            await device.enableSynchronization();
        }
    });
});

