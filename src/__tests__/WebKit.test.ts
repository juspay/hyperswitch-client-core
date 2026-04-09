import { renderHook } from '@testing-library/react-native';

const originalWindow = global.window;

function setupReactNativePlatform(os: string) {
  const ReactNative = require('react-native');
  ReactNative.Platform.OS = os;
  return ReactNative;
}

function setupWindowWebKit() {
  const win = {
    webkit: {
      messageHandlers: {
        exitPaymentSheet: { postMessage: jest.fn() },
        sdkInitialised: { postMessage: jest.fn() },
        launchApplePay: { postMessage: jest.fn() }
      }
    },
    parent: { postMessage: jest.fn() }
  };
  Object.defineProperty(global, 'window', {
    value: win,
    writable: true,
    configurable: true
  });
  return win;
}

function setupWindowAndroidInterface() {
  const win = {
    HSAndroidInterface: { postMessage: jest.fn() },
    parent: { postMessage: jest.fn() }
  };
  Object.defineProperty(global, 'window', {
    value: win,
    writable: true,
    configurable: true
  });
  return win;
}

function setupWindowWebOnly() {
  const win = {
    parent: { postMessage: jest.fn() }
  };
  Object.defineProperty(global, 'window', {
    value: win,
    writable: true,
    configurable: true
  });
  return win;
}

