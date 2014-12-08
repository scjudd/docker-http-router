#!/bin/bash

export ROOT_CMD="curl -sL http://172.17.42.1:4001/v2/keys"
export CONF=/etc/nginx/sites-enabled/default

read -r -d '' PARTIAL <<EOF
server {
    listen 80;
    server_name %SERVER_NAME%;
    add_header X-Backend %BACKEND%;

    location / {
        proxy_pass %BACKEND%;
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

gen_config() {
    echo "server { listen 80; }"

    for VHOST in $($ROOT_CMD/router | jq -r '.node.nodes[].key'); do
        BACKEND=$($ROOT_CMD$VHOST/backend | jq -r '.node.value')
        SERVER_NAME=$($ROOT_CMD$VHOST/server_name | jq -r '.node.value')
        if [[ "$BACKEND" != "" && "$SERVER_NAME" != "" ]]; then
            echo "$PARTIAL" | sed -e "s;%SERVER_NAME%;$SERVER_NAME;g" -e "s;%BACKEND%;$BACKEND;g"
        fi
    done
}

echo "[http-router] generating initial nginx configuration..."

gen_config > $CONF;

echo "[http-router] starting etcd watch loop..."

while :; do
    $ROOT_CMD/router?wait=true\&recursive=true >/dev/null
    echo "[http-router] change detected. reloading nginx..."
    sleep 1 && gen_config > $CONF
    nginx -s reload
done &

echo "[http-router] monitoring etcd for changes..."
echo "[http-router] starting nginx..."

nginx &

echo "[http-router] http-router is ready. How may I direct your call?"

wait
exit 1
