type environment = {environment: string}
type env = {env: environment}
@val external process: env = "process"

let getNextEnv = try {
  process.env.environment
} catch {
| _ => ""
}

let listRes = `{
            "redirect_url": "https://chrome.google.com/",
            "payment_methods": [
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
                                "email": {
                                    "required_field": "email",
                                    "display_name": "email",
                                    "field_type": "user_email_address",
                                    "value": "josephDoe@gmail.com"
                                },
                                "payment_method_data.pay_later.klarna.billing_country": {
                                    "required_field": "payment_method_data.pay_later.klarna.billing_country",
                                    "display_name": "billing_country",
                                    "field_type": {
                                        "user_address_country": {
                                            "options": [
                                                "ALL"
                                            ]
                                        }
                                    },
                                    "value": null
                                }
                            },
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "affirm",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "afterpay_clearpay",
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
                                "payment_method_data.pay_later.afterpay_clearpay_redirect.billing_email": {
                                    "required_field": "payment_method_data.pay_later.afterpay_clearpay_redirect.billing_email",
                                    "display_name": "billing_email",
                                    "field_type": "user_email_address",
                                    "value": null
                                },
                                "name": {
                                    "required_field": "name",
                                    "display_name": "cust_name",
                                    "field_type": "user_full_name",
                                    "value": "hubert"
                                }
                            },
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "bank_transfer",
                    "payment_method_types": [
                        {
                            "payment_method_type": "sepa",
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
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "ach",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "bacs",
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
                            "required_fields": null,
                            "surcharge_details": null
                        },
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
                            "required_fields": {},
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "bank_debit",
                    "payment_method_types": [
                        {
                            "payment_method_type": "ach",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "sepa",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "bacs",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
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
                            "required_fields": null,
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "wallet",
                    "payment_method_types": [
                        {
                            "payment_method_type": "ali_pay",
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "cashapp",
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
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "google_pay",
                            "payment_experience": [
                                {
                                    "payment_experience_type": "invoke_sdk_client",
                                    "eligible_connectors": [
                                        "checkout"
                                    ]
                                }
                            ],
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "apple_pay",
                            "payment_experience": [
                                {
                                    "payment_experience_type": "invoke_sdk_client",
                                    "eligible_connectors": [
                                        "checkout"
                                    ]
                                }
                            ],
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "we_chat_pay",
                            "payment_experience": [
                                {
                                    "payment_experience_type": "display_qr_code",
                                    "eligible_connectors": [
                                        "stripe"
                                    ]
                                }
                            ],
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
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
                                    "card_network": "CartesBancaires",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Discover",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Mastercard",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "DinersClub",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Interac",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe"
                                    ]
                                },
                                {
                                    "card_network": "Visa",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "JCB",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "AmericanExpress",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "UnionPay",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                }
                            ],
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": {
                                "payment_method_data.card.card_exp_month": {
                                    "required_field": "payment_method_data.card.card_exp_month",
                                    "display_name": "card_exp_month",
                                    "field_type": "user_card_expiry_month",
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
                                "payment_method_data.card.card_holder_name": {
                                    "required_field": "payment_method_data.card.card_holder_name",
                                    "display_name": "card_holder_name",
                                    "field_type": "user_full_name",
                                    "value": null
                                },
                                "billing.address.last_name": {
                                    "required_field": "billing.address.last_name",
                                    "display_name": "billing_last_name",
                                    "field_type": "user_billing_name",
                                    "value": "Doe"
                                },
                                "payment_method_data.card.card_cvc": {
                                    "required_field": "payment_method_data.card.card_cvc",
                                    "display_name": "card_cvc",
                                    "field_type": "user_card_cvc",
                                    "value": null
                                },
                                "billing.address.first_name": {
                                    "required_field": "billing.address.first_name",
                                    "display_name": "billing_first_name",
                                    "field_type": "user_billing_name",
                                    "value": "joseph"
                                },
                                "email": {
                                    "required_field": "email",
                                    "display_name": "email",
                                    "field_type": "user_email_address",
                                    "value": "josephDoe@gmail.com"
                                }
                            },
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "debit",
                            "payment_experience": null,
                            "card_networks": [
                                {
                                    "card_network": "Interac",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "JCB",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "CartesBancaires",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "AmericanExpress",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "DinersClub",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Mastercard",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Discover",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "Visa",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                },
                                {
                                    "card_network": "UnionPay",
                                    "surcharge_details": null,
                                    "eligible_connectors": [
                                        "checkout",
                                        "bluesnap",
                                        "stripe",
                                        "trustpay"
                                    ]
                                }
                            ],
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": {
                                "payment_method_data.card.card_holder_name": {
                                    "required_field": "payment_method_data.card.card_holder_name",
                                    "display_name": "card_holder_name",
                                    "field_type": "user_full_name",
                                    "value": null
                                },
                                "payment_method_data.card.card_cvc": {
                                    "required_field": "payment_method_data.card.card_cvc",
                                    "display_name": "card_cvc",
                                    "field_type": "user_card_cvc",
                                    "value": null
                                },
                                "payment_method_data.card.card_exp_month": {
                                    "required_field": "payment_method_data.card.card_exp_month",
                                    "display_name": "card_exp_month",
                                    "field_type": "user_card_expiry_month",
                                    "value": null
                                },
                                "billing.address.first_name": {
                                    "required_field": "billing.address.first_name",
                                    "display_name": "billing_first_name",
                                    "field_type": "user_billing_name",
                                    "value": "joseph"
                                },
                                "payment_method_data.card.card_exp_year": {
                                    "required_field": "payment_method_data.card.card_exp_year",
                                    "display_name": "card_exp_year",
                                    "field_type": "user_card_expiry_year",
                                    "value": null
                                },
                                "billing.address.last_name": {
                                    "required_field": "billing.address.last_name",
                                    "display_name": "billing_last_name",
                                    "field_type": "user_billing_name",
                                    "value": "Doe"
                                },
                                "payment_method_data.card.card_number": {
                                    "required_field": "payment_method_data.card.card_number",
                                    "display_name": "card_number",
                                    "field_type": "user_card_number",
                                    "value": null
                                },
                                "email": {
                                    "required_field": "email",
                                    "display_name": "email",
                                    "field_type": "user_email_address",
                                    "value": "josephDoe@gmail.com"
                                }
                            },
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "bank_redirect",
                    "payment_method_types": [
                        {
                            "payment_method_type": "bancontact_card",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": [],
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "przelewy24",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": [
                                {
                                    "bank_name": [
                                        "pbac_z_ipko",
                                        "blik",
                                        "mbank_mtransfer",
                                        "plus_bank",
                                        "bank_millennium",
                                        "noble_pay",
                                        "nest_przelew",
                                        "alior_bank",
                                        "credit_agricole",
                                        "bnp_paribas",
                                        "inteligo",
                                        "volkswagen_bank",
                                        "getin_bank",
                                        "bank_pekao_sa",
                                        "idea_bank",
                                        "toyota_bank",
                                        "boz",
                                        "citi",
                                        "e_transfer_pocztowy24",
                                        "bank_nowy_bfg_sa",
                                        "santander_przelew24",
                                        "banki_spbdzielcze"
                                    ],
                                    "eligible_connectors": [
                                        "stripe"
                                    ]
                                }
                            ],
                            "bank_debits": null,
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "bank_debit",
                    "payment_method_types": [
                        {
                            "payment_method_type": "ach",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
                        },
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
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "sepa",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "bacs",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "bank_transfers": null,
                            "required_fields": {},
                            "surcharge_details": null
                        }
                    ]
                },
                {
                    "payment_method": "bank_transfer",
                    "payment_method_types": [
                        {
                            "payment_method_type": "ach",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "required_fields": {},
                            "surcharge_details": null
                        },
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
                            "required_fields": {},
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "bacs",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "required_fields": null,
                            "surcharge_details": null
                        },
                        {
                            "payment_method_type": "sepa",
                            "payment_experience": null,
                            "card_networks": null,
                            "bank_names": null,
                            "bank_debits": null,
                            "bank_transfers": {
                                "eligible_connectors": [
                                    "stripe"
                                ]
                            },
                            "required_fields": null,
                            "surcharge_details": null
                        }
                    ]
                }
            ],
            "mandate_payment": null,
            "merchant_name": "NewAge Retailer",
            "show_surcharge_breakup_screen": false,
            "payment_type": "normal"
        }`->JSON.parseExn

