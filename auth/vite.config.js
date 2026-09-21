import { defineConfig } from 'vite';

export default defineConfig({
  preview: {
    // Allow Railway domain and custom domains
    allowedHosts: [
      'skillspays.com',
      'auth.skillspays.com',
      '.skillspays.com',
      '.railway.app', // wildcard for all railway subdomains
    ],
    host: '0.0.0.0',
    port: process.env.PORT ? parseInt(process.env.PORT) : 4173,
  },
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        confirm: 'confirm.html',
        reset: 'reset-password.html',
        magic: 'magic-link.html',
      },
    },
  },
});
