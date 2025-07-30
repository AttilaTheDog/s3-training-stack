#!/usr/bin/env bash
set -euo pipefail

# Config (override with env vars or .env)
ACME_EMAIL="${ACME_EMAIL:-you@example.com}"
BASE_DOMAIN="${BASE_DOMAIN:-s3.demo.mylemans.online}"
COUNT="${COUNT:-15}"
STACK_DIR="${STACK_DIR:-/opt/minio-stack}"

echo "[*] Ensuring docker compose v2 is available..."
if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get update -y && sudo apt-get install -y docker-compose-plugin
fi

echo "[*] Preparing runtime folders..."
sudo mkdir -p "$STACK_DIR"/{data,secrets,letsencrypt}
sudo install -m 600 /dev/null "$STACK_DIR/letsencrypt/acme.json"

echo "[*] Write .env for ACME"
printf "ACME_EMAIL=%s\n" "$ACME_EMAIL" | sudo tee "$STACK_DIR/.env" >/dev/null
sudo chmod 600 "$STACK_DIR/.env"

echo "[*] Writing docker-compose.yml (Traefik header + network)"
cat > /tmp/compose.header.yml <<'YML'
x-minio-common: &minio-common
  image: quay.io/minio/minio:latest
  command: server /data --console-address ":9001"
  restart: unless-stopped
  networks: [web]

services:
  traefik:
    image: traefik:v3.1
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.email=${ACME_EMAIL}
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.letsencrypt.acme.httpchallenge=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    restart: unless-stopped
    networks: [web]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.rule=HostRegexp(`{any:.+}`)"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"

YML

cat > /tmp/compose.footer.yml <<'YML'

networks:
  web:
    driver: bridge
YML

sudo bash -c "cat /tmp/compose.header.yml > $STACK_DIR/docker-compose.yml"

echo "[*] Appending $COUNT MinIO services..."
for i in $(seq -w 01 "$COUNT"); do
  S3_HOST="training${i}.${BASE_DOMAIN}"
  CONSOLE_HOST="console-training${i}.${BASE_DOMAIN}"
  DATADIR="$STACK_DIR/data/minio${i}"
  SECRET="$STACK_DIR/secrets/minio${i}.env"
  sudo mkdir -p "$DATADIR"
  if ! [ -f "$SECRET" ]; then
    U=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)
    P=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32)
    printf "MINIO_ROOT_USER=%s\nMINIO_ROOT_PASSWORD=%s\n" "$U" "$P" | sudo tee "$SECRET" >/dev/null
    sudo chmod 600 "$SECRET"
  fi
  cat <<YML | sudo tee -a "$STACK_DIR/docker-compose.yml" >/dev/null
  minio${i}:
    <<: *minio-common
    env_file: [./secrets/minio${i}.env]
    volumes: [./data/minio${i}:/data]
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.minio${i}.rule=Host(\`${S3_HOST}\`)"
      - "traefik.http.routers.minio${i}.entrypoints=websecure"
      - "traefik.http.routers.minio${i}.tls.certresolver=letsencrypt"
      - "traefik.http.services.minio${i}.loadbalancer.server.port=9000"
      - "traefik.http.routers.minio${i}.service=minio${i}"
      - "traefik.http.routers.minio${i}-console.rule=Host(\`${CONSOLE_HOST}\`)"
      - "traefik.http.routers.minio${i}-console.entrypoints=websecure"
      - "traefik.http.routers.minio${i}-console.tls.certresolver=letsencrypt"
      - "traefik.http.services.minio${i}-console.loadbalancer.server.port=9001"
      - "traefik.http.routers.minio${i}-console.service=minio${i}-console"

YML
done

sudo bash -c "cat /tmp/compose.footer.yml >> $STACK_DIR/docker-compose.yml"

echo "[*] Starting stack..."
cd "$STACK_DIR"
sudo docker compose up -d
sudo docker compose ps
echo "[OK] Example: https://training01.${BASE_DOMAIN} (console: https://console-training01.${BASE_DOMAIN})"
