export interface VgsVaultData {
  vaultId: string;
  environment?: string;
  routeId?: string;
  cname?: string;
}

export interface VgsTokenizeOptions {
  path?: string;
  method?: string;
  extraData?: Record<string, unknown>;
}
