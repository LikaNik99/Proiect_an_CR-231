import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/api/, ""),
      },
      "/auth": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
      },
      "/availability": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
      },
      "/reservations": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
      },
      "/admin": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
      },
      "/restaurants": {
        target: "http://localhost:8080",
        changeOrigin: true,
        secure: false,
      },
    },
  },
});
