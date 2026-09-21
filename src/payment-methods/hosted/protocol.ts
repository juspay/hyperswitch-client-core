import type {
  Appearance,
  CvcIconDisplay,
  ElementType,
  ErrorDisplay,
  FieldOptions,
  FieldStyles,
  FormId,
  LabelBehavior,
  TokenizeResult,
  VaultDetails,
} from '../core/types';
import type { HyperswitchConfiguration } from '../session/config';

/* The contract between this bundle and whatever hosts it (the native SDKs, or
   the React Native package's native glue). The host keeps its own copy of these
   shapes; protocolVersion is how the two sides notice they have drifted. */
export const PROTOCOL_VERSION = 1;

export const NATIVE_MODULE = 'HyperPaymentMethodsModule';

/* Viewless. One per form: it owns the form, so ending it ends the form. */
export const FORM_COMPONENT = 'HyperPaymentMethodsForm';

/* One per field view the merchant places. */
export const FIELD_COMPONENT = 'HyperPaymentMethodsField';

export const SURFACE_TYPE_FORM = 'paymentMethodsForm';
export const SURFACE_TYPE_FIELD = 'paymentMethodsField';

export const ELEMENT_TYPES: readonly ElementType[] = [
  'cardNumber',
  'cardExpiry',
  'cardCvc',
  'cardholderName',
];

interface DescriptorBase {
  protocolVersion: number;
  formId: FormId;
}

export interface FormDescriptor extends DescriptorBase {
  type: typeof SURFACE_TYPE_FORM;
  hyper: HyperswitchConfiguration;
  sdkAuthorization?: string;
  vaultDetails?: VaultDetails;
  appearance?: Appearance;
  locale?: string;
  readyTimeoutMs?: number;
}

export interface FieldDescriptor extends DescriptorBase {
  type: typeof SURFACE_TYPE_FIELD;
  elementType: ElementType;
  placeholder?: string;
  label?: string;
  labelBehavior?: LabelBehavior;
  errorDisplay?: ErrorDisplay;
  unstyled?: boolean;
  cvcIcon?: CvcIconDisplay;
  options?: FieldOptions;
  styles?: FieldStyles;
  testID?: string;
}

export const FieldEvent = {
  Ready: 'PM_FIELD_READY',
  Change: 'PM_FIELD_CHANGE',
  Focus: 'PM_FIELD_FOCUS',
  Blur: 'PM_FIELD_BLUR',
  Layout: 'PM_LAYOUT',
  Error: 'PM_FIELD_ERROR',
} as const;

export const FormEvent = {
  Ready: 'PM_FORM_READY',
  Change: 'PM_FORM_CHANGE',
  Error: 'PM_FORM_ERROR',
  CommandResult: 'PM_COMMAND_RESULT',
} as const;

export type FieldEventName = (typeof FieldEvent)[keyof typeof FieldEvent];
export type FormEventName = (typeof FormEvent)[keyof typeof FormEvent];

export type FieldCommandName = 'focus' | 'blur' | 'clear';

/* rootTag is the form screen's. Every answer goes back to it, so the host finds
   the form the way it finds any surface's owner and keeps no table of forms. */
interface CommandBase {
  rootTag: number;
  formId: FormId;
  commandId: string;
}

export type SurfaceCommand =
  | (CommandBase & { name: 'tokenize'; providerData?: unknown })
  | (CommandBase & { name: FieldCommandName; elementType: ElementType });

export interface CommandResultPayload {
  commandId: string;
  name: SurfaceCommand['name'];
  ok: boolean;
  result?: TokenizeResult;
  message?: string;
}
