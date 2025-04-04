import { defineConfig } from "eslint/config";
import globals from "globals";
import js from "@eslint/js";

const files = ["app/**/*.{js,mjs,cjs}"];

export default defineConfig([
  { ignores: ["public/**/*"] },
  { files },
  { files, languageOptions: { globals: globals.browser } },
  { files, plugins: { js }, extends: ["js/recommended"] },
]);
