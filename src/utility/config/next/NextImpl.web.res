let clistRes = `
{"customer_payment_methods":[],"is_guest_customer":true}
`->JSON.parseExn

let listRes = `
{
    "redirect_url": "https://www.example.com/success",
    "currency": "USD",
    "payment_methods": [
        {
            "payment_method": "bank_transfer",
            "payment_method_types": [
                {
                    "payment_method_type": "multibanco",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "stripe"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "crypto",
            "payment_method_types": [
                {
                    "payment_method_type": "crypto_currency",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "bitpay",
                                "cryptopay",
                                "cashtocode",
                                "opennode"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "payment_method_data.crypto.pay_currency": {
                            "required_field": "payment_method_data.crypto.pay_currency",
                            "display_name": "currency",
                            "field_type": {
                                "user_currency": {
                                    "options": [
                                        "BTC",
                                        "LTC",
                                        "ETH",
                                        "XRP",
                                        "XLM",
                                        "BCH",
                                        "ADA",
                                        "SOL",
                                        "SHIB",
                                        "TRX",
                                        "DOGE",
                                        "BNB",
                                        "USDT",
                                        "USDC",
                                        "DAI"
                                    ]
                                }
                            },
                            "value": null
                        },
                        "payment_method_data.crypto.network": {
                            "required_field": "payment_method_data.crypto.network",
                            "display_name": "network",
                            "field_type": "user_crypto_currency_network",
                            "value": null
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "card_redirect",
            "payment_method_types": [
                {
                    "payment_method_type": "card_redirect",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "prophetpay"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "pay_later",
            "payment_method_types": [
                {
                    "payment_method_type": "klarna",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "stripe"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "payment_method_data.pay_later.klarna.billing_country": {
                            "required_field": "payment_method_data.pay_later.klarna.billing_country",
                            "display_name": "billing_country",
                            "field_type": {
                                "user_address_country": {
                                    "options": [
                                        "AU",
                                        "AT",
                                        "BE",
                                        "CA",
                                        "CZ",
                                        "DK",
                                        "FI",
                                        "FR",
                                        "GR",
                                        "DE",
                                        "IE",
                                        "IT",
                                        "NL",
                                        "NZ",
                                        "NO",
                                        "PL",
                                        "PT",
                                        "RO",
                                        "ES",
                                        "SE",
                                        "CH",
                                        "GB",
                                        "US"
                                    ]
                                }
                            },
                            "value": null
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "bank_debit",
            "payment_method_types": [
                {
                    "payment_method_type": "becs",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "stripe"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "billing_first_name",
                            "field_type": "user_billing_name",
                            "value": "joseph"
                        },
                        "payment_method_data.bank_debit.becs.bsb_number": {
                            "required_field": "payment_method_data.bank_debit.becs.bsb_number",
                            "display_name": "bsb_number",
                            "field_type": "text",
                            "value": null
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "owner_name",
                            "field_type": "user_billing_name",
                            "value": "Doe"
                        },
                        "payment_method_data.bank_debit.becs.account_number": {
                            "required_field": "payment_method_data.bank_debit.becs.account_number",
                            "display_name": "bank_account_number",
                            "field_type": "user_bank_account_number",
                            "value": null
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "reward",
            "payment_method_types": [
                {
                    "payment_method_type": "classic",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "cryptopay",
                                "cashtocode"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                },
                {
                    "payment_method_type": "evoucher",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "cashtocode"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "wallet",
            "payment_method_types": [
                {
                    "payment_method_type": "apple_pay",
                    "payment_experience": [
                        {
                            "payment_experience_type": "invoke_sdk_client",
                            "eligible_connectors": [
                                "cybersource"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.address.country": {
                            "required_field": "payment_method_data.billing.address.country",
                            "display_name": "country",
                            "field_type": {
                                "user_address_country": {
                                    "options": [
                                        "ALL"
                                    ]
                                }
                            },
                            "value": "PL"
                        },
                        "billing.address.zip": {
                            "required_field": "payment_method_data.billing.address.zip",
                            "display_name": "zip",
                            "field_type": "user_address_pincode",
                            "value": "94122"
                        },
                        "billing.address.state": {
                            "required_field": "payment_method_data.billing.address.state",
                            "display_name": "state",
                            "field_type": "user_address_state",
                            "value": "California"
                        },
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "billing_first_name",
                            "field_type": "user_billing_name",
                            "value": "joseph"
                        },
                        "billing.address.line1": {
                            "required_field": "payment_method_data.billing.address.line1",
                            "display_name": "line1",
                            "field_type": "user_address_line1",
                            "value": "1467"
                        },
                        "billing.address.city": {
                            "required_field": "payment_method_data.billing.address.city",
                            "display_name": "city",
                            "field_type": "user_address_city",
                            "value": "San Fransico"
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "billing_last_name",
                            "field_type": "user_billing_name",
                            "value": "Doe"
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                },
                {
                    "payment_method_type": "google_pay",
                    "payment_experience": [
                        {
                            "payment_experience_type": "invoke_sdk_client",
                            "eligible_connectors": [
                                "cybersource"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.address.country": {
                            "required_field": "payment_method_data.billing.address.country",
                            "display_name": "country",
                            "field_type": {
                                "user_address_country": {
                                    "options": [
                                        "ALL"
                                    ]
                                }
                            },
                            "value": "PL"
                        },
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "billing_first_name",
                            "field_type": "user_billing_name",
                            "value": "joseph"
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "billing_last_name",
                            "field_type": "user_billing_name",
                            "value": "Doe"
                        },
                        "billing.address.state": {
                            "required_field": "payment_method_data.billing.address.state",
                            "display_name": "state",
                            "field_type": "user_address_state",
                            "value": "California"
                        },
                        "billing.address.city": {
                            "required_field": "payment_method_data.billing.address.city",
                            "display_name": "city",
                            "field_type": "user_address_city",
                            "value": "San Fransico"
                        },
                        "billing.address.zip": {
                            "required_field": "payment_method_data.billing.address.zip",
                            "display_name": "zip",
                            "field_type": "user_address_pincode",
                            "value": "94122"
                        },
                        "billing.address.line1": {
                            "required_field": "payment_method_data.billing.address.line1",
                            "display_name": "line1",
                            "field_type": "user_address_line1",
                            "value": "1467"
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                },
                {
                    "payment_method_type": "paypal",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "authorizedotnet"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "upi",
            "payment_method_types": [
                {
                    "payment_method_type": "upi_collect",
                    "payment_experience": [
                        {
                            "payment_experience_type": "redirect_to_url",
                            "eligible_connectors": [
                                "iatapay"
                            ]
                        }
                    ],
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": {
                        "surcharge": {
                            "type": "rate",
                            "value": {
                                "percentage": 10.0
                            }
                        },
                        "tax_on_surcharge": {
                            "percentage": 0.0
                        },
                        "display_surcharge_amount": 3.0,
                        "display_tax_on_surcharge_amount": 0.0,
                        "display_total_surcharge_amount": 3.0
                    },
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "card",
            "payment_method_types": [
                {
                    "payment_method_type": "credit",
                    "payment_experience": null,
                    "card_networks": [
                        {
                            "card_network": "Discover",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Interac",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "CartesBancaires",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Visa",
                            "surcharge_details": null,
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "zen",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "DinersClub",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "JCB",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "AmericanExpress",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Mastercard",
                            "surcharge_details": null,
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "zen",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "UnionPay",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        }
                    ],
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.address.city": {
                            "required_field": "payment_method_data.billing.address.city",
                            "display_name": "city",
                            "field_type": "user_address_city",
                            "value": "San Fransico"
                        },
                        "billing.address.country": {
                            "required_field": "payment_method_data.billing.address.country",
                            "display_name": "country",
                            "field_type": {
                                "user_address_country": {
                                    "options": [
                                        "ALL"
                                    ]
                                }
                            },
                            "value": "PL"
                        },
                        "billing.address.zip": {
                            "required_field": "payment_method_data.billing.address.zip",
                            "display_name": "zip",
                            "field_type": "user_address_pincode",
                            "value": "94122"
                        },
                        "billing.address.line1": {
                            "required_field": "payment_method_data.billing.address.line1",
                            "display_name": "line1",
                            "field_type": "user_address_line1",
                            "value": "1467"
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        },
                        "billing.address.state": {
                            "required_field": "payment_method_data.billing.address.state",
                            "display_name": "state",
                            "field_type": "user_address_state",
                            "value": "California"
                        },
                        "email": {
                            "required_field": "email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        },
                        "payment_method_data.card.card_cvc": {
                            "required_field": "payment_method_data.card.card_cvc",
                            "display_name": "card_cvc",
                            "field_type": "user_card_cvc",
                            "value": null
                        },
                        "payment_method_data.card.card_exp_year": {
                            "required_field": "payment_method_data.card.card_exp_year",
                            "display_name": "card_exp_year",
                            "field_type": "user_card_expiry_year",
                            "value": null
                        },
                        "payment_method_data.card.card_number": {
                            "required_field": "payment_method_data.card.card_number",
                            "display_name": "card_number",
                            "field_type": "user_card_number",
                            "value": null
                        },
                        "payment_method_data.card.card_exp_month": {
                            "required_field": "payment_method_data.card.card_exp_month",
                            "display_name": "card_exp_month",
                            "field_type": "user_card_expiry_month",
                            "value": null
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "card_holder_name",
                            "field_type": "user_full_name",
                            "value": "Doe"
                        },
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "card_holder_name",
                            "field_type": "user_full_name",
                            "value": "joseph"
                        }
                    },
                    "surcharge_details": null,
                    "pm_auth_connector": null
                },
                {
                    "payment_method_type": "debit",
                    "payment_experience": null,
                    "card_networks": [
                        {
                            "card_network": "Discover",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Visa",
                            "surcharge_details": null,
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "zen",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "UnionPay",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "AmericanExpress",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Interac",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "CartesBancaires",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "JCB",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "DinersClub",
                            "surcharge_details": {
                                "surcharge": {
                                    "type": "rate",
                                    "value": {
                                        "percentage": 10.0
                                    }
                                },
                                "tax_on_surcharge": {
                                    "percentage": 0.0
                                },
                                "display_surcharge_amount": 3.0,
                                "display_tax_on_surcharge_amount": 0.0,
                                "display_total_surcharge_amount": 3.0
                            },
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "stripe"
                            ]
                        },
                        {
                            "card_network": "Mastercard",
                            "surcharge_details": null,
                            "eligible_connectors": [
                                "rapyd",
                                "worldline",
                                "fiserv",
                                "paypal_test",
                                "nuvei",
                                "pretendpay",
                                "nmi",
                                "payme",
                                "braintree",
                                "cybersource",
                                "checkout",
                                "aci",
                                "forte",
                                "bankofamerica",
                                "tsys",
                                "noon",
                                "airwallex",
                                "stripe_test",
                                "nexinets",
                                "bluesnap",
                                "paypal",
                                "iatapay",
                                "worldpay",
                                "trustpay",
                                "stax",
                                "authorizedotnet",
                                "adyen",
                                "shift4",
                                "zen",
                                "stripe"
                            ]
                        }
                    ],
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "payment_method_data.card.card_exp_year": {
                            "required_field": "payment_method_data.card.card_exp_year",
                            "display_name": "card_exp_year",
                            "field_type": "user_card_expiry_year",
                            "value": null
                        },
                        "payment_method_data.card.card_cvc": {
                            "required_field": "payment_method_data.card.card_cvc",
                            "display_name": "card_cvc",
                            "field_type": "user_card_cvc",
                            "value": null
                        },
                        "billing.address.city": {
                            "required_field": "payment_method_data.billing.address.city",
                            "display_name": "city",
                            "field_type": "user_address_city",
                            "value": "San Fransico"
                        },
                        "billing.address.zip": {
                            "required_field": "payment_method_data.billing.address.zip",
                            "display_name": "zip",
                            "field_type": "user_address_pincode",
                            "value": "94122"
                        },
                        "billing.address.line1": {
                            "required_field": "payment_method_data.billing.address.line1",
                            "display_name": "line1",
                            "field_type": "user_address_line1",
                            "value": "1467"
                        },
                        "payment_method_data.card.card_number": {
                            "required_field": "payment_method_data.card.card_number",
                            "display_name": "card_number",
                            "field_type": "user_card_number",
                            "value": null
                        },
                        "payment_method_data.card.card_exp_month": {
                            "required_field": "payment_method_data.card.card_exp_month",
                            "display_name": "card_exp_month",
                            "field_type": "user_card_expiry_month",
                            "value": null
                        },
                        "billing.address.state": {
                            "required_field": "payment_method_data.billing.address.state",
                            "display_name": "state",
                            "field_type": "user_address_state",
                            "value": "California"
                        },
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "card_holder_name",
                            "field_type": "user_full_name",
                            "value": "joseph"
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "card_holder_name",
                            "field_type": "user_full_name",
                            "value": "Doe"
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        },
                        "billing.address.country": {
                            "required_field": "payment_method_data.billing.address.country",
                            "display_name": "country",
                            "field_type": {
                                "user_address_country": {
                                    "options": [
                                        "ALL"
                                    ]
                                }
                            },
                            "value": "PL"
                        },
                        "email": {
                            "required_field": "email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": null,
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "bank_redirect",
            "payment_method_types": [
                {
                    "payment_method_type": "interac",
                    "payment_experience": null,
                    "card_networks": null,
                    "bank_names": [],
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": null,
                    "surcharge_details": null,
                    "pm_auth_connector": null
                },
                {
                    "payment_method_type": "przelewy24",
                    "payment_experience": null,
                    "card_networks": null,
                    "bank_names": [
                        {
                            "bank_name": [
                                "idea_bank",
                                "bnp_paribas",
                                "alior_bank",
                                "citi",
                                "noble_pay",
                                "credit_agricole",
                                "pbac_z_ipko",
                                "plus_bank",
                                "santander_przelew24",
                                "mbank_mtransfer",
                                "bank_pekao_sa",
                                "boz",
                                "inteligo",
                                "volkswagen_bank",
                                "e_transfer_pocztowy24",
                                "toyota_bank",
                                "getin_bank",
                                "blik",
                                "nest_przelew",
                                "bank_millennium",
                                "bank_nowy_bfg_sa",
                                "banki_spbdzielcze"
                            ],
                            "eligible_connectors": [
                                "stripe"
                            ]
                        }
                    ],
                    "bank_debits": null,
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": null,
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "bank_debit",
            "payment_method_types": [
                {
                    "payment_method_type": "becs",
                    "payment_experience": null,
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": {
                        "eligible_connectors": [
                            "stripe"
                        ]
                    },
                    "bank_transfers": null,
                    "required_fields": {
                        "billing.address.first_name": {
                            "required_field": "payment_method_data.billing.address.first_name",
                            "display_name": "billing_first_name",
                            "field_type": "user_billing_name",
                            "value": "joseph"
                        },
                        "payment_method_data.bank_debit.becs.bsb_number": {
                            "required_field": "payment_method_data.bank_debit.becs.bsb_number",
                            "display_name": "bsb_number",
                            "field_type": "text",
                            "value": null
                        },
                        "billing.address.last_name": {
                            "required_field": "payment_method_data.billing.address.last_name",
                            "display_name": "owner_name",
                            "field_type": "user_billing_name",
                            "value": "Doe"
                        },
                        "payment_method_data.bank_debit.becs.account_number": {
                            "required_field": "payment_method_data.bank_debit.becs.account_number",
                            "display_name": "bank_account_number",
                            "field_type": "user_bank_account_number",
                            "value": null
                        },
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": null,
                    "pm_auth_connector": null
                }
            ]
        },
        {
            "payment_method": "bank_transfer",
            "payment_method_types": [
                {
                    "payment_method_type": "multibanco",
                    "payment_experience": null,
                    "card_networks": null,
                    "bank_names": null,
                    "bank_debits": null,
                    "bank_transfers": {
                        "eligible_connectors": [
                            "stripe"
                        ]
                    },
                    "required_fields": {
                        "billing.email": {
                            "required_field": "payment_method_data.billing.email",
                            "display_name": "email",
                            "field_type": "user_email_address",
                            "value": "abc@gmail.com"
                        }
                    },
                    "surcharge_details": null,
                    "pm_auth_connector": null
                }
            ]
        }
    ],
    "mandate_payment": null,
    "merchant_name": "sandboxtesterjp",
    "show_surcharge_breakup_screen": true,
    "payment_type": "normal",
    "request_external_three_ds_authentication": false,
    "collect_shipping_details_from_wallets": false,
    "collect_billing_details_from_wallets": true,
    "is_tax_calculation_enabled": false
}
`->JSON.parseExn

