const createPaymentBody = {
  amount: 2999,
  currency: 'USD',
  authentication_type: 'no_three_ds',
  customer_id: 'hyperswitch_demo_id',
  capture_method: 'automatic',
  email: 'abc@gmail.com',
  business_country: 'US',
  billing: {
    address: {
      line1: '1467',
      line2: 'Harrison Street',
      line3: 'Harrison Street',
      city: 'San Fransico',
      state: 'California',
      zip: '94122',
      country: 'US',
      first_name: 'joseph',
      last_name: 'Doe',
    },
  },
  shipping: {
    address: {
      line1: '1467',
      line2: 'Harrison Street',
      line3: 'Harrison Street',
      city: 'San Fransico',
      state: 'California',
      zip: '94122',
      country: 'US',
      first_name: 'joseph',
      last_name: 'Doe',
    },
  },
};

const createPaymentBody2 = {
  amount: 2999,
  currency: 'USD',
  authentication_type: 'no_three_ds',
  customer_id: 'hyperswitch_demo_id',
  capture_method: 'automatic',
  email: 'abc@gmail.com',
  business_country: 'US',
};

class CreateBody {
    body: any
    constructor() {
        // Deep clone to prevent shared state between test suites
        this.body = JSON.parse(JSON.stringify(createPaymentBody))
    }
    get() {
        return this.body
    }

    removeBilling() {
        delete this.body["billing"];
        return this
    }
    removeShipping() {
        delete this.body["shipping"];
        return this
    }
    addKey(key, value) {
        this.body[key] = value
    }

    removeKey(key, value) {
        if (this.body.hasOwnProperty(key))
            delete this.body[key];
    }

}

class CreateBody2 {
  body: any;
  constructor() {
    // Create a deep copy to avoid sharing references between instances
    this.body = JSON.parse(JSON.stringify(createPaymentBody2));
  }
  get() {
    return this.body;
  }

  addKey(key, value) {
    this.body[key] = value;
  }

  removeKey(key, value) {
    if (this.body.hasOwnProperty(key)) delete this.body[key];
  }

  removeBilling() {
    delete this.body['billing'];
    return this;
  }

  removeShipping() {
    delete this.body['shipping'];
    return this;
  }
}

const setCreateBodyForTestAutomation = async body => {
  const response = await fetch('http://localhost:5252/create-payment-intent', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    throw new Error(`Failed to create payment intent: ${response.status}`);
  }

  const data = await response.json();
  return data.clientSecret;
};

const fetchSessionData = async (clientSecret: string) => {
  const response = await fetch(
    `http://localhost:5252/session-data?client_secret=${encodeURIComponent(
      clientSecret,
    )}`,
  );
  if (!response.ok) {
    throw new Error(`Failed to fetch session data: ${response.status}`);
  }
  return await response.json();
};

const fetchPaymentMethods = async (clientSecret: string) => {
  const response = await fetch(
    `http://localhost:5252/payment-methods?client_secret=${encodeURIComponent(
      clientSecret,
    )}`,
  );
  if (!response.ok) {
    throw new Error(`Failed to fetch payment methods: ${response.status}`);
  }
  return await response.json();
};

export {
  createPaymentBody,
  setCreateBodyForTestAutomation,
  CreateBody,
  CreateBody2,
  fetchSessionData,
  fetchPaymentMethods,
};
