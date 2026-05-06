# Microsoft To Do MCP — Setup Guide

This MCP wraps [jordanburke/microsoft-todo-mcp-server](https://github.com/jordanburke/microsoft-todo-mcp-server) (unmodified) and gives Claude Code access to a personal Microsoft To Do account via Microsoft Graph.

This guide is written so a fresh Claude agent on a new machine (with this repo cloned) can replicate the setup end-to-end.

## Prerequisites

- This repo cloned. Working directory: `<repo>` (referred to as `/workspace` below — substitute your actual path).
- Docker + Docker Compose installed.
- Node.js installed on host (for the MCP launcher script — uses built-in `node` to parse the tokens JSON).
- A personal Microsoft account with Microsoft To Do data.
- Browser access on the host machine (for one-time OAuth sign-in at `http://localhost:3000`).

## Architecture

```
[Claude Code on host]
       │ stdio (JSON-RPC)
       ▼
[mcp/microsoft-todo/microsoft_todo_mcp.sh on host]   ── reads working_dir/ms_todo.env
       │ exec                                        ── reads working_dir/ms_todo_tokens.json
       ▼
[npx microsoft-todo-mcp-server on host]
       │ HTTPS
       ▼
[graph.microsoft.com  +  login.microsoftonline.com]
```

The MCP server runs **directly on the host** (not in a container) because Claude Code talks to it over stdio. The `ms-todo-auth` Docker service is a **one-shot** tool used only to obtain tokens.

## Files

| Path | Purpose | Tracked in git? |
|---|---|---|
| `mcp/microsoft-todo/microsoft_todo_mcp.sh` | MCP launcher Claude Code invokes | yes |
| `mcp/microsoft-todo/auth.Dockerfile` | Image for the one-shot auth container | yes |
| `mcp/microsoft-todo/auth-entrypoint.sh` | Runs `pnpm run auth`, watches for tokens.json, copies it out | yes |
| `compose.yml` (service `ms-todo-auth`, profile `auth`) | Compose definition for the auth container | yes |
| `working_dir/ms_todo.env` | `CLIENT_ID`, `CLIENT_SECRET`, `TENANT_ID` | no (gitignored) |
| `working_dir/ms_todo_tokens.json` | OAuth access + refresh tokens | no (gitignored) |

## Step 1 — Azure app registration

Done once per Azure tenant. If a registration already exists from a previous machine, reuse the same `CLIENT_ID`/`CLIENT_SECRET` and skip to Step 2.

1. Go to <https://portal.azure.com> → **Microsoft Entra ID** → **App registrations** → **New registration**.
2. **Name**: anything (e.g. `microsoft-todo-mcp`).
3. **Supported account types**: **Personal Microsoft accounts only** (or "any org and personal" if needed).
4. **Redirect URI**: select **Web** platform, value `http://localhost:3000/callback`. Click **Register**.
5. On the app overview page, copy the **Application (client) ID** → this is `CLIENT_ID`.
6. **Certificates & secrets** → **Client secrets** → **New client secret**. Copy the **Value** immediately (not visible later) → this is `CLIENT_SECRET`.
7. **API permissions** → **Add a permission** → **Microsoft Graph** → **Delegated permissions**. Add: `Tasks.ReadWrite`, `offline_access`, `User.Read`.
8. `TENANT_ID` for personal Microsoft accounts: literal string `consumers`.

## Step 2 — Create env file

Create `working_dir/ms_todo.env`:

```
CLIENT_ID=<application-client-id-from-step-1>
CLIENT_SECRET=<client-secret-value-from-step-1>
TENANT_ID=consumers
```

`REDIRECT_URI` is set by the compose service; do not include it here.

## Step 3 — Run the auth container to obtain tokens

```bash
docker compose --profile auth up --build ms-todo-auth
```

Expected behavior:
1. Image builds (clones upstream repo, `pnpm install`, `pnpm run build`).
2. Container starts and prints: `Open http://localhost:3000 in your host browser to begin sign-in.`
3. You open `http://localhost:3000` in your host browser.
4. Microsoft sign-in flow → consent screen → redirect to `localhost:3000/callback`.
5. Container detects `tokens.json` was written, copies it to `working_dir/ms_todo_tokens.json`, prints `Saved tokens to working_dir/ms_todo_tokens.json`, and exits cleanly.

If the container exits with `Auth server exited before tokens.json was written`, see troubleshooting.

## Step 4 — Register the MCP with Claude Code

```bash
claude mcp add microsoft-todo /workspace/mcp/microsoft-todo/microsoft_todo_mcp.sh
```

(Replace `/workspace` with the absolute path to this repo.)

Restart Claude Code (or `/mcp` → reconnect). The `microsoft-todo` server should appear with 13 tools: `auth-status`, `get-task-lists`, `create-task-list`, `update-task-list`, `delete-task-list`, `get-tasks`, `create-task`, `update-task`, `delete-task`, `get-checklist-items`, `create-checklist-item`, `update-checklist-item`, `delete-checklist-item`.

## Step 5 — Verify (optional)

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"x","version":"0"}}}' \
  | /workspace/mcp/microsoft-todo/microsoft_todo_mcp.sh 2>&1 | head -5
```

Should print a JSON-RPC response with `serverInfo`. Errors here usually mean missing env file or tokens file.

## Token lifecycle

- **Access token**: 1 hour. Refreshed automatically in-memory by the MCP server process (~5 min before expiry, or on a 401).
- **Refresh token**: ~90 days of inactivity. As long as the MCP server uses it at least every 90 days, it auto-renews. If it lapses, password changes, or admin revokes the session — re-run Step 3.
- Refreshed tokens stay in memory only; the on-disk `ms_todo_tokens.json` is not updated. This is fine because the original refresh token remains valid throughout its 90-day window.

## Troubleshooting

**`Cannot find module '/app/dist/auth-server.js'`**
The upstream package wasn't built. Ensure `auth.Dockerfile` runs `pnpm run build`. Rebuild with `--build`.

**`AADSTS90023: Public clients can't send a client secret`**
Tokens were minted via device code flow (public client) but refresh is sending a secret (confidential). This setup explicitly avoids that — make sure you obtained tokens via the auth container in Step 3, not via any other device-code flow. Re-run Step 3 if unsure.

**`Missing /workspace/working_dir/ms_todo.env`**
You skipped Step 2. Create the file.

**`Missing /workspace/working_dir/ms_todo_tokens.json`**
You skipped Step 3, or the container exited before writing. Re-run Step 3.

**Browser redirect goes to `localhost:3000/callback` and shows connection refused**
The auth container exited (auth completed) before the browser finished loading the response. Check the host filesystem — `working_dir/ms_todo_tokens.json` likely already exists. The auth flow itself succeeded.

**MCP server starts but tool calls fail with 401**
Refresh token has expired or been revoked. Re-run Step 3.

**Refresh fails after 1 hour**
Re-run Step 3 to mint fresh tokens. If it persistently fails, confirm the Azure app registration matches Step 1 (especially: redirect URI is registered as **Web** platform, not SPA or public client).

## Replicating on a new machine

1. Clone this repo.
2. Copy `working_dir/ms_todo.env` from the original machine (or recreate it with the same `CLIENT_ID`/`CLIENT_SECRET` from Azure — they are reusable across machines).
3. **Do not** copy `working_dir/ms_todo_tokens.json` between machines unless you are sure no other machine is actively using it. Easier: re-run Step 3 on the new machine to mint fresh tokens.
4. Run Step 4 to register with Claude Code on the new machine.
