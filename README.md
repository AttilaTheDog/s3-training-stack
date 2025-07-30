# S3 Training Stack (MinIO + Traefik)

Multi-tenant or single-tenant **MinIO** object storage behind **Traefik** with **HTTPS** and host‑based routing.

- Example single instance:
  - S3: `https://training01.s3.demo.mylemans.online`
  - Console: `https://console-training01.s3.demo.mylemans.online`

---

## 1) Prerequisites (Ubuntu Server 22.04/24.04)

```bash
# Install Docker (if needed)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# Ensure docker compose v2
docker compose version || { sudo apt-get update -y && sudo apt-get install -y docker-compose-plugin; }
```

**DNS (Cloudflare):**
- Create **A record** for `*.s3.demo.mylemans.online` to your server IP.
- Set to **DNS‑Only (grey cloud)** so Let's Encrypt HTTP‑01 works.

---

## 2) Single-instance quick start (dev)

Create secrets and `.env`:

```bash
cp .env.example .env
echo "MINIO_ROOT_USER=adminuser" > secrets/minio01.env
echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio01.env
mkdir -p data/minio01 letsencrypt
install -m 600 /dev/null letsencrypt/acme.json
```

Bring up:

```bash
docker compose up -d
docker compose ps
```

Test:
- Console → `https://${CONSOLE_HOST}`
- S3 API → `https://${S3_HOST}`

---

## 3) Multi-tenant rollout (15 instances on a fresh VM)

Run the provisioning script (generates per‑instance credentials and a compose for 15 instances):

```bash
ACME_EMAIL=you@example.com BASE_DOMAIN=s3.demo.mylemans.online COUNT=15 \
  sudo scripts/setup_minio_stack.sh
```

Secrets live in `/opt/minio-stack/secrets/minioNN.env`.

---

## 4) Connect (AWS CLI / mc)

```bash
# AWS CLI
aws --endpoint-url https://training01.s3.demo.mylemans.online s3 ls

# MinIO client
mc alias set training01 https://training01.s3.demo.mylemans.online ACCESS_KEY SECRET_KEY
mc mb training01/mybucket
mc ls training01
```

---

## 5) Operations

```bash
# Status
docker compose ps
docker ps --format "table {{.Names}}\t{{.Status}}"

# Logs
docker compose logs -f traefik
docker compose logs -f minio01

# Resource usage
docker stats
```

**Enable Traefik dashboard (temporary):**
Add to `traefik` service:
```yaml
command:
  - --api.insecure=true
ports:
  - "8080:8080"
```
Open `http://<server-ip>:8080/dashboard/`.

---

## 6) Troubleshooting

- **404 on console URL**
  - Cloudflare must be **grey cloud**.
  - Check routers exist:
    ```
    docker compose logs traefik | egrep -i 'router|minio|error'
    ```
  - Ensure labels include explicit router→service mapping:
    ```
    traefik.http.routers.minio01.service=minio01
    traefik.http.routers.minio01-console.service=minio01-console
    ```

- **Cert errors**
  - Check ACME email and that port **80** is open.
  - `docker compose logs traefik | egrep -i 'acme|letsencrypt|challenge'`.

- **Health**
  - `docker ps` should show `(healthy)` for `minio01`.

---

## 7) Security/Hardening (next steps)
- Create per‑tenant users & policies (`mc admin user add`, `mc admin policy set`).
- Move data to dedicated disks/volumes.
- For HA, migrate an instance to **MinIO distributed** mode across multiple disks/hosts.

---

## License
MIT
