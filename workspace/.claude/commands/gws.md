Run a Google Workspace CLI command using the service account in this repo.

Usage: /gws <service> <resource> <method> [flags]

Examples:
  /gws drive files list
  /gws gmail users messages list --params '{"userId": "me"}'
  /gws calendar calendars list

The wrapper script at /workspace/gws auto-generates a service account token from
working_dir/sa_key.json and passes it to the containerized gws CLI.

When the user runs this skill, execute the following bash command, substituting
the arguments they provided for $ARGUMENTS:

```bash
cd /workspace && ./gws $ARGUMENTS
```

If the user doesn't provide arguments, run:

```bash
cd /workspace && ./gws --help
```
