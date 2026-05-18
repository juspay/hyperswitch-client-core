let defaultProps = {
  type: 'payment',
  hyperswitchConfig: {
    publishableKey: '',
    profileId: '',
    environment: 'sandbox',
  },
  paymentSessionConfig: {
    sdkAuthorization: '',
  },
  configuration: {
    paymentSheetHeaderLabel: 'Select a payment method',
    savedPaymentSheetHeaderLabel: 'Saved payment method',
    allowsDelayedPaymentMethods: false,
    merchantDisplayName: 'Example, Inc.',
    allowsPaymentMethodsRequiringShippingAddress: false,
    displaySavedPaymentMethodsCheckbox: true,
    displaySavedPaymentMethods: true,
    displayDefaultSavedPaymentIcon: true,
    displayPayButton: true,
    disableBranding: true,
    // preloadCardElement: false,
    primaryButtonLabel: 'Pay Now',
    netceteraSDKApiKey: '',
    locale: 'en',
    subscribedEvents: ['onSuccess', 'onFailed', 'onCancelled'],
    paymentMethodLayout: {
      type: 'tabs',
      radios: false,
      maxAccordionItems: 3,
      paymentMethodsArrangementForTabs: "auto",
      spacedAccordionItems: true,
      defaultCollapsed: true,
      savedMethodCustomization: {
        defaultCollapsed: false,
        hideCardExpiry: true,
        hideCVCError: false,
        cvcIcon: 'shown',
        groupingBehavior: {
          displayInSeparateScreen: true,
          groupByPaymentMethods: false,
        },
      },
    },
    appearance: {
      theme: 'Light',
      colors: {
        light: {
          primary: '#006DF9',
          background: '#FFFFFF',
          componentBackground: '#F6F8F9',
          componentBorder: '#E0E0E0',
          componentDivider: '#E0E0E0',
          componentText: '#000000',
          primaryText: '#000000',
          secondaryText: '#767676',
          placeholderText: '#9E9E9E',
          icon: '#000000',
          error: '#FF0000',
          loaderBackground: '#F6F8F9',
          loaderForeground: '#006DF9',
          selectedComponentBackground: '#EBF2FF',
          selectedComponentBorder: '#006DF9',
          selectedComponentBorderWidth: 2.0,
          selectedComponentDivider: '#E0E0E0',
          selectedComponentText: '#000000',
        },
        dark: {
          primary: '#006DF9',
          background: '#FFFFFF',
          componentBackground: '#F6F8F9',
          componentBorder: '#E0E0E0',
          componentDivider: '#E0E0E0',
          componentText: '#000000',
          primaryText: '#000000',
          secondaryText: '#767676',
          placeholderText: '#9E9E9E',
          icon: '#000000',
          error: '#FF0000',
          loaderBackground: '#F6F8F9',
          loaderForeground: '#006DF9',
          selectedComponentBackground: '#1a3a5c',
          selectedComponentBorder: '#0057c7',
          selectedComponentBorderWidth: 2.0,
          selectedComponentDivider: '#e6e6e6',
          selectedComponentText: '#ffffff',
        },
      },
      shapes: {
        borderRadius: 8.0,
        borderWidth: 1.0,
        shadow: {
          color: '#000000',
          opacity: 0.2,
          blurRadius: 4.0,
          intensity: 4.0,
          offset: { x: 2.0, y: 2.0 },
        },
      },
      font: {
        family: 'Roboto',
        scale: 1.0,
      },
      primaryButton: {
        shapes: {
          borderRadius: 8.0,
          borderWidth: 2.5,
          shadow: {
            color: '#000000',
            opacity: 1.0,
            blurRadius: 0.0,
            intensity: 4.0,
            offset: { x: 4.0, y: 4.0 },
          },
        },
        colors: {
          light: {
            background: '#FFE500',
            text: '#000000',
            border: '#000000',
          },
          dark: {
            background: '#FFE500',
            text: '#000000',
            border: '#000000',
          },
        },
      },
      logo: {
        borderRadius: 50,
        colors: {
          light: {
            backgroundColor: 'black',
            unselected: 'white',
          },
          dark: {
            backgroundColor: 'white',
            unselected: 'black',
          },
        },
        checkedIconForSelection: {
          colors: {
            light: {
              color: '#15b600',
            },
            dark: {
              color: '#15b600',
            },
          },
        },
      },
    },
    walletButtonsConfiguration: {
      googlePay: {
        buttonType: 'buy',
        buttonStyle: { light: 'dark', dark: 'light' },
      },
      applePay: {
        buttonType: 'donate',
        buttonStyle: { light: 'black', dark: 'white' },
      },
    },
    placeholder: {
      cardNumber: '4242 4242 4242 4242',
      expiryDate: 'MM / YY',
      cvv: 'CVC',
    },
    redirectionInfo: 'hidden',
    stickyPayButton: true,
    // alwaysSendCustomerAcceptance: false,
    paymentMethodsConfig: [{ paymentMethod: 'card', message: '' }, { paymentMethod: 'wallet', message: '' }],
    // opensCardScannerAutomatically: false,
    paymentMethodOrder: ["apple_pay", "google_pay", "paypal", "samsung_pay", "credit", "klarna",],
    billingDetails: {
      email: 'john@example.com',
      phone: { code: '+91', number: '9999999999' },
      address: {
        first_name: 'John',
        last_name: 'Doe',
        city: 'San Francisco',
        country: 'US',
        line1: '123 Main St',
        line2: 'Apt 4B',
        postalCode: '94102',
        state: 'CA',
      },
    },
    shippingDetails: {
      phone: { code: '+91', number: '9999999999' },
      address: {
        first_name: 'John',
        last_name: 'Doe',
        city: 'San Francisco',
        country: 'US',
        line1: '123 Main St',
        line2: 'Apt 4B',
        postalCode: '94102',
        state: 'CA',
      },
    },
    customer: {
      id: 'cus_xxxxxxxxxxxx',
      ephemeralKeySecret: 'ephem_xxxxxxxxxxxx',
    },
  },
  sdkParams: {
    sessionId: '',
    sdkVersion: '1.0.0',
    confirm: false,
    'user-agent': navigator.userAgent,
    launchTime: Date.now(),
    appId: 'com.example.myapp',
    country: 'US',
    device_model: 'iPhone',
    os_type: 'iOS',
    os_version: '18.5',
    deviceBrand: 'Apple',
  },
};

