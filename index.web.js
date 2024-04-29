import {AppRegistry} from 'react-native';
import {name as appName} from './app.json';
import {app} from './src/routes/WebApp.bs.js';
if (module.hot) {
  module.hot.accept();
}
AppRegistry.registerComponent(appName, () => app);

// function handleMessage(ev) {
//   console.log('got 2 event form dashboard', ev.data);
// }
// window.addEventListener('message', handleMessage);
// primary: option<string>,
// background: option<string>,
// componentBackground: option<string>,
// componentBorder: option<string>,
// componentDivider: option<string>,
// componentText: option<string>,
// primaryText: option<string>,
// secondaryText: option<string>,
// placeholderText: option<string>,
// icon: option<string>,
// error: option<string>,

const runApp = async () => {
  let props = {
    local: true,
    configuration: {
      paymentSheetHeaderLabel: 'Add a payment methord',
      savedPaymentSheetHeaderLabel: 'Saved payment methord',
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
      // displaySavedPaymentMethods: false,
      // appearance:{
      //   // componentBackground:"black",
      //   colors:{
      //     background:"#F5F8F9",
      //     primary:"#8DBD00"

      //   },
      //   primaryButton:{
      //   shapes:{
      //     borderRadius:20.0
      //   }}

      // }
    },
    hyperParams: {
      ip: '13.232.74.226',
      'user-agent':
        'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.',
      launchTime: Date.now(),
    },
    country: 'US',
    type: 'payment',
  };

  const searchParams = new URLSearchParams(
    new URL(window.location.href).search,
  );
  if (searchParams.size === 2) {
    props.publishableKey = searchParams.get('pk');
    props.clientSecret = searchParams.get('cs');
  } else if (window.location.href == 'http://localhost:8080/') {
    let response = await fetch('http://localhost:5252/create-payment-intent');
    const data = await response.json();
    props.publishableKey = data.publishableKey;
    props.clientSecret = data.clientSecret;
  }

  AppRegistry.runApplication(appName, {
    initialProps: {props},
    rootTag: document.getElementById('app-root'),
  });
  window.parent.postMessage(
    JSON.stringify({
      sdkLoaded: true,
    }),
    '*',
  );
};

runApp();
