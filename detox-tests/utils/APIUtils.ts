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
}

class CreateBody {
    body: any
    constructor() {
        this.body = createPaymentBody

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

const setCreateBodyForTestAutomation = async (body) => {
    await fetch("http://localhost:5252/create-payment-intent", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
    })
}
export { setCreateBodyForTestAutomation, CreateBody }