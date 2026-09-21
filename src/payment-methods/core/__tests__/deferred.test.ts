import { describe, it, expect } from '@jest/globals';
import { createDeferred } from '../deferred';

describe('createDeferred', () => {
  it('resolves the promise with the provided value', async () => {
    const d = createDeferred<number>();
    d.resolve(42);
    await expect(d.promise).resolves.toBe(42);
  });

  it('rejects the promise with the provided error', async () => {
    const d = createDeferred<number>();
    const err = new Error('boom');
    d.reject(err);
    await expect(d.promise).rejects.toBe(err);
  });

  it('starts unsettled and reports settled after resolve', () => {
    const d = createDeferred<void>();
    expect(d.settled).toBe(false);
    d.resolve();
    expect(d.settled).toBe(true);
  });

  it('keeps the first settlement (resolve after resolve is ignored)', async () => {
    const d = createDeferred<number>();
    d.resolve(1);
    d.resolve(2);
    await expect(d.promise).resolves.toBe(1);
  });
});
