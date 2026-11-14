import NativeHyperVaultRelay from '../../specs/NativeHyperVaultRelay';

// Access layer for the optional HyperVaultRelay TurboModule (see the spec). Opening no-ops, and
// tokenizing rejects, when the host does not provide it.

export const isAvailable = (): boolean => NativeHyperVaultRelay != null;

export const openVaultForm = (rootTag: number, descriptorJson: string): void => {
  NativeHyperVaultRelay?.openVaultForm(rootTag, descriptorJson);
};

export const tokenizeVaultForm = (rootTag: number, formId: string): Promise<string> =>
  NativeHyperVaultRelay
    ? NativeHyperVaultRelay.tokenizeVaultForm(rootTag, formId)
    : Promise.reject(new Error('HyperVaultRelay is not available in this host.'));
