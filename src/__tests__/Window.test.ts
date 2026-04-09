import { renderHook, act } from '@testing-library/react-native';

const {
  setHref,
  getStatusString,
  useScript,
  useLink,
  map,
  registerEventListener,
  useEventListener,
} = require('../utility/logics/Window.bs.js');

describe('Window', () => {
  let originalWindowLocation: Location;

  beforeEach(() => {
    jest.clearAllMocks();
    originalWindowLocation = window.location;
    map.clear();
  });

  afterEach(() => {
    window.location = originalWindowLocation;
  });

  describe('setHref', () => {
    it('sets window.location.href to the provided URL', () => {
      delete (window as any).location;
      window.location = { href: '' } as Location;

      setHref('https://example.com');

      expect(window.location.href).toBe('https://example.com');
    });

    it('overwrites existing href value', () => {
      delete (window as any).location;
      window.location = { href: 'https://old-url.com' } as Location;

      setHref('https://new-url.com');

      expect(window.location.href).toBe('https://new-url.com');
    });

    it('handles empty string URL', () => {
      delete (window as any).location;
      window.location = { href: 'https://existing.com' } as Location;

      setHref('');

      expect(window.location.href).toBe('');
    });

    it('handles relative URLs', () => {
      delete (window as any).location;
      window.location = { href: '' } as Location;

      setHref('/path/to/page');

      expect(window.location.href).toBe('/path/to/page');
    });

    it('handles URLs with query parameters', () => {
      delete (window as any).location;
      window.location = { href: '' } as Location;

      setHref('https://example.com?param=value&other=test');

      expect(window.location.href).toBe('https://example.com?param=value&other=test');
    });
  });

  describe('getStatusString', () => {
    it('returns "load" for status "load"', () => {
      expect(getStatusString('load')).toBe('load');
    });

    it('returns "ready" for status "ready"', () => {
      expect(getStatusString('ready')).toBe('ready');
    });

    it('returns "error" for status "error"', () => {
      expect(getStatusString('error')).toBe('error');
    });

    it('returns "loading" for status "loading"', () => {
      expect(getStatusString('loading')).toBe('loading');
    });

    it('returns "idle" for unknown status strings', () => {
      expect(getStatusString('unknown')).toBe('idle');
    });

    it('returns "idle" for empty string', () => {
      expect(getStatusString('')).toBe('idle');
    });

    it('returns "idle" for null converted to string', () => {
      expect(getStatusString(null as any)).toBe('idle');
    });

    it('returns "idle" for undefined converted to string', () => {
      expect(getStatusString(undefined as any)).toBe('idle');
    });
  });

  describe('useScript', () => {
    let mockScriptElement: any;
    let appendedElements: any[];
    let eventListeners: { [key: string]: Function[] };

    beforeEach(() => {
      appendedElements = [];
      eventListeners = {};

      mockScriptElement = {
        src: '',
        async: false,
        setAttribute: jest.fn(),
        getAttribute: jest.fn(() => null),
        addEventListener: jest.fn((event: string, handler: Function) => {
          if (!eventListeners[event]) {
            eventListeners[event] = [];
          }
          eventListeners[event].push(handler);
        }),
        removeEventListener: jest.fn(),
      };

      const mockHead = {
        appendChild: jest.fn((el: any) => {
          appendedElements.push(el);
        }),
      };

      const mockDocument = {
        querySelector: jest.fn(() => null),
        createElement: jest.fn(() => mockScriptElement),
        head: mockHead,
      };

      Object.defineProperty(global, 'document', {
        value: mockDocument,
        writable: true,
      });
    });

    it('returns "idle" when src is empty string', () => {
      const { result } = renderHook(() => useScript(''));

      expect(result.current).toBe('idle');
    });

    it('returns "loading" when src is provided and script does not exist', () => {
      const { result } = renderHook(() => useScript('https://example.com/script.js'));

      expect(result.current).toBe('loading');
    });

    it('creates and appends script element for new scripts', () => {
      renderHook(() => useScript('https://example.com/script.js'));

      expect(document.createElement).toHaveBeenCalledWith('script');
      expect(document.head.appendChild).toHaveBeenCalled();
    });

    it('sets script attributes correctly', () => {
      renderHook(() => useScript('https://example.com/script.js'));

      expect(mockScriptElement.src).toBe('https://example.com/script.js');
      expect(mockScriptElement.async).toBe(true);
      expect(mockScriptElement.setAttribute).toHaveBeenCalledWith('data-status', 'loading');
    });

    it('registers load and error event listeners', () => {
      renderHook(() => useScript('https://example.com/script.js'));

      expect(mockScriptElement.addEventListener).toHaveBeenCalledWith('load', expect.any(Function));
      expect(mockScriptElement.addEventListener).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('uses existing script status when script already exists', () => {
      const mockExistingScript = {
        getAttribute: jest.fn(() => 'ready'),
      };

      (document.querySelector as jest.Mock).mockReturnValue(mockExistingScript);

      const { result } = renderHook(() => useScript('https://example.com/script.js'));

      expect(result.current).toBe('ready');
      expect(document.head.appendChild).not.toHaveBeenCalled();
    });

    it('sets status to "ready" when script load event fires', () => {
      renderHook(() => useScript('https://example.com/script.js'));

      const loadHandler = eventListeners['load']?.[0];
      expect(loadHandler).toBeDefined();

      act(() => {
        loadHandler({ type: 'load' });
      });

      expect(mockScriptElement.setAttribute).toHaveBeenCalledWith('data-status', 'ready');
    });

    it('sets status to "error" when script error event fires', () => {
      renderHook(() => useScript('https://example.com/script.js'));

      const errorHandler = eventListeners['error']?.[0];
      expect(errorHandler).toBeDefined();

      act(() => {
        errorHandler({ type: 'error' });
      });

      expect(mockScriptElement.setAttribute).toHaveBeenCalledWith('data-status', 'error');
    });

    it('removes event listeners on cleanup', () => {
      const { unmount } = renderHook(() => useScript('https://example.com/script.js'));

      unmount();

      expect(mockScriptElement.removeEventListener).toHaveBeenCalledWith('load', expect.any(Function));
      expect(mockScriptElement.removeEventListener).toHaveBeenCalledWith('error', expect.any(Function));
    });
  });

  describe('useLink', () => {
    let mockLinkElement: any;
    let eventListeners: { [key: string]: Function[] };

    beforeEach(() => {
      eventListeners = {};

      mockLinkElement = {
        href: '',
        rel: '',
        async: false,
        setAttribute: jest.fn(),
        getAttribute: jest.fn(() => null),
        addEventListener: jest.fn((event: string, handler: Function) => {
          if (!eventListeners[event]) {
            eventListeners[event] = [];
          }
          eventListeners[event].push(handler);
        }),
        removeEventListener: jest.fn(),
      };

      const mockHead = {
        appendChild: jest.fn(),
      };

      const mockDocument = {
        querySelector: jest.fn(() => null),
        createElement: jest.fn(() => mockLinkElement),
        head: mockHead,
      };

      Object.defineProperty(global, 'document', {
        value: mockDocument,
        writable: true,
      });
    });

    it('returns "idle" when src is empty string', () => {
      const { result } = renderHook(() => useLink(''));

      expect(result.current).toBe('idle');
    });

    it('returns "loading" when src is provided and link does not exist', () => {
      const { result } = renderHook(() => useLink('https://example.com/styles.css'));

      expect(result.current).toBe('loading');
    });

    it('creates and appends link element for new stylesheets', () => {
      renderHook(() => useLink('https://example.com/styles.css'));

      expect(document.createElement).toHaveBeenCalledWith('link');
      expect(document.head.appendChild).toHaveBeenCalled();
    });

    it('sets link attributes correctly', () => {
      renderHook(() => useLink('https://example.com/styles.css'));

      expect(mockLinkElement.href).toBe('https://example.com/styles.css');
      expect(mockLinkElement.rel).toBe('stylesheet');
      expect(mockLinkElement.async).toBe(true);
      expect(mockLinkElement.setAttribute).toHaveBeenCalledWith('data-status', 'loading');
    });

    it('registers load and error event listeners', () => {
      renderHook(() => useLink('https://example.com/styles.css'));

      expect(mockLinkElement.addEventListener).toHaveBeenCalledWith('load', expect.any(Function));
      expect(mockLinkElement.addEventListener).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('uses existing link status when stylesheet already exists', () => {
      const mockExistingLink = {
        getAttribute: jest.fn(() => 'ready'),
      };

      (document.querySelector as jest.Mock).mockReturnValue(mockExistingLink);

      const { result } = renderHook(() => useLink('https://example.com/styles.css'));

      expect(result.current).toBe('ready');
      expect(document.head.appendChild).not.toHaveBeenCalled();
    });

    it('sets status to "ready" when link load event fires', () => {
      renderHook(() => useLink('https://example.com/styles.css'));

      const loadHandler = eventListeners['load']?.[0];
      expect(loadHandler).toBeDefined();

      act(() => {
        loadHandler({ type: 'load' });
      });

      expect(mockLinkElement.setAttribute).toHaveBeenCalledWith('data-status', 'ready');
    });

    it('sets status to "error" when link error event fires', () => {
      renderHook(() => useLink('https://example.com/styles.css'));

      const errorHandler = eventListeners['error']?.[0];
      expect(errorHandler).toBeDefined();

      act(() => {
        errorHandler({ type: 'error' });
      });

      expect(mockLinkElement.setAttribute).toHaveBeenCalledWith('data-status', 'error');
    });

    it('removes event listeners on cleanup', () => {
      const { unmount } = renderHook(() => useLink('https://example.com/styles.css'));

      unmount();

      expect(mockLinkElement.removeEventListener).toHaveBeenCalledWith('load', expect.any(Function));
      expect(mockLinkElement.removeEventListener).toHaveBeenCalledWith('error', expect.any(Function));
    });
  });

  describe('map', () => {
    it('is a Map instance', () => {
      expect(map).toBeInstanceOf(Map);
    });
  });

  describe('registerEventListener', () => {
    it('registers a callback for a given key', () => {
      const callback = jest.fn();
      registerEventListener('testKey', callback);

      expect(map.get('testKey')).toBe(callback);
    });

    it('overwrites existing callback for the same key', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();

      registerEventListener('testKey', callback1);
      registerEventListener('testKey', callback2);

      expect(map.get('testKey')).toBe(callback2);
    });

    it('can register multiple keys with different callbacks', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();

      registerEventListener('key1', callback1);
      registerEventListener('key2', callback2);

      expect(map.get('key1')).toBe(callback1);
      expect(map.get('key2')).toBe(callback2);
    });

    it('allows retrieving registered callbacks', () => {
      const callback = jest.fn();
      registerEventListener('myKey', callback);

      const retrievedCallback = map.get('myKey');
      retrievedCallback({ data: 'test' });

      expect(callback).toHaveBeenCalledWith({ data: 'test' });
    });
  });

  describe('useEventListener', () => {
    let messageListeners: Function[];

    beforeEach(() => {
      messageListeners = [];

      const mockWindow = {
        addEventListener: jest.fn((event: string, handler: Function) => {
          if (event === 'message') {
            messageListeners.push(handler);
          }
        }),
        removeEventListener: jest.fn((event: string, handler: Function) => {
          const index = messageListeners.indexOf(handler);
          if (index > -1) {
            messageListeners.splice(index, 1);
          }
        }),
      };

      Object.defineProperty(global, 'window', {
        value: mockWindow,
        writable: true,
      });
    });

    it('adds a message event listener on mount', () => {
      renderHook(() => useEventListener());

      expect(window.addEventListener).toHaveBeenCalledWith('message', expect.any(Function));
    });

    it('removes the message event listener on unmount', () => {
      const { unmount } = renderHook(() => useEventListener());

      unmount();

      expect(window.removeEventListener).toHaveBeenCalledWith('message', expect.any(Function));
    });

    it('calls registered callback when valid message is received', () => {
      const callback = jest.fn();
      map.set('eventType', callback);

      renderHook(() => useEventListener());

      const messageHandler = messageListeners[0];

      const mockEvent = {
        data: JSON.stringify({ eventType: { data: 'test value' } }),
      };

      act(() => {
        messageHandler(mockEvent);
      });

      expect(callback).toHaveBeenCalled();
    });

    it('does not call callback when message does not contain registered key', () => {
      const callback = jest.fn();
      map.set('registeredKey', callback);

      renderHook(() => useEventListener());

      const messageHandler = messageListeners[0];

      const mockEvent = {
        data: JSON.stringify({ differentKey: { data: 'test' } }),
      };

      act(() => {
        messageHandler(mockEvent);
      });

      expect(callback).not.toHaveBeenCalled();
    });

    it('handles invalid JSON gracefully without throwing', () => {
      const callback = jest.fn();
      map.set('testKey', callback);

      renderHook(() => useEventListener());

      const messageHandler = messageListeners[0];

      const mockEvent = {
        data: 'invalid json {{{',
      };

      expect(() => {
        messageHandler(mockEvent);
      }).not.toThrow();

      expect(callback).not.toHaveBeenCalled();
    });

    it('handles event data that is not a JSON object', () => {
      const callback = jest.fn();
      map.set('testKey', callback);

      renderHook(() => useEventListener());

      const messageHandler = messageListeners[0];

      const mockEvent = {
        data: JSON.stringify('just a string'),
      };

      expect(() => {
        messageHandler(mockEvent);
      }).not.toThrow();
    });
  });
});