const TRUSTED_ORIGINS = [
  'http://127.0.0.1:8082',
  'http://localhost:8083',
  'https://your-production-url.com',
]; // Add trusted origins

const initReactNativeWeb = async () => {
  const createProps = async () => {
    try {
      let response = await fetch('http://localhost:5252/create-payment-intent');
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      const data = await response.json();
      defaultProps.hyperswitchConfig.publishableKey = data.publishableKey;
      defaultProps.hyperswitchConfig.profileId = data.profileId ?? '';
      defaultProps.paymentSessionConfig.sdkAuthorization =
        data.sdkAuthorization ?? '';

      const iframe = document.querySelector('iframe');
      if (iframe && iframe.contentWindow) {
        iframe.contentWindow.postMessage(
          JSON.stringify({ initialProps: { props: defaultProps } }),
          TRUSTED_ORIGINS[0],
        );
      } else {
        console.error('Iframe not found or inaccessible.');
      }
    } catch (error) {
      console.error('Error fetching payment intent:', error);
    }
  };

  const handleMessage = event => {
    if (!TRUSTED_ORIGINS.includes(event.origin)) {
      console.warn(`Blocked message from untrusted origin: ${event.origin}`);
      return;
    } else if (
      event.data.type === 'webpackOk' ||
      event.data.source === 'react-devtools-content-script'
    ) {
      return;
    }

    try {
      let data = JSON.parse(event.data);

      if (data.sdkLoaded) {
        createProps();
      }
      if (data.status) {
        const iframe = document.querySelector('iframe');
        if (iframe) iframe.style.display = 'none';

        const statusElement = document.getElementById('status');
        if (statusElement) {
          statusElement.textContent = `Status: ${data.status} ${data.message ? 'Message: ' + data.message : ''
            }`.toUpperCase();
        } else {
          console.error('Status element not found.');
        }
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  };

  window.addEventListener('message', handleMessage);
};

initReactNativeWeb();
