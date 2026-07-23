// Root page — redirect based on auth type in URL params
import { parseAuthParams, buildDeepLink } from './supabase.js';

const { type, code, token } = parseAuthParams();

if (type === 'signup' || type === 'email_change') {
  window.location.replace('/confirm.html' + window.location.search + window.location.hash);
} else if (type === 'recovery') {
  window.location.replace('/reset-password.html' + window.location.search + window.location.hash);
} else if (type === 'magiclink' || type === 'invite') {
  window.location.replace('/magic-link.html' + window.location.search + window.location.hash);
} else if (code || token) {
  // Generic fallback — try confirm page
  window.location.replace('/confirm.html' + window.location.search + window.location.hash);
}
