import { supabase } from './supabase';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api/v1';

async function getAuthToken(): Promise<string | null> {
  const { data } = await supabase.auth.getSession();
  return data.session?.access_token || null;
}

export async function request(path: string, options: RequestInit = {}) {
  const token = await getAuthToken();
  const headers = new Headers(options.headers || {});
  
  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }
  
  if (!(options.body instanceof FormData) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const errorText = await response.text();
    let errorMessage = `HTTP error! status: ${response.status}`;
    try {
      const parsed = JSON.parse(errorText);
      errorMessage = parsed.message || errorMessage;
    } catch {
      // Not JSON
    }
    throw new Error(errorMessage);
  }

  if (response.status === 204) return null;
  const json = await response.json();
  
  // Unwrap the NestJS TransformInterceptor envelope globally
  if (json && json.success === true && 'data' in json) {
    return json.data;
  }
  return json;
}

export const api = {
  auth: {
    syncUser: () => request('/auth/login', { method: 'POST' }),
    getProfile: () => request('/auth/me'),
  },
  users: {
    list: (page = 1, limit = 10, role?: string, status?: string) => {
      let query = `?page=${page}&limit=${limit}`;
      if (role) query += `&role=${role}`;
      if (status) query += `&status=${status}`;
      return request(`/users${query}`);
    },
    get: (id: string) => request(`/users/${id}`),
    suspend: (id: string) => request(`/users/${id}/suspend`, { method: 'PATCH' }),
    ban: (id: string) => request(`/users/${id}/ban`, { method: 'PATCH' }),
    activate: (id: string) => request(`/users/${id}/activate`, { method: 'PATCH' }),
    getStats: () => request('/users/stats'),
  },
  artisans: {
    listPendingVerifications: () => request('/admin/verifications/pending'),
    verifyDocument: (id: string, status: 'VERIFIED' | 'REJECTED', adminNote?: string) =>
      request(`/admin/verifications/${id}`, {
        method: 'POST',
        body: JSON.stringify({ status, adminNote }),
      }),
  },
  categories: {
    list: () => request('/categories'),
    create: (data: { name: string; icon?: string; description?: string }) =>
      request('/categories', {
        method: 'POST',
        body: JSON.stringify(data),
      }),
    update: (id: string, data: { name?: string; icon?: string; description?: string; isActive?: boolean }) =>
      request(`/categories/${id}`, {
        method: 'PATCH',
        body: JSON.stringify(data),
      }),
  },
  bookings: {
    list: () => request('/admin/bookings'),
    get: (id: string) => request(`/bookings/${id}`),
  },
  payments: {
    list: () => request('/admin/payments'),
    getStats: () => request('/admin/payments/stats'),
  },
  reports: {
    list: () => request('/admin/reports'),
    resolve: (id: string, adminNote: string) =>
      request(`/admin/reports/${id}/resolve`, {
        method: 'POST',
        body: JSON.stringify({ adminNote }),
      }),
    dismiss: (id: string, adminNote: string) =>
      request(`/admin/reports/${id}/dismiss`, {
        method: 'POST',
        body: JSON.stringify({ adminNote }),
      }),
  },
};