let sessionsRes = `{
          "payment_id": "pay_iduLsbbgKqAemYcXNn73",
          "client_secret": "pay_iduLsbbgKqAemYcXNn73_secret_Mxtg5tqQKPxiockssLCP",
          "session_token": [
              {
                  "wallet_name": "apple_pay",
                  "session_token_data": {
                      "epoch_timestamp": 1697703881252,
                      "expires_at": 1697707481252,
                      "merchant_session_identifier": "SSH70F5542D6E894E1081AF539A818090C3_2101F68F6980DFE07DEFE987B1CAF2961766C119C8FDCBB33566B1A97F33C9C3",
                      "nonce": "0ed701a1",
                      "merchant_identifier": "76B79A8E91F4D365B0B636C8F75CB207D52532E82C2C085DE79D6D8135EF3813",
                      "domain_name": "demo-hyperswitch.netlify.app",
                      "display_name": "checkoutapple",
                      "signature": "308006092a864886f70d010702a0803080020101310d300b0609608648016503040201308006092a864886f70d0107010000a080308203e330820388a00302010202084c304149519d5436300a06082a8648ce3d040302307a312e302c06035504030c254170706c65204170706c69636174696f6e20496e746567726174696f6e204341202d20473331263024060355040b0c1d4170706c652043657274696669636174696f6e20417574686f7269747931133011060355040a0c0a4170706c6520496e632e310b3009060355040613025553301e170d3139303531383031333235375a170d3234303531363031333235375a305f3125302306035504030c1c6563632d736d702d62726f6b65722d7369676e5f5543342d50524f4431143012060355040b0c0b694f532053797374656d7331133011060355040a0c0a4170706c6520496e632e310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004c21577edebd6c7b2218f68dd7090a1218dc7b0bd6f2c283d846095d94af4a5411b83420ed811f3407e83331f1c54c3f7eb3220d6bad5d4eff49289893e7c0f13a38202113082020d300c0603551d130101ff04023000301f0603551d2304183016801423f249c44f93e4ef27e6c4f6286c3fa2bbfd2e4b304506082b0601050507010104393037303506082b060105050730018629687474703a2f2f6f6373702e6170706c652e636f6d2f6f63737030342d6170706c65616963613330323082011d0603551d2004820114308201103082010c06092a864886f7636405013081fe3081c306082b060105050702023081b60c81b352656c69616e6365206f6e207468697320636572746966696361746520627920616e7920706172747920617373756d657320616363657074616e6365206f6620746865207468656e206170706c696361626c65207374616e64617264207465726d7320616e6420636f6e646974696f6e73206f66207573652c20636572746966696361746520706f6c69637920616e642063657274696669636174696f6e2070726163746963652073746174656d656e74732e303606082b06010505070201162a687474703a2f2f7777772e6170706c652e636f6d2f6365727469666963617465617574686f726974792f30340603551d1f042d302b3029a027a0258623687474703a2f2f63726c2e6170706c652e636f6d2f6170706c6561696361332e63726c301d0603551d0e041604149457db6fd57481868989762f7e578507e79b5824300e0603551d0f0101ff040403020780300f06092a864886f76364061d04020500300a06082a8648ce3d0403020349003046022100be09571fe71e1e735b55e5afacb4c72feb445f30185222c7251002b61ebd6f55022100d18b350a5dd6dd6eb1746035b11eb2ce87cfa3e6af6cbd8380890dc82cddaa63308202ee30820275a0030201020208496d2fbf3a98da97300a06082a8648ce3d0403023067311b301906035504030c124170706c6520526f6f74204341202d20473331263024060355040b0c1d4170706c652043657274696669636174696f6e20417574686f7269747931133011060355040a0c0a4170706c6520496e632e310b3009060355040613025553301e170d3134303530363233343633305a170d3239303530363233343633305a307a312e302c06035504030c254170706c65204170706c69636174696f6e20496e746567726174696f6e204341202d20473331263024060355040b0c1d4170706c652043657274696669636174696f6e20417574686f7269747931133011060355040a0c0a4170706c6520496e632e310b30090603550406130255533059301306072a8648ce3d020106082a8648ce3d03010703420004f017118419d76485d51a5e25810776e880a2efde7bae4de08dfc4b93e13356d5665b35ae22d097760d224e7bba08fd7617ce88cb76bb6670bec8e82984ff5445a381f73081f4304606082b06010505070101043a3038303606082b06010505073001862a687474703a2f2f6f6373702e6170706c652e636f6d2f6f63737030342d6170706c65726f6f7463616733301d0603551d0e0416041423f249c44f93e4ef27e6c4f6286c3fa2bbfd2e4b300f0603551d130101ff040530030101ff301f0603551d23041830168014bbb0dea15833889aa48a99debebdebafdacb24ab30370603551d1f0430302e302ca02aa0288626687474703a2f2f63726c2e6170706c652e636f6d2f6170706c65726f6f74636167332e63726c300e0603551d0f0101ff0404030201063010060a2a864886f7636406020e04020500300a06082a8648ce3d040302036700306402303acf7283511699b186fb35c356ca62bff417edd90f754da28ebef19c815e42b789f898f79b599f98d5410d8f9de9c2fe0230322dd54421b0a305776c5df3383b9067fd177c2c216d964fc6726982126f54f87a7d1b99cb9b0989216106990f09921d00003182018930820185020101308186307a312e302c06035504030c254170706c65204170706c69636174696f6e20496e746567726174696f6e204341202d20473331263024060355040b0c1d4170706c652043657274696669636174696f6e20417574686f7269747931133011060355040a0c0a4170706c6520496e632e310b300906035504061302555302084c304149519d5436300b0609608648016503040201a08193301806092a864886f70d010903310b06092a864886f70d010701301c06092a864886f70d010905310f170d3233313031393038323434315a302806092a864886f70d010934311b3019300b0609608648016503040201a10a06082a8648ce3d040302302f06092a864886f70d0109043122042045d7f05fe5027dd3b0cdc8e1d6a18ca063961bae1e7192d372f1eecf6ef3e2a2300a06082a8648ce3d0403020448304602210080da8154186599149aa93348594129f375b50b9624df9e7d1a6c2aa205087e10022100b0a0ba4b18723ba3cc6595dec6c9f36784e3d6e04ec24179d10c94714f227f1c000000000000",
                      "operational_analytics_identifier": "checkoutapple:76B79A8E91F4D365B0B636C8F75CB207D52532E82C2C085DE79D6D8135EF3813",
                      "retries": 0,
                      "psp_id": "76B79A8E91F4D365B0B636C8F75CB207D52532E82C2C085DE79D6D8135EF3813"
                  },
                  "payment_request_data": {
                      "country_code": "US",
                      "currency_code": "USD",
                      "total": {
                          "label": "apple",
                          "type": "final",
                          "amount": "65.41"
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
                      "merchant_identifier": "merchant.com.hyperswitch.checkout"
                  },
                  "connector": "checkout",
                  "delayed_session_token": false,
                  "sdk_next_action": {
                      "next_action": "confirm"
                  },
                  "connector_reference_id": null,
                  "connector_sdk_public_key": null,
                  "connector_merchant_id": null
              },
              {
                  "wallet_name": "google_pay",
                  "merchant_info": {
                      "merchant_name": "gpay"
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
                              ]
                          },
                          "tokenization_specification": {
                              "type": "PAYMENT_GATEWAY",
                              "parameters": {
                                  "gateway": "checkoutltd",
                                  "gateway_merchant_id": "pk_sbox_wdgpgj6igt2xynjl76sbqe3gru5"
                              }
                          }
                      }
                  ],
                  "transaction_info": {
                      "country_code": "US",
                      "currency_code": "USD",
                      "total_price_status": "Final",
                      "total_price": "65.41"
                  },
                  "delayed_session_token": false,
                  "connector": "checkout",
                  "sdk_next_action": {
                      "next_action": "confirm"
                  },
                  "secrets": null
              }
          ]
      }`->JSON.parseExn
