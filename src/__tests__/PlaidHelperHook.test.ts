import { renderHook, act, waitFor } from '@testing-library/react-native';
import React from 'react';

jest.mock('../components/modules/Plaid/Plaid.bs.js', () => ({
  dismissLink: jest.fn(),
  create: jest.fn(),
  open_: jest.fn(() => Promise.resolve()),
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getDictFromJson: jest.fn((json) => {
    if (typeof json === 'string') {
      try {
        return JSON.parse(json);
      } catch {
        return {};
      }
    }
    return json || {};
  }),
}));

const mockNativePropContext = React.createContext([{}, jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

const createMockNativeProp = (overrides = {}) => ({
  publishableKey: 'pk_test_123',
  clientSecret: 'pi_123_secret_456',
  paymentMethodId: 'pi_123',
  ephemeralKey: undefined,
  customBackendUrl: undefined,
  customLogUrl: undefined,
  sessionId: 'session_123',
  from: 'native',
  configuration: {},
  env: 'sandbox',
  sdkState: 'PaymentSheet',
  rootTag: 1,
  hyperParams: {
    confirm: false,
    appId: 'test-app',
    country: 'US',
    sdkVersion: '1.0.0',
  },
  customParams: {},
  ...overrides,
});

const { usePlaidProps } = require('../hooks/PlaidHelperHook.bs.js');

describe('PlaidHelperHook', () => {
  let mockRetrievePayment: jest.Mock;
  let mockResponseCallback: jest.Mock;
  let mockErrorCallback: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    mockRetrievePayment = jest.fn();
    mockResponseCallback = jest.fn();
    mockErrorCallback = jest.fn();
  });

  describe('usePlaidProps', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function when called', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns an object with onSuccess and onExit handlers', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      expect(props).toHaveProperty('onSuccess');
      expect(props).toHaveProperty('onExit');
      expect(typeof props.onSuccess).toBe('function');
      expect(typeof props.onExit).toBe('function');
    });

    it('onSuccess calls retrievePayment with correct parameters', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'succeeded' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: '{"test": "data"}',
          status: 'success',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      expect(mockRetrievePayment).toHaveBeenCalledWith(
        'Payment',
        'pi_123_secret_456',
        'pk_test_123',
        true
      );
    });

    it('onSuccess calls responseCallback with PaymentSuccess for succeeded status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'succeeded' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'success message',
          status: 'success',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'PaymentSuccess',
          expect.objectContaining({
            message: 'success message',
          })
        );
      });
    });

    it('onSuccess calls responseCallback with PaymentSuccess for processing status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'processing' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'processing',
          status: 'processing',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'PaymentSuccess',
          expect.objectContaining({
            message: 'processing',
          })
        );
      });
    });

    it('onSuccess calls responseCallback with ProcessingPayments for requires_capture status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'requires_capture' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'requires capture',
          status: 'pending',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'ProcessingPayments',
          expect.objectContaining({
            status: 'requires_capture',
          })
        );
      });
    });

    it('onSuccess calls responseCallback with ProcessingPayments for requires_confirmation status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'requires_confirmation' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'requires confirmation',
          status: 'pending',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'ProcessingPayments',
          expect.objectContaining({
            status: 'requires_confirmation',
          })
        );
      });
    });

    it('onSuccess calls errorCallback for unknown status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'unknown_status' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'unknown',
          status: 'unknown',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockErrorCallback).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Payment is processing. Try again later!',
            type_: 'sync_payment_failed',
            status: 'unknown_status',
          }),
          true,
          undefined
        );
      });
    });

    it('onSuccess calls errorCallback when retrievePayment returns null', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue(null);

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const successData = {
        metadata: {
          metadataJson: 'null test',
          status: 'success',
        },
      };

      await act(async () => {
        await props.onSuccess(successData);
      });

      await waitFor(() => {
        expect(mockErrorCallback).toHaveBeenCalled();
      });
    });

    it('onExit calls dismissLink and errorCallback', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      const { dismissLink } = require('../components/modules/Plaid/Plaid.bs.js');

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      const exitData = {
        error: {
          errorMessage: 'User cancelled',
        },
      };

      act(() => {
        props.onExit(exitData);
      });

      expect(dismissLink).toHaveBeenCalled();
      expect(mockErrorCallback).toHaveBeenCalledWith(
        { message: 'User cancelled' },
        true,
        undefined
      );
    });

    it('onExit handles missing error message', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      act(() => {
        props.onExit({});
      });

      expect(mockErrorCallback).toHaveBeenCalledWith(
        { message: 'unknown error' },
        true,
        undefined
      );
    });

    it('onExit handles undefined error', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      act(() => {
        props.onExit({ error: undefined });
      });

      expect(mockErrorCallback).toHaveBeenCalledWith(
        { message: 'unknown error' },
        true,
        undefined
      );
    });

    it('uses clientSecret from nativeProp', async () => {
      const nativeProp = createMockNativeProp({
        clientSecret: 'custom_secret_789',
      });
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'succeeded' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      await act(async () => {
        await props.onSuccess({
          metadata: { metadataJson: 'test', status: 'success' },
        });
      });

      expect(mockRetrievePayment).toHaveBeenCalledWith(
        'Payment',
        'custom_secret_789',
        'pk_test_123',
        true
      );
    });

    it('uses publishableKey from nativeProp', async () => {
      const nativeProp = createMockNativeProp({
        publishableKey: 'pk_custom_key',
      });
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'succeeded' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      await act(async () => {
        await props.onSuccess({
          metadata: { metadataJson: 'test', status: 'success' },
        });
      });

      expect(mockRetrievePayment).toHaveBeenCalledWith(
        'Payment',
        'pi_123_secret_456',
        'pk_custom_key',
        true
      );
    });

    it('handles requires_merchant_action status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'requires_merchant_action' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      await act(async () => {
        await props.onSuccess({
          metadata: { metadataJson: 'test', status: 'pending' },
        });
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'ProcessingPayments',
          expect.objectContaining({
            status: 'requires_merchant_action',
          })
        );
      });
    });

    it('handles cancelled status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'cancelled' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      await act(async () => {
        await props.onSuccess({
          metadata: { metadataJson: 'test', status: 'cancelled' },
        });
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'ProcessingPayments',
          expect.objectContaining({
            status: 'cancelled',
          })
        );
      });
    });

    it('handles requires_customer_action status', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      mockRetrievePayment.mockResolvedValue({ status: 'requires_customer_action' });

      const { result } = renderHook(() => usePlaidProps(), { wrapper });

      const propsFn = result.current;
      const props = propsFn(mockRetrievePayment, mockResponseCallback, mockErrorCallback);

      await act(async () => {
        await props.onSuccess({
          metadata: { metadataJson: 'customer action', status: 'pending' },
        });
      });

      await waitFor(() => {
        expect(mockResponseCallback).toHaveBeenCalledWith(
          'PaymentSuccess',
          expect.objectContaining({
            message: 'customer action',
          })
        );
      });
    });
  });
});
