import { FieldEvent, FormEvent } from './protocol';
import type { FieldEventName, FormEventName } from './protocol';

/* What may cross to the host, key by key. A key that is not listed here is
   dropped, so a provider or a future change cannot widen what leaves this
   engine without this file changing too. `true` passes a value whole; '*'
   stands for any key at that level. */
type Shape = true | { readonly [key: string]: Shape };

const ELEMENT: Shape = { elementType: true };

const FIELD_CHANGE: Shape = {
  elementType: true,
  empty: true,
  complete: true,
  valid: true,
  brand: true,
  error: true,
  touched: true,
};

const CARD_SUMMARY: Shape = {
  bin: true,
  extendedBin: true,
  last4: true,
  brand: true,
  expiryMonth: true,
  expiryYear: true,
  formattedExpiry: true,
  isCardNumberComplete: true,
  isCvcComplete: true,
  isExpiryComplete: true,
  isCardNumberValid: true,
  isExpiryValid: true,
};

const MESSAGE: Shape = { message: true };

export const WIRE_SHAPES: Record<FieldEventName | FormEventName, Shape> = {
  [FieldEvent.Ready]: ELEMENT,
  [FieldEvent.Change]: FIELD_CHANGE,
  [FieldEvent.Focus]: ELEMENT,
  [FieldEvent.Blur]: ELEMENT,
  [FieldEvent.Layout]: { width: true, height: true },
  [FieldEvent.Error]: MESSAGE,

  [FormEvent.Ready]: ELEMENT,
  [FormEvent.Change]: {
    elementType: true,
    eventName: true,
    payload: CARD_SUMMARY,
    complete: true,
    valid: true,
    fields: { '*': FIELD_CHANGE },
  },
  [FormEvent.Error]: MESSAGE,
  /* result is the provider's own tokenize answer: tokens and a card summary.
     Its shape differs per provider, so it passes whole, exactly as the
     in-process library hands it to merchant code today. */
  [FormEvent.CommandResult]: {
    commandId: true,
    name: true,
    ok: true,
    message: true,
    result: true,
  },
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function pick(value: unknown, shape: Shape): unknown {
  if (shape === true) return value;
  if (!isRecord(value)) return undefined;

  const out: Record<string, unknown> = {};
  for (const [key, inner] of Object.entries(value)) {
    const allowed = shape[key] ?? shape['*'];
    if (allowed !== undefined) out[key] = pick(inner, allowed);
  }
  return out;
}

/* A native map also has no undefined, functions or Error instances. A value
   that cannot be serialised is dropped whole rather than allowed to throw
   inside the host. */
export function toWire(
  event: FieldEventName | FormEventName,
  payload: object
): object {
  try {
    const picked = pick(payload, WIRE_SHAPES[event]) ?? {};
    return JSON.parse(JSON.stringify(picked)) as object;
  } catch {
    return {};
  }
}
