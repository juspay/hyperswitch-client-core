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
    displaySavedPaymentMethodsCheckbox: false,
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
      // componentBackground:"black",
      // colors:{
      //   background:"#F5F8F9",
      //   primary:"#8DBD00"
      // },
      // primaryButton:{
      // shapes:{
      //   borderRadius:20.0
      // }}
      // locale: "en"
      typography: {
        fontResId: 'montserrat',
      },
    },
  },
  hyperParams: {
    ip: '13.232.74.226',
    'user-agent':
      'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.',
    launchTime: Date.now(),
    // country: 'AT',
    country: 'US',
  },
  country: 'US',
  type: 'payment',
};

const initReactNativeWeb = async () => {
  const createProps = async () => {
    let response = await fetch('http://localhost:5252/create-payment-intent');
    const data = await response.json();
    defaultProps.publishableKey = data.publishableKey;
    defaultProps.clientSecret = data.clientSecret;
    defaultProps.local = true;
    document.querySelector('iframe').contentWindow.postMessage(
      JSON.stringify({
        initialProps: {
          props: defaultProps,
        },
      }),
      '*',
    );
  };

  const handleMessage = event => {
    try {
      let data = JSON.parse(event.data);
      if (data.sdkLoaded) {
        createProps();
      }
      if (data.status) {
        document.querySelector('iframe').style.display = 'none';
        document.getElementById('status').innerHTML = `Status: ${data.status} ${
          data.message ? 'Message: ' + data.message : ''
        }`;
      }
    } catch (ex) {}
  };

  window.addEventListener('message', handleMessage);
};

initReactNativeWeb();
