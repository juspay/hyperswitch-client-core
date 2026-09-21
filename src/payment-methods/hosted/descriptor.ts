import type { ElementType } from '../core/types';
import {
  ELEMENT_TYPES,
  PROTOCOL_VERSION,
  SURFACE_TYPE_FIELD,
  SURFACE_TYPE_FORM,
} from './protocol';
import type { FieldDescriptor, FormDescriptor } from './protocol';

interface ReadFailure {
  ok: false;
  message: string;
}

export type ReadResult<Descriptor> =
  | { ok: true; descriptor: Descriptor }
  | ReadFailure;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export const isElementType = (value: unknown): value is ElementType =>
  typeof value === 'string' &&
  (ELEMENT_TYPES as readonly string[]).includes(value);

/* The host re-sends equal props as a new object; keying on their text keeps a
   re-send from looking like a new form, which would end the old one. */
export function descriptorKey(props: unknown): string {
  try {
    return JSON.stringify(props) ?? '';
  } catch {
    return '';
  }
}

function readCommon(
  raw: unknown,
  type: string
): { ok: true; record: Record<string, unknown> } | ReadFailure {
  if (!isRecord(raw)) {
    return { ok: false, message: 'The props were not an object.' };
  }
  const formId = typeof raw.formId === 'string' ? raw.formId : '';
  const fail = (message: string) => ({ ok: false as const, message });

  if (raw.type !== type) {
    return fail(
      `Unsupported type ${JSON.stringify(raw.type)}; expected "${type}".`
    );
  }

  const version = raw.protocolVersion;
  if (typeof version !== 'number' || !Number.isInteger(version) || version < 1) {
    return fail('protocolVersion must be a positive integer.');
  }
  if (version > PROTOCOL_VERSION) {
    return fail(
      `The host speaks protocol ${version}, this bundle speaks ${PROTOCOL_VERSION}. Update the SDK bundle.`
    );
  }

  if (formId === '') return fail('formId must be a non-empty string.');
  return { ok: true, record: raw };
}

export function readFormDescriptor(raw: unknown): ReadResult<FormDescriptor> {
  const common = readCommon(raw, SURFACE_TYPE_FORM);
  if (!common.ok) return common;
  const { record } = common;
  const fail = (message: string) => ({ ok: false as const, message });

  const hyper = record.hyper;
  if (
    !isRecord(hyper) ||
    typeof hyper.publishableKey !== 'string' ||
    hyper.publishableKey.trim() === ''
  ) {
    return fail('hyper.publishableKey must be a non-empty string.');
  }

  const hasAuthorization =
    typeof record.sdkAuthorization === 'string' &&
    record.sdkAuthorization !== '';
  if (!isRecord(record.vaultDetails) && !hasAuthorization) {
    return fail('Pass sdkAuthorization or vaultDetails.');
  }

  return { ok: true, descriptor: record as unknown as FormDescriptor };
}

export function readFieldDescriptor(raw: unknown): ReadResult<FieldDescriptor> {
  const common = readCommon(raw, SURFACE_TYPE_FIELD);
  if (!common.ok) return common;
  const { record } = common;

  if (!isElementType(record.elementType)) {
    return {
      ok: false,
      message: `Unknown elementType ${JSON.stringify(record.elementType)}.`,
    };
  }
  return { ok: true, descriptor: record as unknown as FieldDescriptor };
}
