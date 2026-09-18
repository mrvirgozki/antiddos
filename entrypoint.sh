#!/bin/sh
set -e

# Gamitin ang port galing environment, default 8080
PORT=${PORT:-8080}
echo "✅ Ginagamit na port: $PORT"

# ✅ I-update ang Nginx config para sa tamang port
sed -i "s/listen\s*[0-9]*;/listen $PORT;/g" /usr/local/openresty/nginx/conf/nginx.conf

# ✅ Simulan ang Xray sa background
echo "🚀 Sinisimulan ang Xray..."
/usr/local/bin/xray run -config /etc/xray.json &
XRAY_PID=$!

# ✅ Simulan ang OpenResty sa foreground (dapat ito ang huling tumakbo)
echo "🌐 Sinisimulan ang OpenResty sa port $PORT..."
exec /usr/local/openresty/bin/openresty -g "daemon off;"

# Kung mamatay ang alin man, patayin lahat
wait $XRAY_PID
echo "⚠️ Tumigil ang Xray, isinasara ang server..."
kill -TERM 1
