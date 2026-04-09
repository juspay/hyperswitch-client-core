import { renderHook } from '@testing-library/react-native';

const mockUsePayButton = jest.fn(() => [jest.fn(), jest.fn()]);

jest.mock('../hooks/ButtonHook/ButtonHookImpl', () => ({
  usePayButton: () => mockUsePayButton(),
}));

const { usePayButton, useProcessPayButtonResult } = require('../hooks/ButtonHook/ButtonHook.bs.js');

describe('ButtonHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('usePayButton', () => {
    it('calls usePayButton from ButtonHookImpl', () => {
      renderHook(() => usePayButton());

      expect(mockUsePayButton).toHaveBeenCalled();
    });

    it('returns the result from ButtonHookImpl.usePayButton', () => {
      const mockAddApplePay = jest.fn();
      const mockAddGooglePay = jest.fn();
      mockUsePayButton.mockReturnValue([mockAddApplePay, mockAddGooglePay]);

      const { result } = renderHook(() => usePayButton());

      expect(result.current).toEqual([mockAddApplePay, mockAddGooglePay]);
    });

    it('can be called with configuration parameter', () => {
      const config = { someConfig: 'value' };

      renderHook(() => usePayButton(config));

      expect(mockUsePayButton).toHaveBeenCalled();
    });
  });

  describe('useProcessPayButtonResult', () => {
    it('returns a function', () => {
      const { result } = renderHook(() => useProcessPayButtonResult());

      expect(typeof result.current).toBe('function');
    });

    describe('GOOGLE_PAY wallet type', () => {
      it('returns Success for valid Google Pay payment with no error', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: JSON.stringify({
            paymentMethodData: {
              description: 'Visa •••• 1234',
              info: {
                cardNetwork: 'VISA',
                cardDetails: '1234',
                billingAddress: {
                  name: 'John Doe',
                  address1: '123 Main St',
                  city: 'San Francisco',
                  countryCode: 'US',
                  postalCode: '94102'
                }
              },
              tokenizationData: {
                type: 'PAYMENT_GATEWAY',
                token: 'eyJ0b2tlbiI6ICJleUpoYkdjaU9pSlNVekkxTmlJc0luUjVjQ0k2SWtwWFZDSXNJblZqZGlJNklqSTFOa3NpWlhOMElqcGJJbWgwZEhCek9pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUkrUEhKbFkzUWdkMmxrZEdnOUlqSTFOa3NpWlhOMElqcGJJbWgwZEhCek9pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUkrUEhKbFkzUWdkMmxrZEdnOUlqSTFOaUk2ZXlKa1pXZHljanA5SW1OeWFXZHpVMlZ5ZG1WeUlqcG1ZV3h6WlNJNklsZHpRMHRRTHo0aUx6NDhMM1JsZUhRK1BIaHpRMHRRTHo0aUx6NDhMM1JwZEd4bGJXVnVkSEo1T2lKa2FYSndZWEprWlhKQmJHOTNVM1J2YTJWdUlpd2ljR2h5WldGa0lpOTJNVDB5TFRBd0xURXdWREZkVDB4RVFWbEZVMFZGVDB4RVFWbEZVMFZGU1UxQlVVTm9WVlJTWjJVeFZVWnpkMUZVUWtsTlZHc3hUVDA9In19'
              }
            },
            shippingAddress: {
              name: 'John Doe',
              address1: '456 Oak St',
              city: 'Los Angeles',
              countryCode: 'US',
              postalCode: '90001'
            }
          }),
          error: ''
        };

        const processResult = result.current('GOOGLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toBeDefined();
        expect(processResult._1).toBeDefined();
        expect(processResult._2).toBeDefined();
      });

      it('returns Cancelled when error is "Cancel"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: '',
          error: 'Cancel'
        };

        const processResult = result.current('GOOGLE_PAY', paymentData);

        expect(processResult).toBe('Cancelled');
      });

      it('returns Failed for other errors', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: '',
          error: 'DEVELOPER_ERROR'
        };

        const processResult = result.current('GOOGLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('DEVELOPER_ERROR');
      });
    });

    describe('APPLE_PAY wallet type', () => {
      it('returns Cancelled when status is "Cancelled"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Cancelled'
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toBe('Cancelled');
      });

      it('returns Failed when status is "Error"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Error'
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('Error');
      });

      it('returns Failed when status is "Failed"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Failed'
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('Failed');
      });

      it('returns Simulated for simulated transaction identifier', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Success',
          transaction_identifier: 'Simulated Identifier',
          payment_data: 'encrypted_payment_data',
          payment_method: {
            displayName: 'Visa 1234',
            network: 'Visa',
            type: 'debit'
          }
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toBe('Simulated');
      });

      it('returns Success for valid Apple Pay payment', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Success',
          transaction_identifier: 'ABC123DEF456',
          payment_data: 'encrypted_payment_data_base64',
          payment_method: {
            displayName: 'Visa 1234',
            network: 'Visa',
            type: 'debit'
          },
          billing_contact: {
            name: {
              givenName: 'John',
              familyName: 'Doe'
            },
            postalAddress: {
              street: '123 Main St',
              city: 'San Francisco',
              state: 'CA',
              postalCode: '94102',
              isoCountryCode: 'US'
            },
            emailAddress: 'john@example.com',
            phoneNumber: '+1234567890'
          },
          shipping_contact: {
            name: {
              givenName: 'John',
              familyName: 'Doe'
            },
            postalAddress: {
              street: '456 Oak St\nApt 2',
              city: 'Los Angeles',
              state: 'CA',
              postalCode: '90001',
              isoCountryCode: 'US'
            },
            emailAddress: 'john@example.com',
            phoneNumber: '+1234567890'
          }
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toBeDefined();
        expect(processResult._0).toHaveProperty('payment_data');
        expect(processResult._0).toHaveProperty('payment_method');
        expect(processResult._0).toHaveProperty('transaction_identifier');
        expect(processResult._1).toBeDefined();
        expect(processResult._2).toBeDefined();
      });

      it('handles missing optional fields in Apple Pay payment', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Approved',
          transaction_identifier: 'REAL_TRANSACTION_ID',
          payment_data: 'encrypted_data',
          payment_method: null
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
      });
    });

    describe('PAYPAL wallet type', () => {
      it('returns Success for valid PayPal payment with no error', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: 'PAYPAL_TOKEN_12345',
          error: ''
        };

        const processResult = result.current('PAYPAL', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toHaveProperty('token', 'PAYPAL_TOKEN_12345');
        expect(processResult._1).toBeUndefined();
        expect(processResult._2).toBeUndefined();
      });

      it('returns Cancelled when error is "User has canceled"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: '',
          error: 'User has canceled'
        };

        const processResult = result.current('PAYPAL', paymentData);

        expect(processResult).toBe('Cancelled');
      });

      it('returns Failed for other PayPal errors', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: '',
          error: 'NETWORK_ERROR'
        };

        const processResult = result.current('PAYPAL', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('NETWORK_ERROR');
      });
    });

    describe('SAMSUNG_PAY wallet type', () => {
      it('returns Success for valid Samsung Pay payment', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'success',
          message: JSON.stringify({
            payment_card_brand: 'VISA',
            payment_last4_fpan: '1234',
            method: 'card',
            recurring_payment: false,
            '3DS': {
              type: '3DS',
              version: '2.0',
              data: 'encrypted_3ds_data'
            }
          })
        };

        const processResult = result.current('SAMSUNG_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toBeDefined();
        expect(processResult._1).toBeUndefined();
        expect(processResult._2).toBeUndefined();
      });

      it('returns Failed when status is not "success"', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'failed',
          message: 'Payment was declined by the issuer'
        };

        const processResult = result.current('SAMSUNG_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('Payment was declined by the issuer');
      });

      it('returns Failed with empty message when status is not "success" and message is empty', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'cancelled',
          message: ''
        };

        const processResult = result.current('SAMSUNG_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('');
      });
    });

    describe('NONE wallet type', () => {
      it('returns Cancelled', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const processResult = result.current('NONE', {});

        expect(processResult).toBe('Cancelled');
      });
    });

    describe('edge cases', () => {
      it('handles GOOGLE_PAY with valid JSON payment data', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: JSON.stringify({
            paymentMethodData: {
              description: 'Visa',
              info: {},
              tokenizationData: { type: 'PAYMENT_GATEWAY', token: 'test' }
            }
          }),
          error: ''
        };

        const processResult = result.current('GOOGLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
      });

      it('handles PAYPAL with empty token', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          paymentMethodData: '',
          error: ''
        };

        const processResult = result.current('PAYPAL', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toHaveProperty('token', '');
      });

      it('handles SAMSUNG_PAY with empty status returns Failed', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: '',
          message: ''
        };

        const processResult = result.current('SAMSUNG_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Failed');
        expect(processResult._0).toBe('');
      });

      it('handles SAMSUNG_PAY with success status and valid JSON message', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'success',
          message: JSON.stringify({
            payment_card_brand: 'VISA',
            payment_last4_fpan: '4242',
            method: 'card',
            recurring_payment: false
          })
        };

        const processResult = result.current('SAMSUNG_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
      });

      it('handles APPLE_PAY with valid success status', () => {
        const { result } = renderHook(() => useProcessPayButtonResult());

        const paymentData = {
          status: 'Success',
          transaction_identifier: 'REAL_ID_NOT_SIMULATED',
          payment_data: 'data',
          payment_method: {}
        };

        const processResult = result.current('APPLE_PAY', paymentData);

        expect(processResult).toHaveProperty('TAG', 'Success');
        expect(processResult._0).toHaveProperty('transaction_identifier', 'REAL_ID_NOT_SIMULATED');
      });
    });
  });
});
