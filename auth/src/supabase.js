import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY,
);

export const APP_SCHEME = import.meta.env.VITE_APP_SCHEME || 'skillpay';

/**
 * Parse Supabase token from either:
 *   - Hash fragment:  #access_token=...&type=...  (older email links)
 *   - Query string:   ?code=...&type=...           (PKCE flow, newer)
 */
export function parseAuthParams() {
  const hash = new URLSearchParams(window.location.hash.replace('#', ''));
  const query = new URLSearchParams(window.location.search);

  return {
    code: query.get('code'),
    token: hash.get('access_token') || query.get('access_token'),
    refreshToken: hash.get('refresh_token') || query.get('refresh_token'),
    type: hash.get('type') || query.get('type'),
    error: hash.get('error') || query.get('error'),
    errorDescription:
      hash.get('error_description') || query.get('error_description'),
  };
}

/**
 * Build a deep link to reopen the Flutter app.
 * e.g. skillpay://auth/confirmed
 */
export function buildDeepLink(path, params = {}) {
  const qs = new URLSearchParams(params).toString();
  return `${APP_SCHEME}://${path}${qs ? '?' + qs : ''}`;
}
