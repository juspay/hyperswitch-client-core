import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
} from 'react';
import { useFormBinding } from './useFormBinding';
import { resolveFieldStyles } from '../core/appearance';
import {
  CARD_BRAND_ICONS,
  CVC_ICONS,
  ERROR_DISPLAYS,
  LABEL_BEHAVIORS,
  pickAllowed,
  pickString,
} from '../core/validate';
import type {
  CvcIconDisplay,
  ElementType,
  FieldChange,
  FieldHandle,
} from '../core/types';
import { Placeholder } from './Placeholder';
import type { FieldProps } from './types';

type AliasProps = FieldProps & { cvcIcon?: CvcIconDisplay };

export function createCardField<P extends FieldProps = FieldProps>(
  elementType: ElementType,
  displayName: string
) {
  const CardField = forwardRef<FieldHandle, P>((props, ref) => {
    const fieldRef = useRef<FieldHandle | null>(null);
    const {
      form,
      onChange,
      onReady,
      onFocus,
      onBlur,
      options,
      styles: ownStyles,
      placeholder: ownPlaceholder,
      cvcIcon: ownCvcIcon,
      label: ownLabel,
      labelBehavior: ownLabelBehavior,
      errorDisplay: ownErrorDisplay,
      unstyled: ownUnstyled,
      ...rest
    } = props as AliasProps;
    const ctx = useFormBinding(form);

    const onChangeRef = useRef(onChange);
    onChangeRef.current = onChange;
    const onReadyRef = useRef(onReady);
    onReadyRef.current = onReady;

    useImperativeHandle(
      ref,
      () => ({
        focus: () => fieldRef.current?.focus(),
        blur: () => fieldRef.current?.blur(),
        clear: () => fieldRef.current?.clear(),
      }),
      []
    );

    const reportChange = ctx?.reportChange;
    const handleChange = useCallback(
      (change: FieldChange) => {
        reportChange?.(change);
        onChangeRef.current?.(change);
      },
      [reportChange]
    );

    const placeholder =
      pickString(ownPlaceholder) ?? pickString(options?.placeholder);
    const label = pickString(ownLabel) ?? pickString(options?.label);
    const labelBehavior =
      pickAllowed(ownLabelBehavior, LABEL_BEHAVIORS, 'labelBehavior') ??
      pickAllowed(
        options?.labelBehavior,
        LABEL_BEHAVIORS,
        'options.labelBehavior'
      );
    const errorDisplay =
      pickAllowed(ownErrorDisplay, ERROR_DISPLAYS, 'errorDisplay') ??
      pickAllowed(
        options?.errorDisplay,
        ERROR_DISPLAYS,
        'options.errorDisplay'
      );
    const unstyled = ownUnstyled ?? options?.unstyled;
    const cvcIcon =
      elementType === 'cardCvc'
        ? (pickAllowed(ownCvcIcon, CVC_ICONS, 'cvcIcon') ??
          pickAllowed(options?.cvcIcon, CVC_ICONS, 'options.cvcIcon'))
        : undefined;
    const cardBrandIcon =
      elementType === 'cardNumber'
        ? pickAllowed(
            options?.cardBrandIcon,
            CARD_BRAND_ICONS,
            'options.cardBrandIcon'
          )
        : undefined;
    const savedCard = options?.savedCard;
    const savedToken = savedCard?.paymentMethodToken;
    const savedBrand = savedCard?.paymentMethodData?.card?.cardNetwork;
    const registerField = ctx?.registerField;
    const forgetField = ctx?.forgetField;
    useEffect(() => {
      registerField?.(
        elementType,
        savedToken === undefined
          ? undefined
          : {
              savedCard: {
                paymentMethodToken: savedToken,
                ...(savedBrand
                  ? { paymentMethodData: { card: { cardNetwork: savedBrand } } }
                  : {}),
              },
            }
      );
      return () => forgetField?.(elementType);
    }, [registerField, forgetField, savedToken, savedBrand]);

    const styles = useMemo(
      () => resolveFieldStyles(ctx?.appearances, elementType, ownStyles),
      [ctx?.appearances, ownStyles]
    );

    const mounted = ctx !== null && ctx.collector !== undefined;
    useEffect(() => {
      if (mounted) onReadyRef.current?.({ elementType });
    }, [mounted]);

    if (!ctx) {
      throw new Error(
        `${displayName} needs a form: render it inside <CardForm>, or pass form={cardForm}.`
      );
    }

    if (ctx.adapter === null || ctx.collector === undefined) {
      return <Placeholder elementType={elementType} styles={styles} />;
    }

    const Field = ctx.adapter.Field;
    return (
      <Field
        {...rest}
        elementType={elementType}
        collector={ctx.collector}
        fieldRef={fieldRef}
        styles={styles}
        placeholder={placeholder}
        label={label}
        labelBehavior={labelBehavior}
        errorDisplay={errorDisplay}
        unstyled={unstyled}
        cvcIcon={cvcIcon}
        cardBrandIcon={cardBrandIcon}
        savedCard={savedCard}
        onChange={handleChange}
        onFocus={onFocus}
        onBlur={onBlur}
      />
    );
  });

  CardField.displayName = displayName;
  return CardField;
}
