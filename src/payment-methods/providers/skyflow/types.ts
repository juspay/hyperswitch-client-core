import type { ElementType } from '../../core/types';

export interface SkyflowVaultData {
  vaultId: string;
  vaultUrl: string;
  table: string;
  bearerToken?: string;

  columns?: Partial<Record<ElementType, string>>;
  options?: Record<string, unknown>;
}

export interface SkyflowTokenizeOptions {
  tokens?: boolean;
}
