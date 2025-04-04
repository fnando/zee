import { defineConfig } from "vite";
import path from "path";
import { globSync } from "fs";

function entrypoints(strip = false) {
  return globSync("app/assets/scripts/*.{js,ts}").reduce((buffer, entry) => {
    entry = path.join(__dirname, entry);
    const name = path.basename(entry, path.extname(entry));
    return Object.assign(buffer, {
      [name]: strip ? path.join(path.dirname(entry), name) : entry,
    });
  }, {});
}

export default defineConfig({
  build: {
    sourcemap: true,
    minify: true,
    outDir: "public/assets/scripts",
    emptyOutDir: true,
    copyPublicDir: false,
    rollupOptions: {
      input: entrypoints(),
      output: {
        entryFileNames: "[name].js",
      },
    },
  },
  resolve: {
    alias: entrypoints(true),
  },
});
