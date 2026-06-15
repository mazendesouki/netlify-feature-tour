# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev        # Start dev server (port 3000 by default)
netlify dev        # Start dev server with Netlify Functions support (preferred)
npm run build      # Production build → dist/
npm run preview    # Preview the production build locally
```

There is no test suite or linter configured.

## Architecture

This is an **Astro 2.x** static site with two distinct layers:

1. **Netlify feature tour demo** — the original purpose of this repo. A few pages (`/deploy-previews`, `/instant-rollbacks`, `/functions`, `/netlify-forms`, `/success`) use `src/components/layout.astro` as their base shell and demonstrate Netlify platform features.

2. **Wslha (وصله) app** — a full Arabic delivery/ride-sharing UI prototype layered on top. All other pages (`/`, `/login`, `/register`, `/delivery`, `/rides`, `/orders`, `/wallet`, `/tracking`, `/settings`, `/admin/*`, etc.) are standalone `.astro` files that are self-contained HTML pages — they do **not** use `src/components/layout.astro`.

### Page conventions

Each Wslha page is a complete `<!DOCTYPE html>` document inside an `.astro` file. They share these patterns:

- **RTL Arabic** throughout: `<html lang="ar" dir="rtl">`, Google Fonts Cairo loaded via `<link>`.
- **Inline `<style>` blocks** — each page carries its own styles; shared tokens live in `public/global.css` (Netlify design tokens) and `public/wslha.css`.
- **Inline `<script>` blocks** — client-side interactivity (form validation, toast notifications, modals, navigation) lives in a `<script>` tag at the bottom of each page. There is no JS build pipeline — these scripts run as-is in the browser.
- **No component reuse** among Wslha pages. Patterns like the top nav, bottom tab bar, and toast notifications are copy-pasted across files.

### Astro config

`astro.config.mjs` registers two integrations:
- `@astrojs/preact` — enables `.jsx` components (only used by `src/components/function-tester.jsx`)
- `@astrojs/sitemap` — auto-generates sitemap at build time

The only Preact/JSX component is `src/components/function-tester.jsx`, which fetches `/.netlify/functions/hello-world` and renders a button UI.

### Netlify Functions

`netlify/functions/` is empty (only `.gitkeep`). The `/functions` demo page documents how to add functions here — none are implemented yet.

### Styling system

`public/global.css` defines CSS custom properties for the Netlify design system (color scales `--blue-100` through `--blue-900`, spacing, border-radius tokens). Wslha pages use a separate blue/teal primary palette defined inline and via `public/wslha.css`. The two systems coexist but do not share tokens.

### Deployment

- **Netlify** (primary): https://feature-tour.netlify.app — auto-deploys from the main branch.
- **GitHub Pages** (secondary): `.github/workflows/static.yml` deploys on push to `main`.
- `public/_redirects` is present but empty — add Netlify redirect rules there if needed.
