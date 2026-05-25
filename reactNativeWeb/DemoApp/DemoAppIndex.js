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
    displayDefaultSavedPaymentIcon: false,
    displayPayButton: true,
    disableBranding: true,
    // preloadCardElement: false,
    primaryButtonLabel: 'Initiate Deposit',
    netceteraSDKApiKey: '',
    locale: 'en',
    subscribedEvents: ['onSuccess', 'onFailed', 'onCancelled'],
    splitCardFields: true,
    paymentMethodLayout: {
      type: 'tabs',
      radios: false,
      maxAccordionItems: 3,
      paymentMethodsArrangementForTabs: "auto",
      spacedAccordionItems: true,
      defaultCollapsed: true,
      cvcIcon: 'hidden',
      cardBrandIcon: 'hideGeneric',
      showCheckedIconForSelection: true,
      savedMethodCustomization: {
        savedLogo: 'hidden',
        defaultCollapsed: false,
        hideCardExpiry: true,
        hideCVCError: false,
        cvcIcon: 'hidden',
        groupingBehavior: {
          displayInSeparateScreen: false,
          // displayInSeparateSection: true,
          groupByPaymentMethods: false,
        },
        hiddenPaymentMethods: ["apple_pay", "google_pay", "paypal"],
      },
    },
    appearance: {
      theme: 'Light',
      colors: {
        light: {
          primary: 'rgb(79, 175, 66)',
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
          selectedComponentBorder: 'rgb(79, 175, 66)',
          selectedComponentBorderWidth: 2.0,
          selectedComponentDivider: '#E0E0E0',
          selectedComponentText: '#000000',
        },
        dark: {
          primary: 'rgb(79, 175, 66)',
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
          selectedComponentBorder: 'rgb(79, 175, 66)',
          selectedComponentBorderWidth: 2.0,
          selectedComponentDivider: '#e6e6e6',
          selectedComponentText: '#ffffff',
        },
      },
      shapes: {
        borderRadius: 16.0,
        borderWidth: 1.0,
        inputHeight: 56.0,
        gap: 24.0,
        shadow: {
          color: '#000000',
          opacity: 0,
          blurRadius: 0,
          intensity: 0,
          offset: { x: 0, y: 0 },
        },
      },
      font: {
        family: 'Roboto',
        scale: 1.0,
      },
      primaryButton: {
        height: 56.0,
        shapes: {
          borderRadius: 16.0,
          borderWidth: 0,
          shadow: {
            color: '#000000',
            opacity: 0,
            blurRadius: 0,
            intensity: 0,
            offset: { x: 0, y: 0 },
          },
        },
        // colors: {
        //   light: {
        //     background: '#FFE500',
        //     text: '#000000',
        //     border: '#000000',
        //   },
        //   dark: {
        //     background: '#FFE500',
        //     text: '#000000',
        //     border: '#000000',
        //   },
        // },
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
        }
      },
    },
    walletButtonsConfiguration: {
      googlePay: {
        buttonType: 'plain',
        buttonStyle: { light: 'dark', dark: 'light' },
      },
      applePay: {
        buttonType: 'plain',
        buttonStyle: { light: 'black', dark: 'white' },
      },
    },
    // placeholder: {
    //   cardNumber: '4242 4242 4242 4242',
    //   expiryDate: 'MM / YY',
    //   cvv: 'CVC',
    // },
    redirectionInfo: 'hidden',
    stickyPayButton: true,
    alwaysSendCustomerAcceptance: true,
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