describe('WebKit', () => {
  afterAll(() => {
    global.window = originalWindow;
  });

  describe('platform detection', () => {
    it('exports platform as a string', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      setupWindowWebOnly();
      const { platform } = require('../hooks/WebKit.bs.js');
      expect(typeof platform).toBe('string');
    });

    it('exports platformString as a string', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      setupWindowWebOnly();
      const { platformString } = require('../hooks/WebKit.bs.js');
      expect(typeof platformString).toBe('string');
    });
  });

  describe('useWebKit hook - web platform', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };
    let platform: string;
    let mockParentPostMessage: jest.Mock;

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = setupWindowWebOnly();
      mockParentPostMessage = win.parent.postMessage as jest.Mock;
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
      platform = mod.platform;
    });

    it('platform should be web when no webkit/android interface', () => {
      expect(platform).toBe('web');
    });

    it('returns an object with all expected functions', () => {
      const { result } = renderHook(() => useWebKit());
      
      expect(result.current).toHaveProperty('exitPaymentSheet');
      expect(result.current).toHaveProperty('sdkInitialised');
      expect(result.current).toHaveProperty('launchApplePay');
      expect(result.current).toHaveProperty('launchGPay');
      expect(typeof result.current.exitPaymentSheet).toBe('function');
      expect(typeof result.current.sdkInitialised).toBe('function');
      expect(typeof result.current.launchApplePay).toBe('function');
      expect(typeof result.current.launchGPay).toBe('function');
    });

    it('exitPaymentSheet calls window.parent.postMessage on web platform', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('test-message');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('test-message', '*');
    });

    it('sdkInitialised calls window.parent.postMessage on web platform', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.sdkInitialised('init-data');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('init-data', '*');
    });

    it('launchGPay calls window.parent.postMessage on web platform', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.launchGPay('gpay-data');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('gpay-data', '*');
    });

    it('launchApplePay returns early when not iosWebView platform', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.launchApplePay('apple-pay-data');
      
      expect(mockParentPostMessage).not.toHaveBeenCalled();
    });

    it('exitPaymentSheet handles empty string', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('', '*');
    });

    it('exitPaymentSheet handles JSON string', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('{"status":"success"}');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('{"status":"success"}', '*');
    });

    it('can call multiple functions in sequence', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('exit');
      result.current.sdkInitialised('init');
      result.current.launchGPay('gpay');
      
      expect(mockParentPostMessage).toHaveBeenCalledTimes(3);
      expect(mockParentPostMessage).toHaveBeenNthCalledWith(1, 'exit', '*');
      expect(mockParentPostMessage).toHaveBeenNthCalledWith(2, 'init', '*');
      expect(mockParentPostMessage).toHaveBeenNthCalledWith(3, 'gpay', '*');
    });
  });

  describe('useWebKit hook - iOS WebView platform', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };
    let platform: string;
    let mockExitPaymentSheet: { postMessage: jest.Mock };
    let mockSdkInitialised: { postMessage: jest.Mock };
    let mockLaunchApplePay: { postMessage: jest.Mock };
    let mockParentPostMessage: jest.Mock;

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = setupWindowWebKit();
      mockExitPaymentSheet = win.webkit!.messageHandlers.exitPaymentSheet as { postMessage: jest.Mock };
      mockSdkInitialised = win.webkit!.messageHandlers.sdkInitialised as { postMessage: jest.Mock };
      mockLaunchApplePay = win.webkit!.messageHandlers.launchApplePay as { postMessage: jest.Mock };
      mockParentPostMessage = win.parent.postMessage as jest.Mock;
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
      platform = mod.platform;
    });

    it('platform should be iosWebView when webkit is present', () => {
      expect(platform).toBe('iosWebView');
    });

    it('exitPaymentSheet calls webkit.messageHandlers.exitPaymentSheet.postMessage', () => {
      const { result } = renderHook(() => useWebKit());
      mockExitPaymentSheet.postMessage.mockClear();
      
      result.current.exitPaymentSheet('exit-data');
      
      expect(mockExitPaymentSheet.postMessage).toHaveBeenCalledWith('exit-data');
    });

    it('sdkInitialised calls webkit.messageHandlers.sdkInitialised.postMessage', () => {
      const { result } = renderHook(() => useWebKit());
      mockSdkInitialised.postMessage.mockClear();
      
      result.current.sdkInitialised('sdk-init');
      
      expect(mockSdkInitialised.postMessage).toHaveBeenCalledWith('sdk-init');
    });

    it('launchApplePay calls webkit.messageHandlers.launchApplePay.postMessage', () => {
      const { result } = renderHook(() => useWebKit());
      mockLaunchApplePay.postMessage.mockClear();
      
      result.current.launchApplePay('apple-pay-request');
      
      expect(mockLaunchApplePay.postMessage).toHaveBeenCalledWith('apple-pay-request');
    });

    it('launchGPay calls parent.postMessage on iosWebView (not android specific)', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.launchGPay('gpay-data');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('gpay-data', '*');
    });

    it('handles empty message string', () => {
      const { result } = renderHook(() => useWebKit());
      mockExitPaymentSheet.postMessage.mockClear();
      
      result.current.exitPaymentSheet('');
      
      expect(mockExitPaymentSheet.postMessage).toHaveBeenCalledWith('');
    });

    it('handles JSON message string', () => {
      const { result } = renderHook(() => useWebKit());
      mockExitPaymentSheet.postMessage.mockClear();
      
      result.current.exitPaymentSheet('{"key":"value"}');
      
      expect(mockExitPaymentSheet.postMessage).toHaveBeenCalledWith('{"key":"value"}');
    });
  });

  describe('useWebKit hook - Android WebView platform', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };
    let platform: string;
    let mockHSAndroidInterface: { postMessage: jest.Mock };
    let mockParentPostMessage: jest.Mock;

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = setupWindowAndroidInterface();
      mockHSAndroidInterface = win.HSAndroidInterface as { postMessage: jest.Mock };
      mockParentPostMessage = win.parent.postMessage as jest.Mock;
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
      platform = mod.platform;
    });

    it('platform should be androidWebView when HSAndroidInterface is present', () => {
      expect(platform).toBe('androidWebView');
    });

    it('exitPaymentSheet calls HSAndroidInterface.postMessage with correct format', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.exitPaymentSheet('{"status":"done"}');
      
      expect(mockHSAndroidInterface.postMessage).toHaveBeenCalledWith('{"exitPaymentSheet": {"status":"done"}}');
    });

    it('sdkInitialised calls HSAndroidInterface.postMessage with correct format', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.sdkInitialised('{"ready":true}');
      
      expect(mockHSAndroidInterface.postMessage).toHaveBeenCalledWith('{"sdkInitialised": {"ready":true}}');
    });

    it('launchGPay calls HSAndroidInterface.postMessage with correct format', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.launchGPay('{"amount":"10.00"}');
      
      expect(mockHSAndroidInterface.postMessage).toHaveBeenCalledWith('{"launchGPay": {"amount":"10.00"}}');
    });

    it('launchApplePay returns early on androidWebView (ios only)', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.launchApplePay('apple-pay');
      
      expect(mockHSAndroidInterface.postMessage).not.toHaveBeenCalled();
    });

    it('handles plain string message', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.exitPaymentSheet('plain-string');
      
      expect(mockHSAndroidInterface.postMessage).toHaveBeenCalledWith('{"exitPaymentSheet": plain-string}');
    });

    it('handles empty string message', () => {
      const { result } = renderHook(() => useWebKit());
      mockHSAndroidInterface.postMessage.mockClear();
      
      result.current.exitPaymentSheet('');
      
      expect(mockHSAndroidInterface.postMessage).toHaveBeenCalledWith('{"exitPaymentSheet": }');
    });
  });

  describe('useWebKit hook - native iOS platform', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };
    let platform: string;
    let mockParentPostMessage: jest.Mock;

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('ios');
      const win = setupWindowWebOnly();
      mockParentPostMessage = win.parent.postMessage as jest.Mock;
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
      platform = mod.platform;
    });

    it('platform should be ios when Platform.OS is ios', () => {
      expect(platform).toBe('ios');
    });

    it('exitPaymentSheet calls window.parent.postMessage on native iOS', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('test');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('test', '*');
    });

    it('launchApplePay returns early on native iOS (not iosWebView)', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.launchApplePay('apple-pay');
      
      expect(mockParentPostMessage).not.toHaveBeenCalled();
    });
  });

  describe('useWebKit hook - native Android platform', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };
    let platform: string;
    let mockParentPostMessage: jest.Mock;

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('android');
      const win = setupWindowWebOnly();
      mockParentPostMessage = win.parent.postMessage as jest.Mock;
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
      platform = mod.platform;
    });

    it('platform should be android when Platform.OS is android', () => {
      expect(platform).toBe('android');
    });

    it('exitPaymentSheet calls window.parent.postMessage on native Android', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.exitPaymentSheet('test');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('test', '*');
    });

    it('launchGPay calls window.parent.postMessage on native Android', () => {
      const { result } = renderHook(() => useWebKit());
      mockParentPostMessage.mockClear();
      
      result.current.launchGPay('gpay');
      
      expect(mockParentPostMessage).toHaveBeenCalledWith('gpay', '*');
    });
  });

  describe('useWebKit edge cases', () => {
    let useWebKit: () => { exitPaymentSheet: (s: string) => void; sdkInitialised: (s: string) => void; launchApplePay: (s: string) => void; launchGPay: (s: string) => void };

    beforeAll(() => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = setupWindowWebOnly();
      Object.defineProperty(global, 'window', {
        value: win,
        writable: true,
        configurable: true
      });
      const mod = require('../hooks/WebKit.bs.js');
      useWebKit = mod.useWebKit;
    });

    it('handles null message string without throwing', () => {
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet(null as any)).not.toThrow();
    });

    it('handles undefined message without throwing', () => {
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet(undefined as any)).not.toThrow();
    });
  });

  describe('useWebKit with missing handlers', () => {
    it('handles missing messageHandlers property gracefully', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = {
        webkit: {},
        parent: { postMessage: jest.fn() }
      };
      Object.defineProperty(global, 'window', {
        value: win,
        writable: true,
        configurable: true
      });
      
      const { useWebKit } = require('../hooks/WebKit.bs.js');
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet('test')).not.toThrow();
    });

    it('handles missing specific messageHandler gracefully', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = {
        webkit: {
          messageHandlers: {}
        },
        parent: { postMessage: jest.fn() }
      };
      Object.defineProperty(global, 'window', {
        value: win,
        writable: true,
        configurable: true
      });
      
      const { useWebKit } = require('../hooks/WebKit.bs.js');
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet('test')).not.toThrow();
      expect(() => result.current.sdkInitialised('test')).not.toThrow();
      expect(() => result.current.launchApplePay('test')).not.toThrow();
    });

    it('handles null webkit gracefully', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = {
        webkit: null,
        HSAndroidInterface: null,
        parent: { postMessage: jest.fn() }
      };
      Object.defineProperty(global, 'window', {
        value: win,
        writable: true,
        configurable: true
      });
      
      const { useWebKit } = require('../hooks/WebKit.bs.js');
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet('test')).not.toThrow();
    });

    it('handles null HSAndroidInterface gracefully', () => {
      jest.resetModules();
      setupReactNativePlatform('web');
      const win = {
        HSAndroidInterface: null,
        parent: { postMessage: jest.fn() }
      };
      Object.defineProperty(global, 'window', {
        value: win,
        writable: true,
        configurable: true
      });
      
      const { useWebKit } = require('../hooks/WebKit.bs.js');
      const { result } = renderHook(() => useWebKit());
      
      expect(() => result.current.exitPaymentSheet('test')).not.toThrow();
    });
  });
});
