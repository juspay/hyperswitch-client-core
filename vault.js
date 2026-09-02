import { AppRegistry } from 'react-native';
import { app as VaultFieldApp } from './src/vault/HsVaultEntry.bs.js';

/*
 * Gate flag the vault widgets key on: NativeHyperswitchVault (inside
 * react-native-hyperswitch-vault) reads `globalThis.__useHyperswitchNativeFeaturesFlag__`
 * and resolves the HyperVaultModule TurboModule itself for emission and for
 * its raw-value store. There is no client-core registry to inject anymore.
 */
globalThis.__useHyperswitchNativeFeaturesFlag__ = true;

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
