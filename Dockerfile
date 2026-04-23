FROM node:20-slim AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    ca-certificates \
    sudo \
    jq \
    gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Create claude user with sudo permissions and docker group access
RUN useradd -m -s /bin/bash claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    groupadd docker && \
    usermod -aG docker claude

# Set up working directory
RUN mkdir -p /workspace && chown claude:claude /workspace
WORKDIR /workspace

# Install Claude Code CLI globally (latest version)
RUN npm install -g @anthropic-ai/claude-code@latest

# Create necessary directories
RUN mkdir -p /home/claude/.claude && \
    chown -R claude:claude /home/claude

# Switch to claude user
USER claude

# Set environment variables
ENV CLAUDE_HOME=/home/claude/.claude
ENV NODE_ENV=production

# Entry point script
COPY --chown=claude:claude docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]