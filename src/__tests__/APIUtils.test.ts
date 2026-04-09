import { fetchApi, handleApiCall, fetchApiWrapper } from '../utility/logics/APIUtils.bs.js';

jest.mock('../hooks/WebKit.bs.js', () => ({
  platformString: 'web',
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getJsonObjectFromRecord: jest.fn((record: Record<string, unknown>) => record),
  getError: jest.fn((err: unknown, defaultError: string) => defaultError),
}));

describe('APIUtils', () => {
  let mockFetch: jest.Mock;

  beforeEach(() => {
    mockFetch = global.fetch as jest.Mock;
    mockFetch.mockClear();
    mockFetch.mockReset();
  });

  describe('fetchApi', () => {
    it('makes GET request without body', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ data: 'test' }),
      });

      const result = await fetchApi('https://api.example.com/test', undefined, {}, 'GET', undefined, undefined);

      expect(mockFetch).toHaveBeenCalledTimes(1);
      const [url, options] = mockFetch.mock.calls[0];
      expect(url).toBe('https://api.example.com/test');
      expect(options.method).toBe('GET');
      expect(options.body).toBeUndefined();
    });

    it('makes POST request with body', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ success: true }),
      });

      const result = await fetchApi(
        'https://api.example.com/create',
        '{"name":"test"}',
        {},
        'POST',
        undefined,
        undefined
      );

      expect(mockFetch).toHaveBeenCalledTimes(1);
      const [url, options] = mockFetch.mock.calls[0];
      expect(url).toBe('https://api.example.com/create');
      expect(options.method).toBe('POST');
      expect(options.body).toBe('{"name":"test"}');
    });

    it('adds default headers when dontUseDefaultHeader is false', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApi('https://api.example.com/test', '', {}, 'POST', undefined, false);

      const options = mockFetch.mock.calls[0][1];
      const headers = options.headers;
      expect(headers.get('Content-Type')).toBe('application/json');
      expect(headers.get('X-Client-Platform')).toBe('web');
    });

    it('does not add default headers when dontUseDefaultHeader is true', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApi('https://api.example.com/test', '', {}, 'POST', undefined, true);

      const options = mockFetch.mock.calls[0][1];
      expect(options.headers.get('Content-Type')).toBeNull();
    });

    it('merges custom headers with default headers', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApi(
        'https://api.example.com/test',
        '',
        { 'X-Custom-Header': 'custom-value' },
        'POST',
        undefined,
        false
      );

      const options = mockFetch.mock.calls[0][1];
      const headers = options.headers;
      expect(headers.get('X-Custom-Header')).toBe('custom-value');
      expect(headers.get('Content-Type')).toBe('application/json');
    });

    it('handles fetch network error', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      await expect(fetchApi('https://api.example.com/test', '', {}, 'GET', undefined, undefined)).rejects.toMatchObject({
        RE_EXN_ID: expect.anything(),
        _1: expect.any(String),
      });
    });

    it('uses empty string as default body', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApi('https://api.example.com/test', undefined, undefined, 'POST', undefined, undefined);

      const options = mockFetch.mock.calls[0][1];
      expect(options.body).toBe('');
    });

    it('uses empty object as default headers', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApi('https://api.example.com/test', '', undefined, 'POST', undefined, false);

      const options = mockFetch.mock.calls[0][1];
      expect(options.headers).toBeDefined();
    });

    it('returns Response object on success', async () => {
      const mockResponse = {
        status: 200,
        json: () => Promise.resolve({ data: 'success' }),
      };
      mockFetch.mockResolvedValueOnce(mockResponse);

      const result = await fetchApi('https://api.example.com/test', '', {}, 'GET', undefined, undefined);

      expect(result).toBe(mockResponse);
    });
  });

  describe('handleApiCall', () => {
    const mockApiLogWrapper = jest.fn();
    const mockProcessSuccess = jest.fn((json) => ({ success: true, data: json }));
    const mockProcessError = jest.fn((error) => ({ error: true, details: error }));
    const mockProcessCatch = jest.fn(() => ({ caught: true }));

    beforeEach(() => {
      mockApiLogWrapper.mockClear();
      mockProcessSuccess.mockClear();
      mockProcessError.mockClear();
      mockProcessCatch.mockClear();
    });

    it('handles successful API call with 2xx status', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ id: 123, name: 'test' }),
      });

      const result = await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(result).toEqual({ success: true, data: { id: 123, name: 'test' } });
      expect(mockProcessSuccess).toHaveBeenCalledWith({ id: 123, name: 'test' });
      expect(mockProcessError).not.toHaveBeenCalled();
      expect(mockProcessCatch).not.toHaveBeenCalled();
    });

    it('logs init event for valid event name', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(mockApiLogWrapper).toHaveBeenCalledWith(
        'INFO',
        'CONFIRM_CALL_INIT',
        'https://api.example.com/test',
        '',
        'Request',
        null,
        undefined,
        undefined,
        undefined
      );
    });

    it('does not log init event for unknown event name', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'UNKNOWN_EVENT',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      const initCall = mockApiLogWrapper.mock.calls.find(
        (call) => call[1] === 'UNKNOWN_EVENT_INIT'
      );
      expect(initCall).toBeUndefined();
    });

    it('handles error response with non-2xx status', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 400,
        json: () => Promise.resolve({ error: 'Bad Request' }),
      });

      const result = await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(result).toEqual({ error: true, details: { error: 'Bad Request' } });
      expect(mockProcessError).toHaveBeenCalledWith({ error: 'Bad Request' });
      expect(mockProcessSuccess).not.toHaveBeenCalled();
    });

    it('logs error response for non-2xx status', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 404,
        json: () => Promise.resolve({ message: 'Not Found' }),
      });

      await handleApiCall(
        'https://api.example.com/notfound',
        undefined,
        {},
        'RETRIEVE_CALL',
        'GET',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      const errorLogCall = mockApiLogWrapper.mock.calls.find(
        (call) => call[0] === 'ERROR'
      );
      expect(errorLogCall).toBeDefined();
      expect(errorLogCall[1]).toBe('RETRIEVE_CALL');
      expect(errorLogCall[2]).toBe('https://api.example.com/notfound');
      expect(errorLogCall[3]).toBe('404');
      expect(errorLogCall[4]).toBe('Err');
    });

    it('handles network/fetch error', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network failure'));

      const result = await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(result).toEqual({ caught: true });
      expect(mockProcessCatch).toHaveBeenCalledWith(null);
    });

    it('logs error with 504 status on network failure', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network failure'));

      await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'SESSIONS_CALL',
        'GET',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      const errorLogCall = mockApiLogWrapper.mock.calls.find(
        (call) => call[0] === 'ERROR'
      );
      expect(errorLogCall).toBeDefined();
      expect(errorLogCall[3]).toBe('504');
      expect(errorLogCall[4]).toBe('NoResponse');
    });

    it('handles 500 server error', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 500,
        json: () => Promise.resolve({ error: 'Internal Server Error' }),
      });

      const result = await handleApiCall(
        'https://api.example.com/test',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(result).toEqual({ error: true, details: { error: 'Internal Server Error' } });
    });

    it('handles 201 Created status as success', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 201,
        json: () => Promise.resolve({ created: true, id: 1 }),
      });

      const result = await handleApiCall(
        'https://api.example.com/create',
        '{"name":"test"}',
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(result).toEqual({ success: true, data: { created: true, id: 1 } });
      expect(mockProcessSuccess).toHaveBeenCalled();
    });

    it('handles 204 No Content status as success', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 204,
        json: () => Promise.resolve(null),
      });

      const result = await handleApiCall(
        'https://api.example.com/delete',
        undefined,
        {},
        'CONFIRM_CALL',
        'DELETE',
        mockApiLogWrapper,
        mockProcessSuccess,
        mockProcessError,
        mockProcessCatch
      );

      expect(mockProcessSuccess).toHaveBeenCalled();
    });
  });

  describe('fetchApiWrapper', () => {
    const mockApiLogWrapper = jest.fn();

    beforeEach(() => {
      mockApiLogWrapper.mockClear();
    });

    it('returns JSON on successful response', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ id: 1, name: 'test' }),
      });

      const result = await fetchApiWrapper(
        'https://api.example.com/data',
        undefined,
        {},
        'RETRIEVE_CALL',
        'GET',
        mockApiLogWrapper
      );

      expect(result).toEqual({ id: 1, name: 'test' });
    });

    it('returns error object on non-2xx response', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 400,
        json: () => Promise.resolve({ message: 'Validation failed' }),
      });

      const result = await fetchApiWrapper(
        'https://api.example.com/invalid',
        undefined,
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper
      );

      expect(result).toEqual({ message: 'Validation failed' });
    });

    it('returns null on network error', async () => {
      mockFetch.mockRejectedValueOnce(new Error('Network error'));

      const result = await fetchApiWrapper(
        'https://api.example.com/error',
        undefined,
        {},
        'CONFIRM_CALL',
        'GET',
        mockApiLogWrapper
      );

      expect(result).toBeNull();
    });

    it('passes body parameter correctly', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ success: true }),
      });

      await fetchApiWrapper(
        'https://api.example.com/create',
        '{"data":"value"}',
        {},
        'CONFIRM_CALL',
        'POST',
        mockApiLogWrapper
      );

      const options = mockFetch.mock.calls[0][1];
      expect(options.body).toBe('{"data":"value"}');
    });

    it('passes headers parameter correctly', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({}),
      });

      await fetchApiWrapper(
        'https://api.example.com/test',
        undefined,
        { 'Authorization': 'Bearer token' },
        'CONFIRM_CALL',
        'GET',
        mockApiLogWrapper
      );

      const options = mockFetch.mock.calls[0][1];
      const headers = options.headers;
      expect(headers.get('Authorization')).toBe('Bearer token');
    });

    it('handles PUT method', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ updated: true }),
      });

      const result = await fetchApiWrapper(
        'https://api.example.com/update',
        '{"name":"updated"}',
        {},
        'CONFIRM_CALL',
        'PUT',
        mockApiLogWrapper
      );

      expect(result).toEqual({ updated: true });
      const options = mockFetch.mock.calls[0][1];
      expect(options.method).toBe('PUT');
    });

    it('handles DELETE method', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ deleted: true }),
      });

      const result = await fetchApiWrapper(
        'https://api.example.com/delete',
        undefined,
        {},
        'CONFIRM_CALL',
        'DELETE',
        mockApiLogWrapper
      );

      expect(result).toEqual({ deleted: true });
      const options = mockFetch.mock.calls[0][1];
      expect(options.method).toBe('DELETE');
    });

    it('calls apiLogWrapper with correct parameters', async () => {
      mockFetch.mockResolvedValueOnce({
        status: 200,
        json: () => Promise.resolve({ data: 'test' }),
      });

      await fetchApiWrapper(
        'https://api.example.com/test',
        undefined,
        {},
        'PAYMENT_METHODS_CALL',
        'GET',
        mockApiLogWrapper
      );

      expect(mockApiLogWrapper).toHaveBeenCalled();
    });
  });
});
