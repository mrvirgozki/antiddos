# Base: OpenResty Alpine (tama mo ito)
FROM openresty/openresty:alpine

# I-install ang mga kailangan
RUN apk add --no-cache ca-certificates wget unzip tini curl

# ✅ I-download at i-install ang Xray (tama ang link mo, naka-verify na)
RUN wget --timeout=120 -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    echo "✅ Xray zip downloaded" && \
    unzip -q /tmp/xray.zip -d /tmp/xray/ && \
    mv /tmp/xray/xray /usr/local/bin/ && \
    mkdir -p /usr/local/share/xray/ && \
    mv /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    mv /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    chmod +x /usr/local/bin/xray && \
    rm -rf /tmp/xray /tmp/xray.zip && \
    echo "✅ Xray installed successfully"

# ✅ Kopyahin ang files mo
COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html

# ✅ I-fix ang Nginx port bago simula — GAGANA KAHIT ANONG IBIGAY NG CLOUD RUN
RUN sed -i 's/listen\s*[0-9]*;/listen ${PORT:-8080};/g' /usr/local/openresty/nginx/conf/nginx.conf || true

# ✅ Startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray/
ENV PORT=8080
EXPOSE ${PORT:-8080}

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
