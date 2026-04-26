#!/usr/bin/env node
// Generates a GitHub App installation access token.
// Usage: GITHUB_APP_ID=<id> node get_github_token.mjs <installation_id>

import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const appId = process.env.GITHUB_APP_ID;
const installationId = process.argv[2];

if (!appId || !installationId) {
  console.error('Usage: GITHUB_APP_ID=<id> node get_github_token.mjs <installation_id>');
  process.exit(1);
}

const privateKey = readFileSync('/workspace/working_dir/github_app_key.pem', 'utf8');

function base64url(data) {
  return Buffer.from(data).toString('base64')
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function createJWT() {
  const now = Math.floor(Date.now() / 1000);
  const header  = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = base64url(JSON.stringify({ iat: now - 60, exp: now + 600, iss: appId }));
  const body = `${header}.${payload}`;
  const sig = createSign('RSA-SHA256');
  sig.update(body);
  const signature = sig.sign(privateKey, 'base64')
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
  return `${body}.${signature}`;
}

const res = await fetch(
  `https://api.github.com/app/installations/${installationId}/access_tokens`,
  {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${createJWT()}`,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  }
);

if (!res.ok) {
  console.error(`GitHub API error ${res.status}: ${await res.text()}`);
  process.exit(1);
}

const { token } = await res.json();
process.stdout.write(token);
