import type { TurboModule, CodegenTypes } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

/**
 * The relay between a CardWidget (this runtime, payments level) and the hosted payment-methods
 * form it drives (the payment-methods runtime, vault level). The two runtimes cannot call each
 * other, so the host forwards between them; it never reads what it forwards.
 *
 * Results and events still travel on the widgets' existing channels (HyperModule's
 * notifyWidgetPaymentResult / emitPaymentEvent); this module only adds what is new.
 *
 * Optional: a host without hosted card fields does not implement it, and CardWidget then refuses
 * with `sdk_not_ready` instead of failing.
 */
export interface Spec extends TurboModule {
  /** Open (or replace) the hosted form `formId` with this payment-methods form descriptor. */
  openVaultForm(rootTag: CodegenTypes.Int32, descriptorJson: string): void;

  /**
   * Send the hosted form its `tokenize` command and resolve with the PM_COMMAND_RESULT payload,
   * as JSON, unchanged.
   */
  tokenizeVaultForm(rootTag: CodegenTypes.Int32, formId: string): Promise<string>;
}

export default TurboModuleRegistry.get<Spec>('HyperVaultRelay');
