/**
 * Hyperswitch Lite SDK for Web
 *
 *   const hs = Hyperswitch.init({
 *     publishableKey: 'pk_...',
 *     profileId: 'pro_...',
 *     environment: 'sandbox',
 *   });
 *
 *   // Payment Sheet
 *   const session = await hs.initPaymentSession({ sdkAuthorization: '...' });
 *   const result = await session.presentPaymentSheet();
 *
 *   // Headless
 *   const handler = await session.getCustomerSavedPaymentMethods();
 *   const result = await handler.confirmWithCustomerDefaultPaymentMethod();
 *
 *   // Elements (embedded)
 *   const elements = await hs.elements({ sdkAuthorization: '...' });
 *   const card = elements.create({ type: 'widgetPaymentSheet' });
 *   card.mount('#card-container');
 *   const result = await card.confirmPayment({ confirmParams: { returnUrl } });
 */

(function (global) {
  'use strict';

  const DEFAULT_SDK_ORIGIN = 'http://127.0.0.1:8082';
  const DEFAULT_TIMEOUT = 30000;

  // ── Parse result from iframe ──────────────────────────────────────────────

  function parsePaymentResult(data) {
    let parsed = data;
    if (typeof data === 'string') {
      try {
        parsed = JSON.parse(data);
      } catch {
        parsed = { status: data };
      }
    }
    if (!parsed || typeof parsed !== 'object') {
      return { type: 'failed', error: String(data) };
    }
    const status = parsed.status;
    if (parsed.code === 'no_data' || parsed.type_ === 'no_data') {
      return { type: 'no_data', message: parsed.message || 'No saved payment methods', raw: parsed };
    }
    if (status === 'succeeded' || status === 'processing' || status === 'requires_capture') {
      return { type: 'completed', data: status, raw: parsed };
    }
    if (status === 'cancelled') {
      return { type: 'canceled', data: status, raw: parsed };
    }
    return { type: 'failed', error: parsed.message || status, raw: parsed };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  function safePostMessage(win, msg, origin) {
    win.postMessage(typeof msg === 'string' ? msg : JSON.stringify(msg), origin);
  }

  function parseEventData(event) {
    if (typeof event.data === 'string') {
      try { return JSON.parse(event.data); } catch { return null; }
    }
    return event.data || null;
  }

  function isObject(item) {
    return item && typeof item === 'object' && !Array.isArray(item);
  }

  function mergeDeep(target, source) {
    if (!source) return target;
    const output = { ...target };
    Object.keys(source).forEach((key) => {
      if (isObject(source[key]) && isObject(output[key])) {
        output[key] = mergeDeep(output[key], source[key]);
      } else {
        output[key] = source[key];
      }
    });
    return output;
  }

  // ── Hyperswitch (static factory) ──────────────────────────────────────────

  class Hyperswitch {
    static init(config = {}) {
      return new HyperswitchInstance(config);
    }
  }

  // ── HyperswitchInstance ───────────────────────────────────────────────────

  class HyperswitchInstance {
    constructor(config) {
      this.publishableKey = config.publishableKey;
      this.profileId = config.profileId || '';
      this.environment = config.environment || 'sandbox';
      this.sdkOrigin = config.sdkOrigin || DEFAULT_SDK_ORIGIN;
      this.customEndpoints = config.customEndpoints || null;
    }

    _buildBaseProps(sessionConfig) {
      return {
        type: 'payment',
        hyperswitchConfig: {
          publishableKey: this.publishableKey,
          profileId: this.profileId,
          environment: this.environment,
          customEndpoints: this.customEndpoints,
        },
        paymentSessionConfig: {
          sdkAuthorization: sessionConfig.sdkAuthorization,
          clientSecret: sessionConfig.clientSecret || '',
        },
        configuration: sessionConfig.configuration || {},
        sdkParams: {
          sessionId: sessionConfig.sessionId || '',
          sdkVersion: sessionConfig.sdkVersion || '1.0.0',
          confirm: false,
          'user-agent': navigator.userAgent,
          launchTime: Date.now(),
          appId: sessionConfig.appId || 'com.example.myapp',
          country: sessionConfig.country || 'US',
          device_model: sessionConfig.device_model || 'iPhone',
          os_type: sessionConfig.os_type || 'iOS',
          os_version: sessionConfig.os_version || '18.5',
          deviceBrand: sessionConfig.deviceBrand || 'Apple',
        },
      };
    }

    async initPaymentSession(sessionConfig = {}) {
      if (!this.publishableKey) {
        throw new Error('publishableKey is required. Pass it to Hyperswitch.init()');
      }
      if (!sessionConfig.sdkAuthorization) {
        throw new Error('sdkAuthorization is required');
      }

      const props = this._buildBaseProps(sessionConfig);
      return new PaymentSession(this, props);
    }

    async elements(sessionConfig = {}) {
      if (!this.publishableKey) {
        throw new Error('publishableKey is required. Pass it to Hyperswitch.init()');
      }
      if (!sessionConfig.sdkAuthorization) {
        throw new Error('sdkAuthorization is required');
      }

      const props = this._buildBaseProps(sessionConfig);
      return new Elements(this, props);
    }
  }

  // ── PaymentSession ────────────────────────────────────────────────────────

  class PaymentSession {
    constructor(instance, props) {
      this._instance = instance;
      this._props = props;
      this._iframe = null;
      this._methods = null;
      this._headlessPromise = null;
      this._sheetIframe = null;
    }

    // ── Lazy headless iframe creation ───────────────────────────────────────

    _ensureHeadless() {
      if (this._headlessPromise) {
        return this._headlessPromise;
      }

      this._headlessPromise = new Promise((resolve, reject) => {
        const iframe = document.createElement('iframe');
        iframe.src = `${this._instance.sdkOrigin}/headless.html`;
        iframe.style.cssText =
          'position:absolute;width:0;height:0;border:0;overflow:hidden;visibility:hidden;';
        document.body.appendChild(iframe);
        this._iframe = iframe;

        const timer = setTimeout(() => {
          iframe.remove();
          this._iframe = null;
          this._headlessPromise = null;
          reject(new Error('Timeout waiting for headless session'));
        }, DEFAULT_TIMEOUT);

        const onMessage = (event) => {
          if (event.origin !== this._instance.sdkOrigin) return;
          const data = parseEventData(event);
          if (!data) return;

          if (data.type === 'headless:sdkLoaded') {
            safePostMessage(
              iframe.contentWindow,
              { type: 'headless:init', props: this._props },
              this._instance.sdkOrigin
            );
            return;
          }

          if (data.type === 'headless:methods') {
            clearTimeout(timer);
            window.removeEventListener('message', onMessage);
            this._methods = data;
            resolve(data);
          }
        };

        window.addEventListener('message', onMessage);
      });

      return this._headlessPromise;
    }

    // ── Payment Sheet (separate iframe, headless stays alive) ────────────────

    async presentPaymentSheet(paymentSheetConfig = {}) {
      const props = { ...this._props };
      if (paymentSheetConfig.configuration) {
        props.configuration = mergeDeep(props.configuration, paymentSheetConfig.configuration);
      }

      return new Promise((resolve, reject) => {
        const iframe = document.createElement('iframe');
        iframe.src = `${this._instance.sdkOrigin}/index.html`;
        iframe.style.cssText =
          'position:fixed;top:0;left:0;width:100%;height:100%;border:0;z-index:9999;';
        iframe.allow = 'payment';
        document.body.appendChild(iframe);
        this._sheetIframe = iframe;

        const timer = setTimeout(() => {
          iframe.remove();
          this._sheetIframe = null;
          reject(new Error('Timeout waiting for payment sheet'));
        }, DEFAULT_TIMEOUT);

        const onMessage = (event) => {
          if (event.origin !== this._instance.sdkOrigin) return;
          const data = parseEventData(event);
          if (!data) return;

          if (data.sdkLoaded) {
            safePostMessage(
              iframe.contentWindow,
              { initialProps: { props } },
              this._instance.sdkOrigin
            );
            return;
          }

          if (data.status) {
            clearTimeout(timer);
            window.removeEventListener('message', onMessage);
            iframe.remove();
            this._sheetIframe = null;
            resolve(parsePaymentResult(data));
          }
        };

        window.addEventListener('message', onMessage);
      });
    }

    // ── Headless: get saved payment methods ──────────────────────────────────

    async getCustomerSavedPaymentMethods() {
      const methods = await this._ensureHeadless();
      return new PaymentSessionHandler(methods, (token, cvc) =>
        this._confirm(token, cvc)
      );
    }

    // ── Headless: confirm with token ────────────────────────────────────────

    async confirmPayment(paymentMethodData, confirmConfig = {}) {
      const token = paymentMethodData?.payment_token || paymentMethodData?.paymentToken;
      if (!token) {
        throw new Error('payment_token is required');
      }
      return this._confirm(token, paymentMethodData.cvc);
    }

    _confirm(token, cvc) {
      return this._ensureHeadless().then(() => {
        return new Promise((resolve, reject) => {
          if (!this._iframe || !this._iframe.contentWindow) {
            reject(new Error('Session expired'));
            return;
          }

          const timer = setTimeout(() => {
            reject(new Error('Timeout waiting for confirmation'));
          }, 60000);

          const onMessage = (event) => {
            if (event.origin !== this._instance.sdkOrigin) return;
            const data = parseEventData(event);
            if (!data) return;

            if (data.type === 'headless:result') {
              clearTimeout(timer);
              window.removeEventListener('message', onMessage);
              this._iframe.remove();
              this._iframe = null;
              this._headlessPromise = null;
              resolve(parsePaymentResult(data.status));
            }
          };

          window.addEventListener('message', onMessage);

          safePostMessage(
            this._iframe.contentWindow,
            { type: 'headless:confirm', token, cvc: cvc || null, rootTag: 0 },
            this._instance.sdkOrigin
          );
        });
      });
    }
  }

  // ── PaymentSessionHandler ─────────────────────────────────────────────────

  class PaymentSessionHandler {
    constructor(methods, confirmFn) {
      this._methods = methods;
      this._confirm = confirmFn;
    }

    getCustomerSavedPaymentMethods() {
      const all = this._methods.all;
      return Promise.resolve(Array.isArray(all) ? all : []);
    }

    getCustomerDefaultSavedPaymentMethodData() {
      const def = this._methods.default;
      if (!def || def.code === 'no_data' || def.type_ === 'no_data') {
        return Promise.resolve(null);
      }
      return Promise.resolve(def);
    }

    getCustomerLastUsedPaymentMethodData() {
      const last = this._methods.lastUsed;
      if (!last || last.code === 'no_data' || last.type_ === 'no_data') {
        return Promise.resolve(null);
      }
      return Promise.resolve(last);
    }

    confirmWithCustomerPaymentToken(token, cvc) {
      return this._confirm(token, cvc);
    }

    confirmWithCustomerDefaultPaymentMethod(cvc) {
      const def = this._methods.default;
      if (!def || def.code === 'no_data' || def.type_ === 'no_data') {
        return Promise.reject(new Error('No default payment method'));
      }
      return this._confirm(def.payment_token, cvc);
    }

    confirmWithCustomerLastUsedPaymentMethod(cvc) {
      const last = this._methods.lastUsed;
      if (!last || last.code === 'no_data' || last.type_ === 'no_data') {
        return Promise.reject(new Error('No last used payment method'));
      }
      return this._confirm(last.payment_token, cvc);
    }
  }

  // ── Elements ──────────────────────────────────────────────────────────────

  class Elements {
    constructor(instance, props) {
      this._instance = instance;
      this._props = props;
    }

    create(options = {}) {
      return new BoundElement(this._instance, this._props, options);
    }
  }

  // ── BoundElement ──────────────────────────────────────────────────────────

  class BoundElement {
    constructor(instance, props, options) {
      this._instance = instance;
      this._props = props;
      this._options = options;
      this._iframe = null;
      this._mounted = false;
      this._result = null;
      this._resultResolve = null;
      this._messageHandler = null;
    }

    mount(selector) {
      if (this._mounted) {
        throw new Error('Element already mounted');
      }

      const container = typeof selector === 'string'
        ? document.querySelector(selector)
        : selector;

      if (!container) {
        throw new Error(`Mount target not found: ${selector}`);
      }

      const iframe = document.createElement('iframe');
      iframe.src = `${this._instance.sdkOrigin}/element.html`;
      iframe.style.cssText = 'width:100%;height:100%;border:0;';
      iframe.allow = 'payment';
      container.appendChild(iframe);
      this._iframe = iframe;
      this._mounted = true;

      const props = {
        ...this._props,
        type: this._options.type || 'widgetPaymentSheet',
      };

      const self = this;

      const onMessage = (event) => {
        if (event.origin !== self._instance.sdkOrigin) return;
        const data = parseEventData(event);
        if (!data) return;

        if (data.sdkLoaded) {
          safePostMessage(
            iframe.contentWindow,
            { initialProps: { props } },
            self._instance.sdkOrigin
          );
        }

        if (data.status) {
          self._result = data;
          if (self._resultResolve) {
            const resolve = self._resultResolve;
            self._resultResolve = null;
            resolve(parsePaymentResult(data));
          }
        }
      };

      this._messageHandler = onMessage;
      window.addEventListener('message', onMessage);
    }

    confirmPayment(confirmConfig = {}) {
      if (this._result) {
        return Promise.resolve(parsePaymentResult(this._result));
      }

      if (!this._iframe || !this._iframe.contentWindow) {
        return Promise.reject(new Error('Element not mounted or session expired'));
      }

      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => {
          this._resultResolve = null;
          reject(new Error('Timeout waiting for confirmation'));
        }, DEFAULT_TIMEOUT);

        this._resultResolve = (data) => {
          clearTimeout(timer);
          resolve(data);
        };

        safePostMessage(
          this._iframe.contentWindow,
          { triggerWidgetAction: { actionType: 'CONFIRM_PAYMENT_ACTION', rootTag: 1 } },
          this._instance.sdkOrigin
        );
      });
    }

    unmount() {
      if (this._messageHandler) {
        window.removeEventListener('message', this._messageHandler);
        this._messageHandler = null;
      }
      if (this._iframe) {
        this._iframe.remove();
        this._iframe = null;
        this._mounted = false;
      }
    }
  }

  // ── Global Export ─────────────────────────────────────────────────────────

  global.Hyperswitch = Hyperswitch;
})(window);
