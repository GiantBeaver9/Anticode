import { defineConfig } from "vite";
import { svelte } from "@sveltejs/vite-plugin-svelte";

// The C# backend serves the built SPA out of server/wwwroot, so build there.
// In dev, proxy API calls to the ASP.NET Core server.
export default defineConfig({
  plugins: [svelte()],
  build: {
    outDir: "../server/wwwroot",
    emptyOutDir: true,
  },
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:5059",
        changeOrigin: true,
      },
    },
  },
});
