import { AppRegistry } from 'react-native';
import { app as VaultFieldApp } from './src/vault/HsVaultEntry.bs.js';
import * as HyperVaultStore from './src/vault/HyperVaultStore.bs.js';

/*
 * THE Native Vault feature flag — single source of truth. The vault widgets
 * (react-native-hyperswitch-vault's HyperNativeVault) read it before doing
 * any native work; a plain RN merchant bundle never sets it.
 */
globalThis.__useHyperswitchNativeFeaturesFlag__ = true;

/*
 * THE global Vault registry — the ONLY store for raw field values and their
 * redacted wire states. The widget package's HyperNativeVault accesses this
 * exact object through its declared interface on globalThis (null-guarded);
 * nothing creates a second store/context/provider anywhere.
 */
globalThis.HyperVaultStore = HyperVaultStore;

/*
 * AppRegistry hands the root component the flat initialProperties plus
 * rootTag. HsVaultEntry's compiled signature reads a prop literally named
 * `props` — the whole flat payload — plus `rootTag`, the same convention the
 * main SDK uses in src/routes/Update.js. (Spreading {...props} instead left
 * HsVaultEntry reading props.props === undefined and rendering null.)
 */
let HsVault = (props) => {
  return <VaultFieldApp
    props={props}
    rootTag={props.rootTag}
  />
}

AppRegistry.registerComponent('hs-vault', () => HsVault);
