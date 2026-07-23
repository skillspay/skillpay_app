import { defineConfig } from 'vite';

export default defineConfig({
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
