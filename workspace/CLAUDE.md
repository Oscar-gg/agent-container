# Google Workspace Toolkit

This repo provides a containerized [Google Workspace CLI](https://github.com/googleworkspace/cli) (`gws`) pre-wired to a service account, plus a place to add MCP servers for Google Workspace integrations.

## Repository Structure

```
.
├── cli/                    # Docker image for the gws CLI
│   └── Dockerfile          # Ubuntu + Node.js + @googleworkspace/cli
├── mcp/                    # MCP servers (empty — add custom servers here)
├── working_dir/            # Mounted into the container at /workspace (gitignored)
│   ├── sa_key.json         # Service account key (never commit)
│   ├── get_token.mjs       # Generates an access token from sa_key.json
│   └── ...                 # Files for upload/download operations
├── compose.yml             # Docker Compose service definition
└── gws                     # Wrapper script — use this to run CLI commands
```

## Running Google Workspace Commands

Always use the `./gws` wrapper script. It auto-generates a service account token and passes it to the container:

```bash
./gws drive files list
./gws drive files list --params '{"q": "mimeType = \"application/vnd.google-apps.folder\""}'
./gws gmail users messages list --params '{"userId": "me"}'
./gws calendar calendars list
./gws sheets spreadsheets get --params '{"spreadsheetId": "..."}'
```

The `/gws` slash command is also available — use it to run CLI commands directly in conversation.

Full list of supported services: `drive`, `sheets`, `gmail`, `calendar`, `docs`, `slides`, `tasks`, `people`, `chat`, `classroom`, `forms`, `keep`, `meet`, `admin-reports`.

Use `./gws <service> --help` to explore available resources and methods.

## Authentication

- **Method**: Service account token via `GOOGLE_WORKSPACE_CLI_TOKEN`
- **Key file**: `working_dir/sa_key.json` (gitignored — never commit)
- **Token generation**: `working_dir/get_token.mjs` (uses `google-auth-library`)
- **Service account**: `openclaw@oscar-assistant-489703.iam.gserviceaccount.com`
- **GCP project**: `oscar-assistant-489703`

Tokens expire after 1 hour; the wrapper regenerates one on every invocation.

> **Note**: The service account only sees Drive files shared with it. To access user-owned data (Gmail, personal Drive, etc.), domain-wide delegation must be configured and an impersonation subject provided.

## MCP Servers

The `mcp/` directory holds custom MCP servers. See per-server setup docs:

- **Microsoft To Do** — `mcp/microsoft-todo/SETUP.md` (Azure app registration + browser-auth token flow + Claude Code wiring). Additionally, the following claude.ai MCP connectors are available in this environment and can be activated via `/mcp`:

- **claude.ai Gmail** — read and manage Gmail
- **claude.ai Google Calendar** — manage calendars and events
- **claude.ai Google Drive** — manage Drive files

Prefer the `./gws` CLI for scripted or bulk operations. Use the MCP connectors for interactive, user-context operations (e.g. reading the current user's Gmail inbox).

## Key Files (gitignored)

`working_dir/` is gitignored. Sensitive files that must be present locally:

| File | Purpose |
|------|---------|
| `working_dir/sa_key.json` | Service account private key |
| `working_dir/client_secret.json` | OAuth2 client secret (used if switching to OAuth login) |
