import { createFormCore } from '../core/formCore';
import { attachCore } from '../core/formRegistry';
import { loadAdapter } from '../providers/registry';
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

/* Returns at once, initializing. The adapter (and, for a chunked provider,
   its SDK) loads first; the collector is built once it has. Whatever fails
   along the way puts the form in the error state a failed collector would. */
function createCardForm(
  vaultDetails: VaultDetails,
  options: CreateCardFormOptions = {},
  config?: HyperswitchConfiguration
): CardFormInstance {
  const core = createFormCore(
    vaultDetails.vaultType,
    options.appearance ? [options.appearance] : [],
    options.readyTimeoutMs
  );

  const fail = (error: unknown) => {
    core.session.fail(error);
    core.error = error;
    core.status = 'error';
    core.notify();
  };

  loadAdapter(vaultDetails.vaultType)
    .then((adapter) => {
      if (!adapter.createCollector) {
        throw new Error(
          `The ${vaultDetails.vaultType} SDK builds its client from a React provider, so its ` +
            'fields cannot be mounted detached. Use <HyperPaymentMethodSession> with <CardForm> ' +
            'for this vault.'
        );
      }

      const data = adapter.validateVaultData(vaultDetails.vaultData);
      core.attachAdapter(adapter);

      return adapter.createCollector(data, {
        appearances: core.appearances,
        locale: options.locale,
        environment: config?.environment,
        customEndpoints: config?.customEndpoints,
        onCardDetails: (details) => {
          core.details = { ...core.details, ...details };
          core.notify();
        },
      });
    })
    .then((collector) => {
      core.collector = collector;
      core.session.attachCollector(collector);
      core.status = 'ready';
      core.notify();
    }, fail);

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
