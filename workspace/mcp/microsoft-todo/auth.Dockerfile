FROM node:20-alpine
RUN apk add --no-cache git
RUN npm install -g pnpm@9
WORKDIR /app
RUN git clone --depth 1 https://github.com/jordanburke/microsoft-todo-mcp-server . \
    && pnpm install --frozen-lockfile=false \
    && pnpm run build
COPY auth-entrypoint.sh /usr/local/bin/auth-entrypoint.sh
RUN chmod +x /usr/local/bin/auth-entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/auth-entrypoint.sh"]
