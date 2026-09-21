import type {
  CardFormInstance,
  CvcIconDisplay,
  ErrorDisplay,
  LabelBehavior,
  FieldChange,
  FieldEvent,
  FieldOptions,
  FieldStyles,
} from '../core/types';

export type { FieldStyles };

export interface FieldProps {
  form?: CardFormInstance;

  options?: FieldOptions;

  styles?: FieldStyles;
  placeholder?: string;
  label?: string;
  labelBehavior?: LabelBehavior;
  errorDisplay?: ErrorDisplay;
  unstyled?: boolean;

  onReady?: (event: FieldEvent) => void;
  onFocus?: (event: FieldEvent) => void;
  onBlur?: (event: FieldEvent) => void;

  onChange?: (change: FieldChange) => void;
}

export interface CardCVCFieldProps extends FieldProps {
  cvcIcon?: CvcIconDisplay;
}
