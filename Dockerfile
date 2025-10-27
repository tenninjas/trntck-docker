FROM alpine:latest

ARG RELEASE_TAG

# Install required packages
RUN apk add --no-cache \
    bash \
    python3 \
    py3-pip \
    dcron \
    shadow \
    su-exec \
    git \
    && rm -rf /var/cache/apk/*

# Create app directory
WORKDIR /app

# Clone the specific release from the torrent_checker repository
RUN git clone --depth 1 --branch ${RELEASE_TAG} https://github.com/tenninjas/torrent_checker.git /app

# Install Python dependencies
RUN if [ -f requirements.txt ]; then pip3 install --break-system-packages --no-cache-dir -r requirements.txt; fi

# Create entrypoint script
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/bash
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create group and user
if ! getent group torrentgrp > /dev/null 2>&1; then
    addgroup -g ${PGID} torrentgrp
fi

if ! getent passwd torrenter > /dev/null 2>&1; then
    adduser -D -u ${PUID} -G torrentgrp -s /bin/bash torrenter
fi

chown -R torrenter:torrentgrp /app

# Start crond
crond -b -l 2

# Export environment variables
export TORRENT_UI_PORT=${TORRENT_UI_PORT}
export TORRENT_UI_SECRET=${TORRENT_UI_SECRET}

# Execute as torrenter
exec su-exec torrenter "$@"
EOF

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "torrent_check.py"]
