import { AppRegistry } from 'react-native';
import { app as VaultFieldApp } from './src/vault/HsVaultEntry.bs.js';
import { pushFieldState, dropSurface } from './src/vault/VaultRegistry.bs.js';

/*
 * Runtime global the widgets look up via globalThis.VaultRegistry.
 * NativeHyperswitchVault (inside react-native-hyperswitch-vault) treats the
 * registry as a JS global — string fieldType + JSON snapshot — so the
 * adapters below convert from that surface to the typed bindings in
 * src/vault/VaultRegistry.res.
 */
const stringToFieldType = raw => {
  switch (raw) {
    case 'card_number':
      return 'CardNumber';
    case 'exp_date':
      return 'Expiry';
    case 'cvc':
      return 'CVC';
    case 'card_holder':
      return 'CardHolder';
    case 'ssn':
      return 'Ssn';
    case 'info':
      return 'Info';
    default:
      return { TAG: 'Unknown', _0: raw };
  }
};

globalThis.VaultRegistry = {
  pushFieldState: (rootTag, fieldType, state) =>
    pushFieldState(rootTag, stringToFieldType(fieldType), state),
  dropSurface: (rootTag, fieldType) =>
    dropSurface(rootTag, stringToFieldType(fieldType)),
};
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
