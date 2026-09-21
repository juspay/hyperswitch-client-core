import type {
  CommonEndpoint,
  HyperswitchEnvironment,
  OverrideEndpoints,
} from './fetchVaultDetails';

export interface HyperswitchConfiguration {
  publishableKey: string;
  platformPublishableKey?: string;
  profileId?: string;
  environment?: HyperswitchEnvironment;
  customEndpoints?: CommonEndpoint | OverrideEndpoints;
}
