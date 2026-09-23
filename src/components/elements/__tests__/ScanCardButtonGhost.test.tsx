/* When the scan card package turns out to be missing, the button becomes a
   ghost mark: no alert tells the shopper about the build. */
import React from 'react';
import { describe, it, expect, jest } from '@jest/globals';
import { fireEvent, render, screen } from '@testing-library/react-native';

const ScanCardButton = require('../ScanCardButton.bs.js');
const VaultInput = require('../../vault/VaultInput.bs.js');

const hidden = { includeHiddenElements: true };

// The field label animates; fake timers keep its frames inside the test.
jest.useFakeTimers();

describe('ghost marks for missing optional packages', () => {
  it('turns the scan card button into a ghost mark once scanning is unavailable', async () => {
    render(
      <ScanCardButton.make
        onScanCard={() => {}}
        expireRef={{ current: null }}
        cvvRef={{ current: null }}
      />
    );
    expect(screen.queryByTestId('scan-card-unavailable', hidden)).toBeNull();
    // This test has no scan card native module, so the launch is unavailable.
    fireEvent.press(screen.getByTestId('scan-card-button', hidden));
    expect(await screen.findByTestId('scan-card-unavailable', hidden)).toBeTruthy();
    expect(screen.queryByTestId('scan-card-button', hidden)).toBeNull();
  });

  it('renders a payment sheet vault field as a ghost mark when its provider is unavailable', () => {
    render(
      <VaultInput.make
        elementType="cardNumber"
        height={50}
        placeholder="Card number"
        label="Card number"
        active={false}
        empty
        valid
        reference={{ current: null }}
        onFocus={() => {}}
        onBlur={() => {}}
        testID="number"
        unavailable
      />
    );
    expect(screen.getByTestId('number-unavailable', hidden)).toBeTruthy();
    expect(screen.queryByText('Card number')).toBeNull();
  });
});
