let defaultProps = {
  local: false,
  configuration: {
    paymentSheetHeaderLabel: 'Add a payment method',
    savedPaymentSheetHeaderLabel: 'Saved payment method',
    allowsDelayedPaymentMethods: true,
    merchantDisplayName: 'Example, Inc.',
    // disableSavedCardScreen: true,
    // paymentSheetHeaderText: 'Hello world',
    // savedPaymentScreenHeaderText: 'Testing....',
    allowsPaymentMethodsRequiringShippingAddress: false,
    googlePay: {
      environment: 'Test',
      countryCode: 'US',
      currencyCode: 'US',
    },
    // displaySavedPaymentMethodsCheckbox: false,
    // shippingDetails: {
    //   address: {
    //     city: 'city',
    //     country: 'US',
    //     line1: 'US',
    //     line2: 'line2',
    //     postalCode: '560060',
    //     state: 'California',
    //   },
    //   name: 'Shipping INC',
    // },
    // displaySavedPaymentMethods: false,
    appearance: {
      theme: 'Light',
      // layout: 'accordion',
      // colors:{
      //   background:"rgb(58, 23, 84)",
      //   primary:"#fff",
      //   componentBorder: "#00000050",
      //   componentBackground: "#00000030",
      // },
      // shapes:{
      //   borderRadius:8.0
      // },
      // primaryButton:{
      //   shapes:{
      //     borderRadius:8.0
      //   },
      //   colors: {
      //     text: "#000"
      //   }
      // },
      // locale: "fr",
      // typography: {
        // family: 'Montserrat',
        // sizeScaleFactor: 0.9
      // },
    },
    displayMergedSavedMethods: true,
  },
  hyperParams: {
    ip: '13.232.74.226',
    'user-agent':
      'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.',
    launchTime: Date.now(),
    // country: 'AT',
  },
  from: 'rn',
  type: 'payment',

    // | "payment" => PaymentSheet
    // | "tabSheet" => TabSheet
    // | "buttonSheet" => ButtonSheet
    // | "widgetPaymentSheet" => WidgetPaymentSheet
    // | "widgetTabSheet" => WidgetTabSheet
    // | "widgetButtonSheet" => WidgetButtonSheet

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
      defaultProps.publishableKey = data.publishableKey;
      defaultProps.clientSecret = data.clientSecret;
      defaultProps.local = true;

      const iframe = document.querySelector('iframe');
      if (iframe && iframe.contentWindow) {
        iframe.contentWindow.postMessage(
          JSON.stringify({initialProps: {props: defaultProps}}),
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
          statusElement.textContent = `Status: ${data.status} ${
            data.message ? 'Message: ' + data.message : ''
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
