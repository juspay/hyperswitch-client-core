import type {TurboModule, CodegenTypes} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

/**
 * Native → JS tokenise REQUEST payload (typed broadcast contract).
 *
 * Kotlin (android/VaultTokeniseRequest.kt), Swift
 * (ios/VaultTokeniseRequest.swift) and the JS decoder
 * (src/vault/VaultTokenise.res) all implement their side against this type;
 * keep all three in sync.
 */
export type VaultTokeniseRequest = {
  /**
   * Base64 JSON carrying payment_method_session_id; absent = the claiming
   * surface falls back to its own sdkAuthorization.
   */
  sdkAuthorization?: string;
  /** "sandbox" | "integration" | "production"; absent = surface fallback. */
  environment?: string;
};

export interface Spec extends TurboModule {
  updateFieldState(rootTag: CodegenTypes.Int32, state: string): void;
  updateVaultFieldStates(statesJson: string): void;
  returnTokenizedValue(resultJson: string): void;

  /**
   * HyperswitchVault.tokenise request broadcast: exactly one mounted JS
   * surface claims each request and answers via returnTokenizedValue. Codegen
   * typed EventEmitter — the same pattern NativeHyperModule uses for
   * `triggerWidgetAction` (the confirmCVC channel).
   */
  readonly onVaultTokenise: CodegenTypes.EventEmitter<VaultTokeniseRequest>;
}

export default TurboModuleRegistry.get<Spec>('HyperVaultModule');
