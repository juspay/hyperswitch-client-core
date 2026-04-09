import { renderHook, act } from '@testing-library/react-native';
import React from 'react';
import * as NativePropContext from '../contexts/NativePropContext.bs.js';

const mockNativeProp = {
  env: 'SANDBOX',
  configuration: {
    appearance: {
      googlePay: { buttonType: 'PAY' },
      applePay: { buttonType: 'buy' },
    },
  },
};

jest.mock('../hooks/ThemebasedStyle.bs.js', () => ({
  useThemeBasedStyle: jest.fn(() => ({
    googlePayButtonColor: 'dark',
    applePayButtonColor: 'black',
    buttonBorderRadius: 8,
  })),
}));

jest.mock('../hooks/WebKit.bs.js', () => ({
  useWebKit: jest.fn(() => ({
    launchGPay: jest.fn(),
    launchApplePay: jest.fn(),
  })),
  platform: 'web',
}));

const mockUseScriptReturnValue = { current: 'idle' };

jest.mock('../utility/logics/Window.bs.js', () => ({
  useScript: () => mockUseScriptReturnValue.current,
}));

jest.mock('../types/WalletType.bs.js', () => ({
  getGpayToken: jest.fn(() => ({ environment: 'Test' })),
  getGpayTokenStringified: jest.fn(() => '{}'),
}));

const { usePayButton } = require('../hooks/WebButtonHook.bs.js');

