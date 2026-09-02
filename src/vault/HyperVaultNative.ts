import NativeHyperVaultModule from '../specs/NativeHyperVaultModule';
import type {VaultTokeniseRequest} from '../specs/NativeHyperVaultModule';

export type {VaultTokeniseRequest};

const noop = () => {};

export const updateFieldState = (rootTag: number, state: string): void => {
  NativeHyperVaultModule?.updateFieldState(rootTag, state);
};

export const updateVaultFieldStates = (statesJson: string): void => {
  NativeHyperVaultModule?.updateVaultFieldStates(statesJson);
};

export const returnTokenizedValue = (resultJson: string): void => {
  NativeHyperVaultModule?.returnTokenizedValue(resultJson);
};

/**
 * The CVC-surface claim subscription for the native tokenise broadcast.
 * Typed codegen EventEmitter (onVaultTokenise) — the vault twin of the
 * HyperModule.triggerWidgetAction channel. Returns an unsubscribe thunk;
 * when the host's HyperVaultModule is absent the subscription inertly no-ops
 * and TokeniseDispatcher's 30s net still fires the merchant's completion.
 */
export const subscribeVaultTokenise = (
  handler: (payload: VaultTokeniseRequest) => void,
): (() => void) => {
  const attach = NativeHyperVaultModule?.onVaultTokenise;
  if (!attach) {
    return noop;
  }
  const subscription = attach.call(NativeHyperVaultModule, handler);
  return () => subscription.remove();
};
