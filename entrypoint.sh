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
/usr/local/openresty/bin/openresty -t || exit 1

echo "🚀 Starting Xray..."
# ✅ GAMITIN ANG `exec` + `tini` para hindi mamatay ang Xray
exec /sbin/tini -s -- /usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

# Clean shutdown
cleanup() {
    echo "🛑 Stopping Xray..."
    kill -TERM "$XRAY_PID" 2>/dev/null || true
}
trap cleanup TERM INT

echo "🌐 Starting OpenResty on port $PORT..."
# ✅ OpenResty sa foreground, ito ang magiging main process
exec /usr/local/openresty/bin/openresty -g "daemon off;"
