import { InAppBrowser } from 'react-native-inappbrowser-reborn';

jest.mock('react-native', () => ({
  Platform: { OS: 'web' },
}));

jest.mock('react-native-inappbrowser-reborn', () => ({
  InAppBrowser: {
    isAvailable: jest.fn(() => Promise.resolve(true)),
    openAuth: jest.fn(() => Promise.resolve({ url: null, message: '', type: 'cancel' })),
  },
}));

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'android',
}));

const mockOpenUrl = () => {
  const { openUrl, InAppBrowser: BrowserHookInAppBrowser } = require('../hooks/BrowserHook.bs.js');
  return { openUrl, BrowserHookInAppBrowser };
};

describe('BrowserHook', () => {
  describe('InAppBrowser export', () => {
    it('exports an empty InAppBrowser object', () => {
      const { BrowserHookInAppBrowser } = mockOpenUrl();
      expect(BrowserHookInAppBrowser).toEqual({});
    });
  });

  describe('openUrl', () => {
    let originalWindow: any;
    let mockWindowOpen: jest.Mock;
    let capturedCallbacks: { interval: Function | null };

    beforeEach(() => {
      jest.clearAllMocks();
      capturedCallbacks = { interval: null };
      mockWindowOpen = jest.fn(() => ({
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      }));

      originalWindow = global.window;
      global.window = {
        open: mockWindowOpen,
        clearInterval: jest.fn(),
        addEventListener: jest.fn(),
      } as any;

      global.setInterval = jest.fn((cb: any, _ms: number) => {
        capturedCallbacks.interval = cb;
        return 123;
      }) as any;
    });

    afterEach(() => {
      global.window = originalWindow;
    });

    it('opens URL in new tab on web platform', () => {
      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      openUrl(url, returnUrl, intervalId, false, appearance);

      expect(mockWindowOpen).toHaveBeenCalledWith(url);
    });

    it('resolves with success status when URL contains status=succeeded', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      expect(capturedCallbacks.interval).toBeDefined();
      mockTab.location.href = 'https://example.com/callback?status=succeeded&payment_id=pay123&amount=100';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Success');
      expect(result).toHaveProperty('paymentID', 'pay123');
      expect(result).toHaveProperty('amount', '100');
    });

    it('resolves with cancel status when tab is closed without status', async () => {
      const mockTab = {
        closed: true,
        close: jest.fn(),
        location: { href: 'https://example.com/callback' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Cancel');
    });

    it('resolves with failed status when URL contains status=failed', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      mockTab.location.href = 'https://example.com/callback?status=failed&payment_id=pay123&amount=100';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Failed');
      expect(result).toHaveProperty('paymentID', 'pay123');
    });

    it('resolves with success status when URL contains status=processing', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      mockTab.location.href = 'https://example.com/callback?status=processing&payment_id=pay456&amount=200';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Success');
    });

    it('handles requires_capture status as success', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      mockTab.location.href = 'https://example.com/callback?status=requires_capture&payment_id=pay789&amount=300';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Success');
    });

    it('handles requires_payment_method status as failed', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      mockTab.location.href = 'https://example.com/callback?status=requires_payment_method&payment_id=pay111&amount=400';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Failed');
    });

    it('handles partially_captured status as success', async () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      const promise = openUrl(url, returnUrl, intervalId, false, appearance);

      mockTab.location.href = 'https://example.com/callback?status=partially_captured&payment_id=pay222&amount=500';
      capturedCallbacks.interval!();

      const result = await promise;
      expect(result).toHaveProperty('status', 'Success');
    });

    it('handles exception when accessing cross-origin location', async () => {
      const mockTab: any = {
        closed: false,
        close: jest.fn(),
      };
      Object.defineProperty(mockTab, 'location', {
        get() {
          throw new Error('Security error');
        },
      });
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      openUrl(url, returnUrl, intervalId, false, appearance);

      expect(() => capturedCallbacks.interval!()).not.toThrow();
    });

    it('handles null newTab gracefully', () => {
      mockWindowOpen.mockReturnValue(null);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      openUrl(url, returnUrl, intervalId, false, appearance);

      expect(mockWindowOpen).toHaveBeenCalledWith(url);
    });

    it('uses ephemeral web session when enabled', () => {
      const mockTab = {
        closed: false,
        close: jest.fn(),
        location: { href: '' },
      };
      mockWindowOpen.mockReturnValue(mockTab);

      const { openUrl } = mockOpenUrl();
      const url = 'https://example.com/payment';
      const returnUrl = 'https://example.com/callback';
      const intervalId = { current: null };
      const appearance = { colors: undefined, theme: 'Light' };

      openUrl(url, returnUrl, intervalId, true, appearance);

      expect(mockWindowOpen).toHaveBeenCalledWith(url);
    });
  });
});
