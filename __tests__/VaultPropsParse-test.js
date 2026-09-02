/**
 * Verifies that the flat initialProperties payload sent by the native vault
 * surfaces (Android BaseVaultFieldView.buildInitialProps / iOS
 * HyperswitchTextField.initialProperties) parses into a renderable field.
 *
 * Wire format (both platforms):
 *   { type: 'cardNumberInput' | 'expDateInput' | 'cvcInput' | 'cardHolderInput',
 *     config: { fieldName?, isRequired,
 *               sessionConfig?: { sdkAuthorization, environment },
 *               configuration?: { appearance?, options? } } }
 */
import {decodeInitialProps} from '../src/vault/VaultFieldTypes.bs.js';

const flatNativePayload = {
  type: 'cardNumberInput',
  config: {
    fieldName: 'card_number',
    isRequired: true,
    sessionConfig: {
      sdkAuthorization: 'sdk_test_123',
      environment: 'production',
    },
    configuration: {
      appearance: {primaryColor: '#FF0000'},
      options: {placeholder: 'Card number', brandIconMode: 'auto'},
    },
  },
};

test('parses the flat native payload (as the vault surface sends it)', () => {
  const decoded = decodeInitialProps(flatNativePayload, 42);

  expect(decoded.rootTag).toBe(42);
  expect(decoded.fieldType).toBe('CardNumber'); // not Unknown -> must render
  expect(decoded.config.fieldName).toBe('card_number');
  expect(decoded.config.isRequired).toBe(true);
  expect(decoded.config.sdkAuthorization).toBe('sdk_test_123');
  expect(decoded.config.environment).toBe('production');
  expect(decoded.config.configuration.appearance).toEqual({
    primaryColor: '#FF0000',
  });
  expect(decoded.config.configuration.options).toEqual({
    placeholder: 'Card number',
    brandIconMode: 'auto',
  });
});

test('payload without sessionConfig still parses (fields render, session absent)', () => {
  const decoded = decodeInitialProps(
    {type: 'cvcInput', config: {isRequired: true}},
    7,
  );

  expect(decoded.fieldType).toBe('CVC');
  expect(decoded.config.sdkAuthorization).toBeUndefined();
  expect(decoded.config.environment).toBeUndefined();
});

test('REPRO of the rendering bug: undefined props (what vault.js used to hand over) yields Unknown("")', () => {
  // vault.js used to spread the flat {type, config} props, so the compiled
  // HsVaultEntry read props.props === undefined. This is why the container
  // mounted but rendered nothing.
  const decoded = decodeInitialProps(undefined, 42);
  expect(decoded.fieldType).toEqual({TAG: 'Unknown', _0: ''});
});
