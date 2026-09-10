import NativeHyperHeadless from '../../specs/NativeHyperHeadless';

function assertModule(method: string): boolean {
  if (NativeHyperHeadless == null) {
    console.error(
      `[HyperHeadless] native module is NULL in this JS context — ` +
        `TurboModuleRegistry.get('HyperHeadless') returned nothing, so ` +
        `${method}() cannot reach native.`,
    );
    return false;
  }
  if (typeof (NativeHyperHeadless as any)[method] !== 'function') {
    console.error(
      `[HyperHeadless] ${method}() is missing on the native module — ` +
        `the native side needs a rebuild so codegen regenerates the spec.`,
    );
    return false;
  }
  return true;
}

export const getPaymentSession = (
  rootTag: number,
  paymentIntentData: Object,
  defaultPaymentMethod: Object,
  savedPaymentMethods: Array<Object>,
  callback: (result: Object) => void,
): void => {
  if (!assertModule('getPaymentSession')) {
    return;
  }
  NativeHyperHeadless?.getPaymentSession(
    rootTag,
    paymentIntentData,
    defaultPaymentMethod,
    savedPaymentMethods,
    callback,
  );
};

export const getWalletSession = (
  rootTag: number,
  wallets: Array<Object>,
  callback: (result: Object) => void,
): void => {
  if (!assertModule('getWalletSession')) {
    return;
  }
  NativeHyperHeadless?.getWalletSession(rootTag, wallets, callback);
};

export const exitHeadless = (rootTag: number, result: string): void => {
  NativeHyperHeadless?.exitHeadless(rootTag, result);
};
