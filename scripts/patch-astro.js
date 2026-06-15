// Removes the missing hc_light theme reference from Astro 2.10.15's shiki-themes.js
// This theme does not exist in the bundled shiki version, causing the build to fail.
const fs = require('fs');
const path = require('path');

const file = path.join(__dirname, '..', 'node_modules', 'astro', 'components', 'shiki-themes.js');
if (!fs.existsSync(file)) {
  console.log('patch-astro: shiki-themes.js not found, skipping.');
  process.exit(0);
}

let content = fs.readFileSync(file, 'utf8');
if (content.includes("'hc_light'")) {
  content = content.replace(/\t'hc_light':.*\n/, '');
  fs.writeFileSync(file, content);
  console.log('patch-astro: removed hc_light from shiki-themes.js');
} else {
  console.log('patch-astro: hc_light already absent, nothing to do.');
}
