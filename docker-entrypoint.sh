#!/bin/bash
set -e

# Ensure claude user owns the mounted workspace
sudo chown -R claude:claude /workspace
sudo chown -R claude:claude /home/claude

# Grant claude access to the Docker socket
if [ -S /var/run/docker.sock ]; then
    sudo chmod 666 /var/run/docker.sock
fi

# Update Claude Code to latest version on startup
echo "Checking for Claude Code updates..."
sudo npm update -g @anthropic-ai/claude-code || true

# Set up API key if provided
if [ -n "$ANTHROPIC_API_KEY" ]; then
    export ANTHROPIC_API_KEY
fi

# Set up AWS credentials if using Bedrock
if [ "$CLAUDE_CODE_USE_BEDROCK" = "1" ] || [ "$CLAUDE_CODE_USE_BEDROCK" = "true" ]; then
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        export AWS_ACCESS_KEY_ID
        export AWS_SECRET_ACCESS_KEY
        [ -n "$AWS_SESSION_TOKEN" ] && export AWS_SESSION_TOKEN
        [ -n "$AWS_REGION" ] && export AWS_REGION
    fi
fi

# Execute command
echo "Starting container with command: $@"
exec "$@"