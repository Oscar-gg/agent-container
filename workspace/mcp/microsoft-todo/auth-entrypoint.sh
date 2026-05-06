#!/bin/sh
set -eu

: "${CLIENT_ID:?CLIENT_ID env var required}"
: "${CLIENT_SECRET:?CLIENT_SECRET env var required}"
: "${TENANT_ID:=consumers}"
: "${REDIRECT_URI:=http://localhost:3000/callback}"

# Upstream's auth server reads from .env in cwd
cat > /app/.env <<EOF
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
TENANT_ID=${TENANT_ID}
REDIRECT_URI=${REDIRECT_URI}
EOF

mkdir -p /tokens

cd /app
rm -f tokens.json

echo "================================================================"
echo "Open http://localhost:3000 in your host browser to begin sign-in."
echo "After you complete the Microsoft login, tokens will be written to"
echo "  working_dir/ms_todo_tokens.json"
echo "and this container will exit."
echo "================================================================"

pnpm run auth &
AUTH_PID=$!

while [ ! -s /app/tokens.json ]; do
  if ! kill -0 "$AUTH_PID" 2>/dev/null; then
    echo "Auth server exited before tokens.json was written." >&2
    exit 1
  fi
  sleep 1
done

# Give the auth server a moment to fully flush the file
sleep 1
cp /app/tokens.json /tokens/ms_todo_tokens.json
echo "Saved tokens to working_dir/ms_todo_tokens.json"

kill "$AUTH_PID" 2>/dev/null || true
wait "$AUTH_PID" 2>/dev/null || true
