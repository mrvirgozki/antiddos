#!/bin/sh
set -eu

PORT="${PORT:-8080}"

echo "======================================"
echo "Starting Virgozki container"
echo "Cloud Run PORT: $PORT"
echo "======================================"

echo "Configuring OpenResty port..."

sed -i -E "s/listen[[:space:]]+[^;]+;/listen 0.0.0.0:${PORT};/" \
    /usr/local/openresty/nginx/conf/nginx.conf

echo "Testing OpenResty configuration..."

if ! /usr/local/openresty/bin/openresty -t; then
    echo "ERROR: OpenResty configuration test failed"
    exit 1
fi

echo "OpenResty configuration OK"

echo "Starting Xray..."

/usr/local/bin/xray run \
    -config /etc/xray.json \
    > /dev/stdout 2> /dev/stderr &

XRAY_PID=$!

sleep 1

if ! kill -0 "$XRAY_PID" 2>/dev/null; then
    echo "WARNING: Xray stopped during startup"
else
    echo "Xray started"
fi

echo "Starting OpenResty on 0.0.0.0:${PORT}..."

exec /usr/local/openresty/bin/openresty -g "daemon off;"
