import { describe, it, expect, jest, beforeEach } from '@jest/globals';

import { hostBridge } from '../bridge';
import { FieldEvent, FormEvent } from '../protocol';

const mockEmitFieldEvent = jest.fn();
const mockEmitFormEvent = jest.fn();
let mockCommandHandler: ((event: unknown) => void) | null = null;
const mockRemove = jest.fn(() => {
  mockCommandHandler = null;
});

jest.mock('../../../specs/NativeHyperPaymentMethods', () => ({
  __esModule: true,
  default: {
    emitFieldEvent: (...args: unknown[]) => mockEmitFieldEvent(...args),
    emitFormEvent: (...args: unknown[]) => mockEmitFormEvent(...args),
    onCommand: (handler: (event: unknown) => void) => {
      mockCommandHandler = handler;
      return { remove: mockRemove };
    },
  },
}));

beforeEach(() => {
  mockEmitFieldEvent.mockClear();
  mockEmitFormEvent.mockClear();
  mockRemove.mockClear();
});

describe('hostBridge', () => {
  it('sends events through its own module, filtered by the wire rules', () => {
    hostBridge.emitField(7, FieldEvent.Change, {
      elementType: 'cardCvc',
      empty: false,
      complete: true,
      valid: true,
      touched: true,
      value: '737',
    });
    expect(mockEmitFieldEvent).toHaveBeenCalledWith(7, 'PM_FIELD_CHANGE', {
      elementType: 'cardCvc',
      empty: false,
      complete: true,
      valid: true,
      touched: true,
    });

    hostBridge.emitForm(5, FormEvent.Error, {
      message: 'nope',
      cause: { number: '4242424242424242' },
    });
    expect(mockEmitFormEvent).toHaveBeenCalledWith(5, 'PM_FORM_ERROR', {
      message: 'nope',
    });
  });

  it('reads providerData out of its JSON text', () => {
    const listener = jest.fn();
    hostBridge.onCommand(listener);

    mockCommandHandler?.({
      rootTag: 5,
      formId: 'form-1',
      commandId: 'c1',
      name: 'tokenize',
      providerData: '{"routeId":"r_1"}',
    });
    expect(listener).toHaveBeenLastCalledWith({
      rootTag: 5,
      formId: 'form-1',
      commandId: 'c1',
      name: 'tokenize',
      elementType: undefined,
      providerData: { routeId: 'r_1' },
    });

    mockCommandHandler?.({
      rootTag: 5,
      formId: 'form-1',
      commandId: 'c2',
      name: 'tokenize',
      providerData: '{not json',
    });
    expect(listener).toHaveBeenLastCalledWith(
      expect.objectContaining({ commandId: 'c2', providerData: undefined })
    );
  });

  it('drops a command nobody could be answered for, and stops when asked', () => {
    const listener = jest.fn();
    const stop = hostBridge.onCommand(listener);

    mockCommandHandler?.({ formId: 'form-1', commandId: 'c1', name: 'tokenize' });
    mockCommandHandler?.({
      rootTag: 5,
      formId: 'form-1',
      commandId: '',
      name: 'tokenize',
    });
    expect(listener).not.toHaveBeenCalled();

    stop();
    expect(mockRemove).toHaveBeenCalledTimes(1);
  });
});
