import { useState } from 'react';
import { post, patch, destroy } from '@rails/request.js';

interface UseApiRequestOptions {
  onSuccess?: (data: any) => void;
  onError?: (error: string, errors?: Record<string, string[]>) => void;
}

// Helper function to transform snake_case keys to camelCase
const transformErrorKeys = (errors: Record<string, string[]>): Record<string, string[]> => {
  const transformed: Record<string, string[]> = {};
  for (const [key, value] of Object.entries(errors)) {
    const camelKey = key.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
    transformed[camelKey] = value;
  }
  return transformed;
};

export const useApiRequest = (options: UseApiRequestOptions = {}) => {
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string[]>>({});

  const makeRequest = async (
    method: 'POST' | 'PATCH' | 'DELETE',
    url: string,
    data?: any
  ) => {
    setLoading(true);
    setErrors({});

    try {
      // Get CSRF token from meta tag
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
      
      const requestFn = method === 'POST' ? post : method === 'PATCH' ? patch : destroy;
      const response = await requestFn(url, {
        body: JSON.stringify(data),
        contentType: 'application/json',
        headers: {
          'X-CSRF-Token': csrfToken || ''
        }
      });

      if (response.ok) {
        // For DELETE requests, there might be no response body
        const result = method === 'DELETE' ? null : await response.json;
        options.onSuccess?.(result);
        return result;
      } else {
        // Try to parse error response for validation errors
        try {
          const errorResult = await response.json;
          if (errorResult.errors) {
            const transformedErrors = transformErrorKeys(errorResult.errors);
            setErrors(transformedErrors);
            options.onError?.('Validation failed', transformedErrors);
            throw new Error('Validation failed');
          }
        } catch (parseError) {
          // If we can't parse the response, fall through to network error
        }
        throw new Error('Network error');
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'An error occurred';
      if (errorMsg !== 'Validation failed') {
        options.onError?.(errorMsg);
      }
      throw err;
    } finally {
      setLoading(false);
    }
  };

  const getFieldError = (fieldName: string): string | undefined => {
    return errors[fieldName]?.[0];
  };

  const getBaseErrors = (): string[] => {
    return errors.base || [];
  };

  const hasErrors = (): boolean => {
    return Object.keys(errors).length > 0;
  };

  return {
    loading,
    errors,
    makeRequest,
    getFieldError,
    getBaseErrors,
    hasErrors,
    clearErrors: () => setErrors({})
  };
};
