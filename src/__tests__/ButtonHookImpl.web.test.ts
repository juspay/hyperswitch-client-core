import { renderHook, act } from '@testing-library/react-native';
import React from 'react';
import * as NativePropContext from '../contexts/NativePropContext.bs.js';

const mockNativeProp = {
  env: 'test',
  configuration: {
    appearance: {
      googlePay: {
        buttonType: 'BUY',
      },
      applePay: {
        buttonType: 'buy',
      },
    },
  },
};

const mockLaunchGPay = jest.fn();
const mockLaunchApplePay = jest.fn();
let mockUseScriptReturnValue = 'idle';
let mockGooglePayButtonColor = 'light';
let mockApplePayButtonColor = 'black';
let mockButtonBorderRadius = 8;
const mockUseScript = jest.fn((src: string) => mockUseScriptReturnValue);

jest.mock('../hooks/WebKit.bs.js', () => ({
  useWebKit: () => ({
    exitPaymentSheet: jest.fn(),
    sdkInitialised: jest.fn(),
    launchApplePay: mockLaunchApplePay,
    launchGPay: mockLaunchGPay,
  }),
  platform: 'web',
}));

jest.mock('../hooks/ThemebasedStyle.bs.js', () => ({
  useThemeBasedStyle: () => ({
    get googlePayButtonColor() { return mockGooglePayButtonColor; },
    get applePayButtonColor() { return mockApplePayButtonColor; },
    get buttonBorderRadius() { return mockButtonBorderRadius; },
  }),
}));

jest.mock('../utility/logics/Window.bs.js', () => ({
  useScript: (src: string) => mockUseScript(src),
}));

jest.mock('../types/WalletType.bs.js', () => ({
  getGpayToken: jest.fn(() => ({ environment: 'Test' })),
  getGpayTokenStringified: jest.fn(() => '{}'),
}));

const { usePayButton } = require('../hooks/ButtonHook/ButtonHookImpl.web.bs.js');

