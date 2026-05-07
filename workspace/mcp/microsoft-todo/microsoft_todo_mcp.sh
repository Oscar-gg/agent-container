#!/bin/bash
# Launches the upstream Microsoft To Do MCP server (jordanburke/microsoft-todo-mcp-server)
# unmodified. Reads OAuth credentials from working_dir/ms_todo.env and tokens (obtained
# via the upstream `pnpm run auth` browser flow) from working_dir/ms_todo_tokens.json.
set -eu

ENV_FILE="${MS_TODO_ENV_FILE:-/workspace/working_dir/ms_todo.env}"
TOKEN_FILE="${MS_TODO_TOKEN_FILE:-/workspace/working_dir/ms_todo_tokens.json}"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it with CLIENT_ID, CLIENT_SECRET, TENANT_ID." >&2
  exit 1
fi
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Missing $TOKEN_FILE. Run upstream's 'pnpm run auth' on a machine with a browser and copy the resulting tokens.json here." >&2
  exit 1
fi

set -a
. "$ENV_FILE"
set +a

# Workaround for upstream bug in microsoft-todo-mcp-server v1.1.3: cli.js calls
# `__require("fs").mkdirSync(...)` which throws under ESM. The branch is only
# taken when the config dir is missing, so pre-creating it avoids the bug.
mkdir -p "$HOME/.config/microsoft-todo-mcp"

ACCESS_TOKEN="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$TOKEN_FILE','utf8')).accessToken || JSON.parse(require('fs').readFileSync('$TOKEN_FILE','utf8')).access_token)")"
REFRESH_TOKEN="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$TOKEN_FILE','utf8')).refreshToken || JSON.parse(require('fs').readFileSync('$TOKEN_FILE','utf8')).refresh_token)")"

exec env \
  CLIENT_ID="$CLIENT_ID" \
  CLIENT_SECRET="$CLIENT_SECRET" \
  TENANT_ID="${TENANT_ID:-consumers}" \
  REDIRECT_URI="${REDIRECT_URI:-http://localhost:3000/callback}" \
  MS_TODO_ACCESS_TOKEN="$ACCESS_TOKEN" \
  MS_TODO_REFRESH_TOKEN="$REFRESH_TOKEN" \
  npx -y microsoft-todo-mcp-server
