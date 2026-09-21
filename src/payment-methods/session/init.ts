import {
  initPaymentMethodSession,
  type PaymentMethodSession,
  type PaymentMethodSessionOptions,
} from './paymentMethodSession';
import type { HyperswitchConfiguration } from './config';

export type { HyperswitchConfiguration };

export interface HyperswitchInstance extends HyperswitchConfiguration {
  initPaymentMethodSession(
    options: PaymentMethodSessionOptions
  ): Promise<PaymentMethodSession>;
}

export function init(
  config: HyperswitchConfiguration
): Promise<HyperswitchInstance> {
  const publishableKey = config.publishableKey?.trim();
  if (!publishableKey) {
    return Promise.reject(
      new Error('Hyperswitch.init needs a non-empty publishableKey.')
    );
  }

  const profileId = config.profileId?.trim();

  const resolved: HyperswitchConfiguration = {
    publishableKey,
    ...(config.platformPublishableKey
      ? { platformPublishableKey: config.platformPublishableKey }
      : {}),
    ...(profileId ? { profileId } : {}),
    ...(config.environment ? { environment: config.environment } : {}),
    ...(config.customEndpoints
      ? { customEndpoints: config.customEndpoints }
      : {}),
  };

  return Promise.resolve({
    ...resolved,
    initPaymentMethodSession: (options: PaymentMethodSessionOptions) =>
      initPaymentMethodSession(resolved, options),
  });
}

export const Hyperswitch = { init };