describe('ButtonHookImpl.web', () => {
  let originalDocument: any;
  let originalWindow: any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockUseScriptReturnValue = 'idle';
    mockGooglePayButtonColor = 'light';
    mockApplePayButtonColor = 'black';
    mockButtonBorderRadius = 8;

    originalDocument = global.document;
    originalWindow = global.window;

    global.document = {
      querySelector: jest.fn(() => ({
        innerHTML: '',
        appendChild: jest.fn(),
        setAttribute: jest.fn(),
        removeAttribute: jest.fn(),
        onclick: null,
      })),
      createElement: jest.fn(() => ({
        src: '',
        async: false,
        setAttribute: jest.fn(),
        removeAttribute: jest.fn(),
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
        appendChild: jest.fn(),
      })),
      head: {
        appendChild: jest.fn(),
      },
    } as any;

    (global as any).google = {
      payments: {
        api: {
          PaymentsClient: jest.fn(() => ({
            createButton: jest.fn(() => ({})),
          })),
        },
      },
    };

    (global as any).window = {
      ...(global as any).window,
      google: (global as any).google,
      parent: {
        postMessage: jest.fn(),
      },
    };
  });

  afterEach(() => {
    global.document = originalDocument;
    global.window = originalWindow;
    delete (global as any).google;
  });

  const createWrapper = () => {
    return ({ children }: { children: React.ReactNode }) => {
      const contextValue = [mockNativeProp, jest.fn()];
      return React.createElement(
        NativePropContext.nativePropContext.Provider,
        { value: contextValue },
        children
      );
    };
  };

  describe('usePayButton', () => {
    it('exists as a function', () => {
      expect(usePayButton).toBeDefined();
      expect(typeof usePayButton).toBe('function');
    });

    it('returns an array with two functions', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(Array.isArray(result.current)).toBe(true);
      expect(result.current.length).toBe(2);
      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('returns addApplePay and addGooglePay functions', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay, addGooglePay] = result.current;

      expect(typeof addApplePay).toBe('function');
      expect(typeof addGooglePay).toBe('function');
    });

    it('addApplePay can be called with session object', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay] = result.current;

      const sessionObject = {
        session_token_data: 'token123',
        payment_request_data: 'requestData',
      };

      expect(() => addApplePay(sessionObject, undefined)).not.toThrow();
    });

    it('addGooglePay can be called with session object', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [, addGooglePay] = result.current;

      const sessionObject = {
        session_token: 'gpay_token',
      };

      expect(() => addGooglePay(sessionObject)).not.toThrow();
    });

    it('handles empty session objects', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay({}, undefined)).not.toThrow();
      expect(() => addGooglePay({})).not.toThrow();
    });

    it('handles null arguments gracefully', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay(null, null)).not.toThrow();
      expect(() => addGooglePay(null)).not.toThrow();
    });

    it('handles undefined arguments gracefully', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay(undefined, undefined)).not.toThrow();
      expect(() => addGooglePay(undefined)).not.toThrow();
    });

    it('returns consistent array length on re-render', () => {
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      expect(result.current.length).toBe(2);

      rerender({});

      expect(result.current.length).toBe(2);
    });

    it('handles complex session objects', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay, addGooglePay] = result.current;

      const complexSession = {
        session_token_data: {
          merchantIdentifier: 'merchant.com.example',
          displayName: 'Test Merchant',
          initiativeContext: 'example.com',
        },
        payment_request_data: {
          countryCode: 'US',
          currencyCode: 'USD',
          supportedNetworks: ['visa', 'masterCard'],
          merchantCapabilities: ['supports3DS'],
          total: {
            label: 'Total',
            amount: '10.00',
          },
        },
      };

      expect(() => addApplePay(complexSession, undefined)).not.toThrow();
      expect(() => addGooglePay(complexSession)).not.toThrow();
    });
  });

  describe('Google Pay button setup', () => {
    it('does not throw when script is not ready', () => {
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(result.current.length).toBe(2);
    });

    it('handles adding Google Pay session when script is ready', () => {
      mockUseScriptReturnValue = 'ready';
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [, addGooglePay] = result.current;

      expect(() => {
        act(() => {
          addGooglePay({ session_token: 'test_token' });
        });
      }).not.toThrow();
    });

    it('creates Google Pay button when script becomes ready after session is set', () => {
      const mockGooglePayButton = { buttonElement: true };
      const mockCreateButton = jest.fn(() => mockGooglePayButton);
      const mockPaymentsClient = jest.fn(() => ({
        createButton: mockCreateButton,
      }));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: mockPaymentsClient,
          },
        },
      };

      const mockContainer = {
        innerHTML: 'old',
        appendChild: jest.fn(),
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockContainer);

      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      const [, addGooglePay] = result.current;

      act(() => {
        addGooglePay({ session_token: 'test_token' });
      });

      expect(mockCreateButton).not.toHaveBeenCalled();

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockPaymentsClient).toHaveBeenCalledWith('Test');
      expect(mockCreateButton).toHaveBeenCalled();
      expect(mockContainer.innerHTML).toBe('');
      expect(mockContainer.appendChild).toHaveBeenCalledWith(mockGooglePayButton);
    });

    it('creates Google Pay button with correct button type BOOK', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithBookType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithBook = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BOOK' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithBook, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithBookType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'book' })
      );
    });

    it('creates Google Pay button with correct button type CHECKOUT', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithCheckoutType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithCheckout = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'CHECKOUT' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithCheckout, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithCheckoutType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'checkout' })
      );
    });

    it('creates Google Pay button with correct button type DONATE', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithDonateType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithDonate = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'DONATE' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithDonate, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithDonateType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'donate' })
      );
    });

    it('creates Google Pay button with correct button type ORDER', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithOrderType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithOrder = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'ORDER' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithOrder, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithOrderType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'order' })
      );
    });

    it('creates Google Pay button with correct button type PAY', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithPayType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithPay = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'PAY' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithPay, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithPayType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'pay' })
      );
    });

    it('creates Google Pay button with correct button type SUBSCRIBE', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithSubscribeType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithSubscribe = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'SUBSCRIBE' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithSubscribe, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithSubscribeType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'subscribe' })
      );
    });

    it('creates Google Pay button with correct button type PLAIN', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      const wrapperWithPlainType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithPlain = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'PLAIN' },
              applePay: { buttonType: 'buy' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithPlain, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithPlainType });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonType: 'plain' })
      );
    });

    it('creates Google Pay button with light button color when googlePayButtonColor is light', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      mockGooglePayButtonColor = 'light';
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonColor: 'white' })
      );
    });

    it('creates Google Pay button with black button color when googlePayButtonColor is dark', () => {
      const mockCreateButton = jest.fn(() => ({}));
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      mockGooglePayButtonColor = 'dark';
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockCreateButton).toHaveBeenCalledWith(
        expect.objectContaining({ buttonColor: 'black' })
      );
    });

    it('calls launchGPay when Google Pay button onClick is triggered', () => {
      let capturedOnClick: (() => void) | null = null;
      const mockCreateButton = jest.fn((props: any) => {
        capturedOnClick = props.onClick;
        return {};
      });
      (global as any).google = {
        payments: {
          api: {
            PaymentsClient: jest.fn(() => ({ createButton: mockCreateButton })),
          },
        },
      };
      (global.document.querySelector as jest.Mock).mockReturnValue({
        innerHTML: '',
        appendChild: jest.fn(),
      });

      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[1]({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(capturedOnClick).not.toBeNull();
      act(() => {
        capturedOnClick!();
      });

      expect(mockLaunchGPay).toHaveBeenCalled();
    });
  });

  describe('Apple Pay button setup', () => {
    it('handles Apple Pay session object with valid data', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay] = result.current;

      const sessionObject = {
        session_token_data: {
          merchantIdentifier: 'merchant.com.example',
        },
        payment_request_data: {
          countryCode: 'US',
          currencyCode: 'USD',
        },
      };

      expect(() => {
        act(() => {
          addApplePay(sessionObject, undefined);
        });
      }).not.toThrow();
    });

    it('creates Apple Pay button when script becomes ready after session is set', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay] = result.current;

      act(() => {
        addApplePay({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      expect(mockApplePayButton.removeAttribute).not.toHaveBeenCalled();

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('hidden');
      expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('aria-hidden');
      expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('disabled');
      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'black');
      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'buy');
      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('locale', 'en-US');
    });

    it('sets Apple Pay button type to plain', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithPlainType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithPlain = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'plain' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithPlain, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithPlainType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'plain');
    });

    it('sets Apple Pay button type to setUp', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithSetUpType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithSetUp = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'setUp' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithSetUp, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithSetUpType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'setUp');
    });

    it('sets Apple Pay button type to subscribe', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithSubscribeType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithSubscribe = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'subscribe' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithSubscribe, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithSubscribeType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'subscribe');
    });

    it('sets Apple Pay button type to inStore', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithInStoreType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithInStore = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'inStore' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithInStore, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithInStoreType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'inStore');
    });

    it('sets Apple Pay button type to checkout', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithCheckoutType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithCheckout = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'checkout' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithCheckout, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithCheckoutType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'checkout');
    });

    it('sets Apple Pay button type to donate', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithDonateType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithDonate = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'donate' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithDonate, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithDonateType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'donate');
    });

    it('sets Apple Pay button type to book as default fallback', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      const wrapperWithUnknownType = ({ children }: { children: React.ReactNode }) => {
        const nativePropWithUnknown = {
          env: 'test',
          configuration: {
            appearance: {
              googlePay: { buttonType: 'BUY' },
              applePay: { buttonType: 'unknownType' },
            },
          },
        };
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: [nativePropWithUnknown, jest.fn()] },
          children
        );
      };

      mockUseScriptReturnValue = 'loading';
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper: wrapperWithUnknownType });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'book');
    });

    it('sets Apple Pay button style to white-outline', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      mockApplePayButtonColor = 'whiteOutline';
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'white-outline');
    });

    it('sets Apple Pay button style to white', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      mockApplePayButtonColor = 'white';
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'white');
    });

    it('calls launchApplePay when Apple Pay button is clicked', () => {
      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      const sessionObject = {
        session_token_data: 'session_token_value',
        payment_request_data: 'payment_request_value',
      };

      act(() => {
        result.current[0](sessionObject, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(mockApplePayButton.onclick).not.toBeNull();

      act(() => {
        mockApplePayButton.onclick();
      });

      expect(mockLaunchApplePay).toHaveBeenCalled();
      const calledArg = mockLaunchApplePay.mock.calls[0][0];
      expect(calledArg).toContain('session_token_data');
      expect(calledArg).toContain('session_token_value');
      expect(calledArg).toContain('payment_request_data');
      expect(calledArg).toContain('payment_request_value');
    });

    it('handles error when Apple Pay button click throws', () => {
      const mockAlert = jest.fn();
      (global as any).alert = mockAlert;

      const mockApplePayButton = {
        removeAttribute: jest.fn(),
        setAttribute: jest.fn(),
        onclick: null,
      };
      (global.document.querySelector as jest.Mock).mockReturnValue(mockApplePayButton);

      mockLaunchApplePay.mockImplementation(() => {
        throw new Error('Apple Pay error');
      });

      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[0]({ session_token_data: 'token', payment_request_data: 'req' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(() => {
        act(() => {
          mockApplePayButton.onclick();
        });
      }).not.toThrow();

      expect(mockAlert).toHaveBeenCalled();
    });
  });

  describe('edge cases', () => {
    it('handles multiple calls to addGooglePay', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [, addGooglePay] = result.current;

      expect(() => {
        act(() => {
          addGooglePay({ session_token: 'test1' });
          addGooglePay({ session_token: 'test2' });
        });
      }).not.toThrow();
    });

    it('handles multiple calls to addApplePay', () => {
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay] = result.current;

      expect(() => {
        act(() => {
          addApplePay({ session_token_data: 'test1' }, undefined);
          addApplePay({ session_token_data: 'test2' }, undefined);
        });
      }).not.toThrow();
    });

    it('handles script status idle', () => {
      mockUseScriptReturnValue = 'idle';
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(result.current.length).toBe(2);
    });

    it('handles script status error', () => {
      mockUseScriptReturnValue = 'error';
      const wrapper = createWrapper();
      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(result.current.length).toBe(2);
    });

    it('handles null querySelector result for Google Pay container', () => {
      (global.document.querySelector as jest.Mock).mockReturnValue(null);
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      const [, addGooglePay] = result.current;

      act(() => {
        addGooglePay({ session_token: 'test' });
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(result.current.length).toBe(2);
    });

    it('handles null querySelector result for Apple Pay button', () => {
      (global.document.querySelector as jest.Mock).mockReturnValue(null);
      mockUseScriptReturnValue = 'loading';
      const wrapper = createWrapper();
      const { result, rerender } = renderHook(() => usePayButton(), { wrapper });

      const [addApplePay] = result.current;

      act(() => {
        addApplePay({ session_token_data: 'test' }, undefined);
      });

      mockUseScriptReturnValue = 'ready';
      rerender({});

      expect(result.current.length).toBe(2);
    });
  });
});
