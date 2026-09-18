#!/bin/sh
set -eu

PORT="${PORT:-8080}"

echo "======================================"
echo "🚀 Starting Virgozki container"
echo "🌐 Cloud Run PORT: $PORT"
echo "======================================"

# Replace the fixed Nginx port with Cloud Run's PORT
sed -i "s/listen 8080 http2;/listen $PORT http2;/" \
    /usr/local/openresty/nginx/conf/nginx.conf

echo "🔍 Testing OpenResty configuration..."

/usr/local/openresty/bin/openresty -t

echo "🚀 Starting Xray..."
/usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

# Clean shutdown
cleanup() {
    echo "🛑 Stopping Xray..."
    kill -TERM "$XRAY_PID" 2>/dev/null || true
}

trap cleanup TERM INT

echo "🌐 Starting OpenResty on port $PORT..."

/usr/local/openresty/bin/openresty -g "daemon off;" &
NGINX_PID=$!

# Keep both processes supervised
wait "$NGINX_PID"
STATUS=$?

echo "⚠️ OpenResty stopped with status: $STATUS"

cleanup

exit "$STATUS"
