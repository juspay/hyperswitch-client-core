import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useSyncExternalStore,
} from 'react';
import type { ForwardRefExoticComponent, RefAttributes } from 'react';
import { View } from 'react-native';
import type { LayoutChangeEvent } from 'react-native';

import type { ElementType, FieldHandle } from '../core/types';
import {
  CardCVCField,
  CardExpiryField,
  CardNumberField,
  CardholderNameField,
} from '../fields';
import type { CardCVCFieldProps } from '../fields';
import { hostBridge } from './bridge';
import type { HostBridge } from './bridge';
import { descriptorKey, readFieldDescriptor } from './descriptor';
import { attachField, fieldChanged, getForm, subscribeForms } from './forms';
import { FieldEvent } from './protocol';

export interface FieldSurfaceProps {
  props?: unknown;
  rootTag: number;
  bridge?: HostBridge;
}

/* testID is not a public field prop; it rides through to the provider field. */
type SlotProps = CardCVCFieldProps & { testID?: string };
type SlotComponent = ForwardRefExoticComponent<
  SlotProps & RefAttributes<FieldHandle>
>;

const FIELD: Record<ElementType, SlotComponent> = {
  cardNumber: CardNumberField as SlotComponent,
  cardExpiry: CardExpiryField as SlotComponent,
  cardCvc: CardCVCField as SlotComponent,
  cardholderName: CardholderNameField as SlotComponent,
};

export function FieldSurface({
  props,
  rootTag,
  bridge = hostBridge,
}: FieldSurfaceProps) {
  const key = descriptorKey(props);
  // eslint-disable-next-line react-hooks/exhaustive-deps -- key is props by value
  const parsed = useMemo(() => readFieldDescriptor(props), [key]);

  const emit = useCallback(
    (event: Parameters<HostBridge['emitField']>[1], payload: object) =>
      bridge.emitField(rootTag, event, payload),
    [bridge, rootTag]
  );

  const invalid = parsed.ok ? null : parsed.message;
  useEffect(() => {
    if (invalid !== null) emit(FieldEvent.Error, { message: invalid });
  }, [invalid, emit]);

  const formId = parsed.ok ? parsed.descriptor.formId : undefined;
  const elementType = parsed.ok ? parsed.descriptor.elementType : undefined;

  /* Until the form screen has opened the form there is nothing to bind to;
     the field draws once it appears, in whichever order the host started them. */
  const form = useSyncExternalStore(subscribeForms, () =>
    formId === undefined ? undefined : getForm(formId)
  );
  const instance = form?.instance;

  const handle = useRef<FieldHandle | null>(null);
  useEffect(() => {
    if (!instance || formId === undefined || elementType === undefined) {
      return undefined;
    }
    return attachField(formId, elementType, () => handle.current);
  }, [instance, formId, elementType]);

  const lastHeight = useRef(-1);
  const onLayout = useCallback(
    (event: LayoutChangeEvent) => {
      const { width, height } = event.nativeEvent.layout;
      const rounded = Math.ceil(height);
      if (rounded === lastHeight.current) return;
      lastHeight.current = rounded;
      emit(FieldEvent.Layout, { width: Math.ceil(width), height: rounded });
    },
    [emit]
  );

  if (!parsed.ok || !instance) return null;

  const {
    type: _type,
    protocolVersion: _protocolVersion,
    formId: ownFormId,
    elementType: ownElementType,
    ...options
  } = parsed.descriptor;
  const Field = FIELD[ownElementType];

  return (
    <View onLayout={onLayout}>
      <Field
        {...options}
        ref={handle}
        form={instance}
        onReady={(event) => emit(FieldEvent.Ready, event)}
        onFocus={(event) => emit(FieldEvent.Focus, event)}
        onBlur={(event) => emit(FieldEvent.Blur, event)}
        onChange={(change) => {
          emit(FieldEvent.Change, change);
          fieldChanged(ownFormId, bridge);
        }}
      />
    </View>
  );
}
