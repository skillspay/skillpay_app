import { defineConfig } from 'vite';

export default defineConfig({
  preview: {
    // Allow Railway domain and your custom domain
    allowedHosts: [
      'auth.skillspays.com',
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
