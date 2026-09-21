import React from 'react';
import {TextInput} from 'react-native';
import renderer, {act, ReactTestRenderer} from 'react-test-renderer';
import {
  CardForm,
  CardNumberField,
} from '@juspay-tech/react-native-hyperswitch-vault';

type CardFormHandle = {
  collector: unknown;
};

type FieldChange = {
  elementType: string;
  empty: boolean;
  complete: boolean;
  valid: boolean;
};

const mountHiddenForm = (): CardFormHandle => {
  const ref = React.createRef<CardFormHandle | null>();
  act(() => {
    renderer.create(
      <CardForm sdkAuthorization="sdk_authorization_test" environment="SANDBOX" ref={ref} />,
    );
  });
  if (!ref.current) {
    throw new Error('The hidden <CardForm> did not expose its handle.');
  }
  return ref.current;
};

const renderDetachedNumberField = (
  collector: unknown,
  onChange: (change: FieldChange) => void,
): ReactTestRenderer => {
  let tree!: ReactTestRenderer;
  act(() => {
    tree = renderer.create(
      <CardNumberField
        collector={collector}
        placeholder="Card number"
        onChange={onChange}
      />,
    );
  });
  return tree;
};

describe('detached CardNumberField (collector prop)', () => {
  it('keeps typed text instead of resetting to the mount-time snapshot', () => {
    const {collector} = mountHiddenForm();
    const tree = renderDetachedNumberField(collector, () => {});
    const input = () => tree.root.findByType(TextInput);

    expect(input().props.value).toBe('');

    act(() => {
      input().props.onChangeText('4242424242424242');
    });

    // Controlled value must track the store — formatted, not cleared.
    expect(input().props.value).toBe('4242 4242 4242 4242');

    act(() => {
      input().props.onChangeText('4242 4242 4242 424');
    });
    expect(input().props.value).toBe('4242 4242 4242 424');
  });

  it('reports live change events (not the frozen mount-time values)', () => {
    const {collector} = mountHiddenForm();
    const changes: Array<FieldChange> = [];
    const tree = renderDetachedNumberField(collector, change =>
      changes.push(change),
    );

    act(() => {
      tree.root.findByType(TextInput).props.onChangeText('4242424242424242');
    });

    const last = changes[changes.length - 1];
    expect(last.elementType).toBe('cardNumber');
    expect(last.empty).toBe(false);
    expect(last.complete).toBe(true);
    expect(last.valid).toBe(true);
  });
});
