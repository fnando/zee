import { defineConfig } from "eslint/config";
import globals from "globals";
import js from "@eslint/js";
import tseslint from "typescript-eslint";

const files = ["app/**/*.{js,mjs,cjs,ts}"];

export default defineConfig([
  { ignores: ["public/**/*"] },
  { files },
  { files: ["app/**/*.js"], languageOptions: { sourceType: "script" } },
  { files, languageOptions: { globals: globals.browser } },
  { files, plugins: { js }, extends: ["js/recommended"] },
  tseslint.configs.recommended,
]);
