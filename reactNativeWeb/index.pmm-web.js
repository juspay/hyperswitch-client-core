import {AppRegistry} from 'react-native';
import appJson from '../app.json';
import PMMRoot from '../src/payment-method-management/PMMEntry';

// The `hyperPMM` web entry: mirrors index.web.js but mounts PMMRoot under the
// PMM app name, so no props-level `type` routing is needed (and the DemoApp
// harness stays untouched). It sources its own payment-method session.
const PM_SESSION_URL = 'http://localhost:5252/create-payment-method-session';

const init = async () => {
  try {
    const response = await fetch(PM_SESSION_URL, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({
        storage_type: 'persistent',
        keep_alive: true,
        billing: {
          address: {first_name: 'hellow', last_name: 'world'},
          email: 'example@example.com',
        },
      }),
    });
    if (!response.ok) {
      throw new Error(`HTTP error! Status: ${response.status}`);
    }
    const data = await response.json();

    AppRegistry.registerComponent(appJson.pmm, () => PMMRoot);
    AppRegistry.runApplication(appJson.pmm, {
      initialProps: {
        props: {
          type: 'paymentMethodsManagement',
          hyperswitchConfig: {
            publishableKey: data.publishableKey ?? '',
            profileId: data.profileId ?? '',
            environment: 'sandbox',
          },
          paymentSessionConfig: {
            sdkAuthorization: data.sdkAuthorization ?? '',
          },
          configuration: {
            merchantDisplayName: 'Example, Inc.',
            locale: 'en',
            disableBranding: true,
          },
          sdkParams: {
            sessionId: '',
            sdkVersion: '1.0.0',
            confirm: false,
            'user-agent': navigator.userAgent,
            launchTime: Date.now(),
            country: 'US',
            device_model: 'iPhone',
            os_type: 'iOS',
            os_version: '18.5',
            deviceBrand: 'Apple',
          },
        },
        rootTag: 1,
      },
      rootTag: document.getElementById('app-root'),
    });
  } catch (error) {
    console.error('Error fetching payment method session:', error);
  }
};

init();
