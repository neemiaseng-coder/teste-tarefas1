// Run: node --test tests/regression.test.mjs
// Read-only checks. These do not replace browser/device or authenticated integration tests.
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const html = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const worker = readFileSync(new URL('../sw.js', import.meta.url), 'utf8');
const manifest = JSON.parse(readFileSync(new URL('../manifest.webmanifest', import.meta.url), 'utf8'));

test('inline JavaScript parses', () => {
  const scripts = [...html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)]
    .filter(match => !/\bsrc\s*=/.test(match[1]));
  assert.ok(scripts.length > 0);
  for (const script of scripts) new vm.Script(script[2]);
});

test('service worker parses and uses versioned cache', () => {
  new vm.Script(worker);
  assert.match(worker, /const CACHE=['"][^'"]+v\d+['"]/);
});

test('PWA manifest uses local start URL and standalone display', () => {
  assert.equal(manifest.display, 'standalone');
  assert.equal(manifest.start_url, './');
  assert.ok(manifest.icons.length > 0);
});

test('login uses Supabase Auth and does not expose service role', () => {
  assert.match(html, /signInWithPassword/);
  assert.match(html, /auth\.getSession/);
  assert.match(html, /auth\.signOut/);
  assert.doesNotMatch(html, /sb_secret_[a-zA-Z0-9]+|service_role\s*[:=]\s*['"]/);
});

test('finance operations and notifications are present', () => {
  for (const name of ['financial_entries','finance_categories','finance_notifications','finance_user_preferences']) {
    assert.ok(html.includes(name), name);
  }
  assert.match(html, /function renderForecast/);
  assert.match(html, /function renderNotifications/);
});

test('biometric local gate is not represented as server-verified passkey auth', () => {
  assert.match(html, /navigator\.credentials\.get/);
  assert.match(html, /Bloqueio biométrico local/);
});

test('password form and accessibility controls exist', () => {
  assert.match(html, /id="loginForm"/);
  assert.match(html, /id="password"/);
  assert.match(html, /id="biometricFallback"/);
});
