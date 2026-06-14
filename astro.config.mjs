import { defineConfig } from "astro/config";
import preact from "@astrojs/preact";

export default defineConfig({
  site: 'https://mazendesouki.github.io/netlify-feature-tour',
  integrations: [
    preact(),
  ],
});
