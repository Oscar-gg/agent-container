FROM pinchtab/pinchtab

USER root
RUN apk add --no-cache xvfb x11vnc novnc websockify fluxbox

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 9867 6080

ENTRYPOINT ["/usr/local/bin/start.sh"]
CMD ["/usr/local/bin/docker-entrypoint.sh", "pinchtab", "server"]
