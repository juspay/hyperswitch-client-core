export interface Deferred<T> {
  readonly promise: Promise<T>;

  readonly settled: boolean;
  resolve(value: T): void;
  reject(reason?: unknown): void;
}

export function createDeferred<T>(): Deferred<T> {
  let resolveFn!: (value: T) => void;
  let rejectFn!: (reason?: unknown) => void;
  let settled = false;

  const promise = new Promise<T>((resolve, reject) => {
    resolveFn = resolve;
    rejectFn = reject;
  });

  return {
    promise,
    get settled() {
      return settled;
    },
    resolve(value: T) {
      if (settled) return;
      settled = true;
      resolveFn(value);
    },
    reject(reason?: unknown) {
      if (settled) return;
      settled = true;
      rejectFn(reason);
    },
  };
}