describe('WebButtonHook', () => {
  let originalDocument: any;

  beforeEach(() => {
    jest.clearAllMocks();

    originalDocument = global.document;
    global.document = {
      ...originalDocument,
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
        addEventListener: jest.fn(),
        removeEventListener: jest.fn(),
      })),
      head: {
        appendChild: jest.fn(),
      },
    } as any;

    (global as any).google = {
      payments: {
        api: {
          PaymentsClient: jest.fn(() => ({
            createButton: jest.fn(() => document.createElement('div')),
          })),
        },
      },
    };
  });

  afterEach(() => {
    global.document = originalDocument;
    delete (global as any).google;
  });

  describe('usePayButton', () => {
    it('returns addApplePay and addGooglePay functions', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [mockNativeProp, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(result.current).toHaveLength(2);
      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('addApplePay function can be called with session object', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [mockNativeProp, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      const sessionObject = {
        session_token_data: 'token_data',
        payment_request_data: 'request_data',
      };

      act(() => {
        result.current[0](sessionObject, undefined);
      });
    });

    it('addGooglePay function can be called with session object', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [mockNativeProp, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      const sessionObject = {
        merchant_info: { merchantId: '123' },
        allowed_payment_methods: [],
        transaction_info: {},
      };

      act(() => {
        result.current[1](sessionObject);
      });
    });

    it('handles undefined session objects', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [mockNativeProp, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[0](undefined as any, undefined);
      });

      act(() => {
        result.current[1](undefined as any);
      });
    });

    it('handles empty session objects', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [mockNativeProp, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      act(() => {
        result.current[0]({}, undefined);
      });

      act(() => {
        result.current[1]({});
      });
    });

    it('handles native prop with different button types', () => {
      const nativePropWithBuy = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'BUY' },
            applePay: { buttonType: 'SUBSCRIBE' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithBuy, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with BOOK button type', () => {
      const nativePropWithBook = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'BOOK' },
            applePay: { buttonType: 'BOOK' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithBook, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with CHECKOUT button type', () => {
      const nativePropWithCheckout = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'CHECKOUT' },
            applePay: { buttonType: 'CHECKOUT' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithCheckout, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with DONATE button type', () => {
      const nativePropWithDonate = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'DONATE' },
            applePay: { buttonType: 'DONATE' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithDonate, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with ORDER button type', () => {
      const nativePropWithOrder = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'ORDER' },
            applePay: { buttonType: 'PLAIN' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithOrder, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with SUBSCRIBE button type', () => {
      const nativePropWithSubscribe = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'SUBSCRIBE' },
            applePay: { buttonType: 'SUBSCRIBE' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithSubscribe, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles native prop with PLAIN button type', () => {
      const nativePropWithPlain = {
        ...mockNativeProp,
        configuration: {
          appearance: {
            googlePay: { buttonType: 'PLAIN' },
            applePay: { buttonType: 'PLAIN' },
          },
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithPlain, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('handles missing configuration gracefully', () => {
      const nativePropWithoutConfig = {
        env: 'SANDBOX',
        configuration: {
          appearance: {},
        },
      };

      const wrapper = ({ children }: { children: React.ReactNode }) => {
        const contextValue = [nativePropWithoutConfig, jest.fn()];
        return React.createElement(
          NativePropContext.nativePropContext.Provider,
          { value: contextValue },
          children
        );
      };

      const { result } = renderHook(() => usePayButton(), { wrapper });

      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    describe('Google Pay button setup', () => {
      beforeEach(() => {
        mockUseScriptReturnValue.current = 'ready';
      });

      afterEach(() => {
        mockUseScriptReturnValue.current = 'idle';
      });

      it('sets up Google Pay button when session is added and status is ready', () => {
        const mockContainer = {
          innerHTML: 'old content',
          appendChild: jest.fn(),
        };
        const mockButton = document.createElement('div');
        (global.document.querySelector as jest.Mock).mockReturnValue(mockContainer);
        ((global as any).google.payments.api.PaymentsClient as jest.Mock).mockImplementation(() => ({
          createButton: jest.fn(() => mockButton),
        }));

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[1]({ merchant_info: { merchantId: '123' } });
        });

        expect(mockContainer.innerHTML).toBe('');
        expect(mockContainer.appendChild).toHaveBeenCalled();
      });

      it('handles Google Pay button setup with light button color', () => {
        const ThemebasedStyle = require('../hooks/ThemebasedStyle.bs.js');
        ThemebasedStyle.useThemeBasedStyle.mockReturnValue({
          googlePayButtonColor: 'light',
          applePayButtonColor: 'white',
          buttonBorderRadius: 12,
        });

        const mockContainer = {
          innerHTML: '',
          appendChild: jest.fn(),
        };
        (global.document.querySelector as jest.Mock).mockReturnValue(mockContainer);

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[1]({ merchant_info: { merchantId: '123' } });
        });

        expect(mockContainer.appendChild).toHaveBeenCalled();
      });

      it('does not setup Google Pay button when container is null', () => {
        (global.document.querySelector as jest.Mock).mockReturnValue(null);

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[1]({ merchant_info: { merchantId: '123' } });
        });

        expect(global.document.querySelector).toHaveBeenCalledWith('#google-wallet-button-container');
      });

      it('handles different Google Pay button types in ready state', () => {
        const buttonTypes = ['BUY', 'BOOK', 'CHECKOUT', 'DONATE', 'ORDER', 'PAY', 'SUBSCRIBE', 'PLAIN'];
        const ThemebasedStyle = require('../hooks/ThemebasedStyle.bs.js');

        buttonTypes.forEach((buttonType) => {
          const mockContainer = { innerHTML: '', appendChild: jest.fn() };
          (global.document.querySelector as jest.Mock).mockReturnValue(mockContainer);

          const nativePropWithButtonType = {
            ...mockNativeProp,
            configuration: {
              appearance: {
                googlePay: { buttonType },
                applePay: { buttonType: 'BUY' },
              },
            },
          };

          ThemebasedStyle.useThemeBasedStyle.mockReturnValue({
            googlePayButtonColor: 'dark',
            applePayButtonColor: 'black',
            buttonBorderRadius: 8,
          });

          const wrapper = ({ children }: { children: React.ReactNode }) => {
            const contextValue = [nativePropWithButtonType, jest.fn()];
            return React.createElement(
              NativePropContext.nativePropContext.Provider,
              { value: contextValue },
              children
            );
          };

          const { result } = renderHook(() => usePayButton(), { wrapper });

          act(() => {
            result.current[1]({ merchant_info: { merchantId: '123' } });
          });

          expect(mockContainer.appendChild).toHaveBeenCalled();
        });
      });
    });

    describe('Apple Pay button setup', () => {
      let mockApplePayButton: any;

      beforeEach(() => {
        mockUseScriptReturnValue.current = 'ready';
        mockApplePayButton = {
          setAttribute: jest.fn(),
          removeAttribute: jest.fn(),
          onclick: null,
        };
        (global.document.querySelector as jest.Mock).mockImplementation((selector: string) => {
          if (selector === 'apple-pay-button') {
            return mockApplePayButton;
          }
          return null;
        });
      });

      afterEach(() => {
        mockUseScriptReturnValue.current = 'idle';
      });

      it('sets up Apple Pay button when session is added and status is ready', () => {
        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[0]({ session_token_data: 'token', payment_request_data: 'request' }, undefined);
        });

        expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('hidden');
        expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('aria-hidden');
        expect(mockApplePayButton.removeAttribute).toHaveBeenCalledWith('disabled');
        expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'black');
        expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', 'buy');
        expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('locale', 'en-US');
      });

      it('sets up Apple Pay button with white-outline style', () => {
        const ThemebasedStyle = require('../hooks/ThemebasedStyle.bs.js');
        ThemebasedStyle.useThemeBasedStyle.mockReturnValue({
          googlePayButtonColor: 'dark',
          applePayButtonColor: 'whiteOutline',
          buttonBorderRadius: 8,
        });

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[0]({ session_token_data: 'token', payment_request_data: 'request' }, undefined);
        });

        expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'white-outline');
      });

      it('sets up Apple Pay button with white style', () => {
        const ThemebasedStyle = require('../hooks/ThemebasedStyle.bs.js');
        ThemebasedStyle.useThemeBasedStyle.mockReturnValue({
          googlePayButtonColor: 'dark',
          applePayButtonColor: 'white',
          buttonBorderRadius: 8,
        });

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[0]({ session_token_data: 'token', payment_request_data: 'request' }, undefined);
        });

        expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('buttonstyle', 'white');
      });

      it('handles different Apple Pay button types', () => {
        const buttonTypes = [
          { type: 'plain', expected: 'plain' },
          { type: 'setUp', expected: 'setUp' },
          { type: 'buy', expected: 'buy' },
          { type: 'subscribe', expected: 'subscribe' },
          { type: 'inStore', expected: 'inStore' },
          { type: 'checkout', expected: 'checkout' },
          { type: 'donate', expected: 'donate' },
          { type: 'book', expected: 'book' },
        ];

        buttonTypes.forEach(({ type, expected }) => {
          mockApplePayButton.setAttribute.mockClear();
          mockApplePayButton.removeAttribute.mockClear();

          const nativePropWithButtonType = {
            ...mockNativeProp,
            configuration: {
              appearance: {
                googlePay: { buttonType: 'PAY' },
                applePay: { buttonType: type },
              },
            },
          };

          const wrapper = ({ children }: { children: React.ReactNode }) => {
            const contextValue = [nativePropWithButtonType, jest.fn()];
            return React.createElement(
              NativePropContext.nativePropContext.Provider,
              { value: contextValue },
              children
            );
          };

          const { result } = renderHook(() => usePayButton(), { wrapper });

          act(() => {
            result.current[0]({ session_token_data: 'token', payment_request_data: 'request' }, undefined);
          });

          expect(mockApplePayButton.setAttribute).toHaveBeenCalledWith('type', expected);
        });
      });

      it('does not setup Apple Pay button when element is null', () => {
        (global.document.querySelector as jest.Mock).mockReturnValue(null);

        const wrapper = ({ children }: { children: React.ReactNode }) => {
          const contextValue = [mockNativeProp, jest.fn()];
          return React.createElement(
            NativePropContext.nativePropContext.Provider,
            { value: contextValue },
            children
          );
        };

        const { result } = renderHook(() => usePayButton(), { wrapper });

        act(() => {
          result.current[0]({ session_token_data: 'token', payment_request_data: 'request' }, undefined);
        });

        expect(global.document.querySelector).toHaveBeenCalledWith('apple-pay-button');
      });
    });
  });
});
