import { createFormCore } from '../core/formCore';
import { attachCore } from '../core/formRegistry';
import { resolveAdapter } from '../providers/registry';
import { fetchVaultDetails } from './fetchVaultDetails';
import type { HyperswitchConfiguration } from './config';
import type {
  Appearance,
  CardFormInstance,
  FormStatus,
  TokenizeResult,
  VaultDetails,
} from '../core/types';

export interface PaymentMethodSessionOptions {
  sdkAuthorization?: string;
  vaultDetails?: VaultDetails;
}

export interface CreateCardFormOptions {
  appearance?: Appearance;
  locale?: string;
  readyTimeoutMs?: number;
}

export interface PaymentMethodSession {
  readonly vaultDetails: VaultDetails;
  createCardForm(options?: CreateCardFormOptions): CardFormInstance;
}

function createCardForm(
  vaultDetails: VaultDetails,
  options: CreateCardFormOptions = {},
  config?: HyperswitchConfiguration
): CardFormInstance {
  const adapter = resolveAdapter(vaultDetails.vaultType);

  if (!adapter.createCollector) {
    throw new Error(
      `The ${vaultDetails.vaultType} SDK builds its client from a React provider, so its ` +
        'fields cannot be mounted detached. Use <HyperPaymentMethodSession> with <CardForm> ' +
        'for this vault.'
    );
  }

  const data = adapter.validateVaultData(vaultDetails.vaultData);
  const core = createFormCore(
    adapter,
    options.appearance ? [options.appearance] : [],
    options.readyTimeoutMs
  );

  adapter
    .createCollector(data, {
      appearances: core.appearances,
      locale: options.locale,
      environment: config?.environment,
      customEndpoints: config?.customEndpoints,
      onCardDetails: (details) => {
        core.details = { ...core.details, ...details };
        core.notify();
      },
    })
    .then(
      (collector) => {
        core.collector = collector;
        core.session.attachCollector(collector);
        core.status = 'ready';
        core.notify();
      },
      (error: unknown) => {
        core.session.fail(error);
        core.status = 'error';
        core.notify();
      }
    );

  const instance: CardFormInstance = {
    tokenize: (providerData?: unknown): Promise<TokenizeResult> =>
      core.tokenize(providerData),
    get status(): FormStatus {
      return core.status;
    },
  };

  attachCore(instance, core);
  return instance;
}

export async function initPaymentMethodSession(
  config: HyperswitchConfiguration,
  options: PaymentMethodSessionOptions
): Promise<PaymentMethodSession> {
  const resolved = options.vaultDetails
    ? { ok: true as const, vaultDetails: options.vaultDetails }
    : options.sdkAuthorization
      ? await fetchVaultDetails({
          sdkAuthorization: options.sdkAuthorization,
          environment: config.environment,
          customEndpoints: config.customEndpoints,
        })
      : {
          ok: false as const,
          message:
            'initPaymentMethodSession needs sdkAuthorization or vaultDetails.',
        };

  if (!resolved.ok) throw new Error(resolved.message);

  const vaultDetails = resolved.vaultDetails;
  return {
    vaultDetails,
    createCardForm: (formOptions?: CreateCardFormOptions) =>
      createCardForm(vaultDetails, formOptions, config),
  };
}
