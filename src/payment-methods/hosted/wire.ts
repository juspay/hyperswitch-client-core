import { FieldEvent, FormEvent } from './protocol';
import type { FieldEventName, FormEventName } from './protocol';

/* What may cross to the host, key by key. A key that is not listed here is
   dropped, so a provider or a future change cannot widen what leaves this
   engine without this file changing too.

   `true` passes a boolean, a number, null, or text; text loses anything shaped
   like a card number and is cut to a sane length, whichever key it sits under.
   `digits(n)` passes at most n digits and nothing else. 'tokens' is the one
   place a provider's own value passes whole. '*' stands for any key. */
class Digits {
  constructor(readonly max: number) {}
}
const digits = (max: number) => new Digits(max);

type Shape = true | 'tokens' | Digits | { readonly [key: string]: Shape };

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
  bin: digits(6),
  extendedBin: digits(8),
  brand: true,
  expiryMonth: digits(2),
  expiryYear: digits(4),
  formattedExpiry: true,
  isCardNumberComplete: true,
  isCvcComplete: true,
  isExpiryComplete: true,
  isCardNumberValid: true,
  isExpiryValid: true,
};

const MESSAGE: Shape = { message: true };

const TOKENIZE_RESULT: Shape = {
  status: true,
  vaultType: true,
  data: {
    tokens: 'tokens',
    savedCard: {
      paymentMethodToken: true,
      paymentMethodData: { card: { cardNetwork: true } },
    },
  },
  card: {
    bin: digits(6),
    last4: digits(4),
    brand: true,
    expiryMonth: digits(2),
    expiryYear: digits(4),
  },
  error: { code: true, message: true, type: true },
};

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
  [FormEvent.CommandResult]: {
    commandId: true,
    name: true,
    ok: true,
    message: true,
    result: TOKENIZE_RESULT,
  },
};

const MAX_TEXT = 512;
const MAX_PAYLOAD = 64 * 1024;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

const CARD_NUMBER_LIKE = /\d(?:[\s\-./]{0,3}\d){12,}/g;

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function withoutCardNumbers(text: string): string {
  let plain = text;
  try {
    plain = text.normalize('NFKC');
  } catch {
    /* An engine without normalize still gets the search below. */
  }
  return plain.replace(CARD_NUMBER_LIKE, '[redacted]');
}

function scalar(value: unknown): unknown {
  if (value === null || typeof value === 'boolean') return value;
  if (typeof value === 'number') return Number.isFinite(value) ? value : undefined;
  if (typeof value !== 'string') return undefined;
  if (UUID.test(value)) return value;
  return withoutCardNumbers(value).slice(0, MAX_TEXT);
}

function pick(value: unknown, shape: Shape): unknown {
  if (shape === true) return scalar(value);
  if (shape === 'tokens') return isRecord(value) ? value : undefined;
  if (shape instanceof Digits) {
    if (value === null) return null;
    return typeof value === 'string' &&
      value.length <= shape.max &&
      /^\d+$/.test(value)
      ? value
      : undefined;
  }
  if (!isRecord(value)) return undefined;

  const out: Record<string, unknown> = {};
  for (const [key, inner] of Object.entries(value)) {
    /* Own keys only: "constructor" and its like are keys of every object. */
    const allowed = Object.prototype.hasOwnProperty.call(shape, key)
      ? shape[key]
      : shape['*'];
    if (allowed !== undefined) out[key] = pick(inner, allowed);
  }
  return out;
}

/* American Express and Diners Club numbers are shorter than sixteen digits. */
const SHORT_NUMBER_BRAND = /amex|american\s*express|diners/i;

/* How much of a number may be shown is set by PCI's truncation formats: the
   first eight digits of a sixteen-digit number, the first six of a shorter one. */
function truncate(summary: unknown): void {
  if (!isRecord(summary)) return;
  if (typeof summary.brand === 'string' && SHORT_NUMBER_BRAND.test(summary.brand)) {
    summary.extendedBin = null;
  }
}

/* A command must always be answered, or whoever sent it waits for good. */
function unsendable(
  event: FieldEventName | FormEventName,
  payload: object
): object {
  if (event !== FormEvent.CommandResult || !isRecord(payload)) return {};
  return {
    commandId: scalar(payload.commandId),
    name: scalar(payload.name),
    ok: false,
    message: 'The result could not be passed on.',
  };
}

/* A native map also has no undefined, functions or Error instances. A value
   that cannot be serialised, or is too large to be what it claims, is not sent
   rather than allowed to throw inside the host. */
export function toWire(
  event: FieldEventName | FormEventName,
  payload: object
): object {
  try {
    const picked = pick(payload, WIRE_SHAPES[event]) ?? {};
    if (event === FormEvent.Change && isRecord(picked)) truncate(picked.payload);

    const text = JSON.stringify(picked);
    if (text.length > MAX_PAYLOAD) return unsendable(event, payload);
    return JSON.parse(text) as object;
  } catch {
    return unsendable(event, payload);
  }
}
