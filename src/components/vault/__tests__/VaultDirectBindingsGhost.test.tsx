/* Without the vault package in the build, payment method management's card
   form renders ghost marks where the vault fields would be, and no error. */
import React from 'react';
import { describe, it, expect, jest } from '@jest/globals';
import { render, screen } from '@testing-library/react-native';

jest.mock('../../../chunks/VaultPackage.bs.js', () => ({ loaded: null }));

const Vault = require('../VaultDirectBindings.bs.js');

describe('VaultDirectBindings without the vault package', () => {
  it('shows each field as a ghost mark inside the form', async () => {
    render(
      <Vault.CardForm.make>
        <Vault.CardNumberField.make testID="number" />
        <Vault.CardCVCField.make testID="cvc" />
      </Vault.CardForm.make>
    );
    // Ghost marks are hidden from screen readers, so the query must include them.
    const hidden = { includeHiddenElements: true };
    expect(await screen.findByTestId('number-unavailable', hidden)).toBeTruthy();
    expect(await screen.findByTestId('cvc-unavailable', hidden)).toBeTruthy();
  });
});
