#!/bin/bash
source /workspace/working_dir/github_app.env

case "$1" in
  personal) INSTALLATION_ID="$GITHUB_PERSONAL_INSTALLATION_ID" ;;
  org)      INSTALLATION_ID="$GITHUB_ORG_INSTALLATION_ID" ;;
  *) echo "Usage: $0 personal|org" >&2; exit 1 ;;
esac

TOKEN=$(GITHUB_APP_ID="$GITHUB_APP_ID" node /workspace/mcp/get_github_token.mjs "$INSTALLATION_ID" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "Failed to generate GitHub App installation token" >&2
  exit 1
fi

exec docker run -i --rm \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="$TOKEN" \
  ghcr.io/github/github-mcp-server