let sessionsRes = `
{
    "payment_id": "pay_NqAQn9DZQr0uuONSmV9K",
    "client_secret": "pay_sample_secret_sample",
    "session_token": [
        {
            "wallet_name": "google_pay",
            "merchant_info": {
                "merchant_id": "juspay_us_sandbox",
                "merchant_name": "juspay_us_sandbox"
            },
            "shipping_address_required": false,
            "email_required": true,
            "shipping_address_parameters": {
                "phone_number_required": false
            },
            "allowed_payment_methods": [
                {
                    "type": "CARD",
                    "parameters": {
                        "allowed_auth_methods": [
                            "PAN_ONLY",
                            "CRYPTOGRAM_3DS"
                        ],
                        "allowed_card_networks": [
                            "AMEX",
                            "DISCOVER",
                            "INTERAC",
                            "JCB",
                            "MASTERCARD",
                            "VISA"
                        ],
                        "billing_address_required": true,
                        "billing_address_parameters": {
                            "phone_number_required": true,
                            "format": "FULL"
                        }
                    },
                    "tokenization_specification": {
                        "type": "PAYMENT_GATEWAY",
                        "parameters": {
                            "gateway": "cybersource",
                            "gateway_merchant_id": "juspay_us_sandbox"
                        }
                    }
                }
            ],
            "transaction_info": {
                "country_code": "PL",
                "currency_code": "USD",
                "total_price_status": "Final",
                "total_price": "29.99"
            },
            "delayed_session_token": false,
            "connector": "cybersource",
            "sdk_next_action": {
                "next_action": "confirm"
            },
            "secrets": null
        },
        {
            "wallet_name": "apple_pay",
            "payment_request_data": {
                "country_code": "US",
                "currency_code": "USD",
                "total": {
                    "label": "apple",
                    "type": "final",
                    "amount": "29.99"
                },
                "merchant_capabilities": [
                    "supports3DS"
                ],
                "supported_networks": [
                    "visa",
                    "masterCard",
                    "amex",
                    "discover"
                ],
                "merchant_identifier": "merchant.test.fb",
                "required_billing_contact_fields": [
                    "postalAddress"
                ],
                "required_shipping_contact_fields": [
                    "phone",
                    "email"
                ]
            },
            "connector": "cybersource",
            "delayed_session_token": false,
            "sdk_next_action": {
                "next_action": "confirm"
            },
            "connector_reference_id": null,
            "connector_sdk_public_key": null,
            "connector_merchant_id": null
        }
    ]
}
`->JSON.parseExn
