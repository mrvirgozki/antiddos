FROM openresty/openresty:alpine

RUN apk add --no-cache \
    ca-certificates \
    wget \
    unzip \
    tini \
    curl

RUN wget --timeout=120 -qO /tmp/xray.zip \
    https://github.com/XTLS/Xray-core/releases/download/v24.10.31/Xray-linux-64.zip && \
    unzip -q /tmp/xray.zip -d /tmp/xray && \
    install -m 755 /tmp/xray/xray /usr/local/bin/xray && \
    mkdir -p /usr/local/share/xray && \
    cp /tmp/xray/geoip.dat /usr/local/share/xray/ && \
    cp /tmp/xray/geosite.dat /usr/local/share/xray/ && \
    rm -rf /tmp/xray /tmp/xray.zip

COPY config.json /etc/xray.json
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY index.html /usr/local/openresty/nginx/html/index.html
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENV XRAY_LOCATION_ASSET=/usr/local/share/xray
ENV PORT=8080

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh"]
