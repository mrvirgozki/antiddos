#!/bin/sh
set -eu

PORT="${PORT:-8080}"

echo "======================================"
echo "🚀 Starting Virgozki container"
echo "🌐 Cloud Run PORT: $PORT"
echo "======================================"

sed -i "s/listen 8080 http2;/listen $PORT http2;/" \
    /usr/local/openresty/nginx/conf/nginx.conf

echo "🔍 Testing OpenResty configuration..."
/usr/local/openresty/bin/openresty -t || exit 1

echo "🚀 Starting Xray..."
/sbin/tini -s -- /usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

cleanup() {
    echo "🛑 Stopping Xray..."
    kill -TERM "$XRAY_PID" 2>/dev/null || true
}
trap cleanup TERM INT

echo "🌐 Starting OpenResty..."
exec /usr/local/openresty/bin/openresty -g "daemon off;"
