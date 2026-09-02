/**
 * Render-level verification: with the props exactly as the native vault
 * surface sends them (flat {type, config} + separate rootTag), HsVaultEntry
 * must route to the matching widget and actually mount an input — not null.
 */
import React from 'react';
import TestRenderer, {act} from 'react-test-renderer';

jest.mock('../src/specs/NativeHyperVaultModule', () => ({
  __esModule: true,
  default: {
    updateFieldState: jest.fn(),
    updateVaultFieldStates: jest.fn(),
    returnTokenizedValue: jest.fn(),
  },
}));

/* The vault package's .mjs asset manifest + pngs aren't transformable by the
 * repo jest preset (no .mjs/babel rule), and the package "exports" map only
 * exposes src/*.bs.js — mock by absolute path. Not relevant to this check. */
jest.mock(
  require('path').resolve(
    __dirname,
    '../../react-native-hyperswitch-vault/src/cardIconAssets.mjs',
  ),
  () => ({__esModule: true, cardIconAssets: {}, default: {}}),
);

jest.mock('react-native-svg', () => require('react-native-svg/mock'));

const {app: VaultFieldApp} = require('../src/vault/HsVaultEntry.bs.js');

const renderVault = initialProps =>
  TestRenderer.create(
    React.createElement(VaultFieldApp, {props: initialProps, rootTag: 42}),
  );

test('card_number surface mounts a real TextInput (was rendering null before the fix)', async () => {
  let tree;
  await act(async () => {
    tree = renderVault({
      type: 'card_number',
      config: {
        fieldName: 'card_number',
        isRequired: true,
        sessionConfig: {sdkAuthorization: 'sdk_x', environment: 'sandbox'},
        configuration: {options: {placeholder: 'Card number'}},
      },
    });
  });
  const inputs = tree.root.findAllByType(require('react-native').TextInput);
  expect(inputs.length).toBeGreaterThan(0);
});

test.each([
  ['card_number', 'card_number'],
  ['exp_date', 'exp_date'],
  ['cvc', 'cvc'],
  ['card_holder', 'card_holder'],
])('%s surface mounts a real TextInput', async type => {
  let tree;
  await act(async () => {
    tree = renderVault({type, config: {isRequired: true}});
  });
  const inputs = tree.root.findAllByType(require('react-native').TextInput);
  expect(inputs.length).toBeGreaterThan(0);
});
