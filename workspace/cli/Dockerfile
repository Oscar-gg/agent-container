FROM ubuntu:24.04

RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

RUN npm install -g @googleworkspace/cli

# Config dir used by gws by default
ENV GOOGLE_WORKSPACE_CLI_CONFIG_DIR=/config/gws

RUN mkdir -p /config/gws

WORKDIR /workspace

ENTRYPOINT ["gws"]
CMD ["--help"]
