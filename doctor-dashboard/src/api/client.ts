import type { ProblemDetails } from './types';

export class ApiError extends Error {
  public status: number;
  public details?: ProblemDetails;

  constructor(status: number, message: string, details?: ProblemDetails) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.details = details;
  }
}

const TOKEN_KEY = 'mindora_doctor_token';
const USER_KEY = 'mindora_doctor_user';

type UnauthorizedCallback = () => void;
const unauthorizedListeners: Set<UnauthorizedCallback> = new Set();

export const onUnauthorized = (cb: UnauthorizedCallback): (() => void) => {
  unauthorizedListeners.add(cb);
  return () => unauthorizedListeners.delete(cb);
};

export const getStoredToken = (): string | null => {
  try {
    return localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
};

export const setStoredToken = (token: string): void => {
  try {
    localStorage.setItem(TOKEN_KEY, token);
  } catch (err) {
    console.warn('Failed to store token in localStorage', err);
  }
};

export const clearStoredAuth = (): void => {
  try {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
  } catch (err) {
    console.warn('Failed to clear auth in localStorage', err);
  }
};

const getBaseUrl = (): string => {
  const envUrl = import.meta.env.VITE_API_BASE_URL;
  if (envUrl && typeof envUrl === 'string' && envUrl.trim().length > 0) {
    return envUrl.trim().replace(/\/+$/, '');
  }
  return '';
};

export interface RequestOptions extends RequestInit {
  skipAuth?: boolean;
}

export const request = async <T>(endpoint: string, options: RequestOptions = {}): Promise<T> => {
  const baseUrl = getBaseUrl();
  const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  const url = `${baseUrl}${normalizedEndpoint}`;

  const headers = new Headers(options.headers || {});

  if (!headers.has('X-Client-Platform')) {
    headers.set('X-Client-Platform', 'DoctorDashboard');
  }

  if (!options.skipAuth) {
    const token = getStoredToken();
    if (token && !headers.has('Authorization')) {
      headers.set('Authorization', `Bearer ${token}`);
    }
  }

  if (!headers.has('Content-Type') && options.body && !(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  if (!headers.has('Accept')) {
    headers.set('Accept', 'application/json');
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  // Centralized 401 Unauthorized handling
  if (response.status === 401) {
    clearStoredAuth();
    unauthorizedListeners.forEach((cb) => {
      try {
        cb();
      } catch (e) {
        console.error('Error in unauthorized listener', e);
      }
    });
    throw new ApiError(401, 'انتهت صلاحية الجلسة أو غير مصرح، يرجى تسجيل الدخول مجدداً.');
  }

  // Parse response body
  let data: unknown = null;
  const contentType = response.headers.get('content-type') || '';
  if (contentType.includes('json') || contentType.includes('+json')) {
    try {
      data = await response.json();
    } catch {
      data = null;
    }
  }

  if (data === null) {
    try {
      const text = await response.text();
      if (text && text.trim().length > 0) {
        try {
          data = JSON.parse(text);
        } catch {
          data = text;
        }
      }
    } catch {
      data = null;
    }
  }

  if (!response.ok) {
    let message = '';
    let problem: ProblemDetails | null = null;

    if (data && typeof data === 'object') {
      problem = data as ProblemDetails;
      if (problem.errors && typeof problem.errors === 'object') {
        const errorValues = Object.values(problem.errors);
        const flattened = errorValues
          .flatMap((err) => (Array.isArray(err) ? err : [err]))
          .filter((err): err is string => typeof err === 'string' && err.trim().length > 0);

        if (flattened.length > 0) {
          message = flattened.join(' ');
        }
      }

      if (!message) {
        if (problem.detail && typeof problem.detail === 'string' && problem.detail.trim().length > 0) {
          message = problem.detail.trim();
        } else if (problem.title && typeof problem.title === 'string' && problem.title.trim().length > 0) {
          message = problem.title.trim();
        } else if ('message' in (data as Record<string, unknown>)) {
          const rawMsg = (data as Record<string, unknown>).message;
          if (typeof rawMsg === 'string' && rawMsg.trim().length > 0) {
            message = rawMsg.trim();
          }
        }
      }
    } else if (typeof data === 'string' && data.trim().length > 0) {
      message = data.trim();
    }

    if (!message) {
      if (response.status === 400) {
        message = 'البيانات المدخلة غير صحيحة، يرجى مراجعة الحقول المدخلة.';
      } else if (response.status === 403) {
        message = 'غير مصرح لك بالوصول أو الحساب غير مؤكد.';
      } else if (response.status === 404) {
        message = 'المورد المطلوب غير موجود.';
      } else if (response.status === 409) {
        message = 'هذا البريد الإلكتروني مسجل بالفعل في المنصة.';
      } else if (response.status >= 500) {
        message = 'حدث خطأ في الخادم أثناء معالجة الطلب، يرجى المحاولة لاحقاً.';
      } else {
        message = 'حدث خطأ أثناء معالجة الطلب.';
      }
    }

    throw new ApiError(response.status, message, problem || undefined);
  }

  return data as T;
};

export const apiClient = {
  get: <T>(endpoint: string, options?: RequestOptions) =>
    request<T>(endpoint, { ...options, method: 'GET' }),

  post: <T>(endpoint: string, body?: unknown, options?: RequestOptions) =>
    request<T>(endpoint, {
      ...options,
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    }),

  put: <T>(endpoint: string, body?: unknown, options?: RequestOptions) =>
    request<T>(endpoint, {
      ...options,
      method: 'PUT',
      body: body ? JSON.stringify(body) : undefined,
    }),

  delete: <T>(endpoint: string, options?: RequestOptions) =>
    request<T>(endpoint, { ...options, method: 'DELETE' }),
};
