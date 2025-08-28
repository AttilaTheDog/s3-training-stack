# S3 Training Stack (MinIO + Traefik)

A scalable, multi-tenant or single-tenant **MinIO** object storage platform, secured with **Traefik** and **Let's Encrypt TLS**.

Each MinIO instance is exposed via:

- **S3 API**: `https://training01.s3.domain.com`
- **Console UI**: `https://console-training01.s3.domain.com`

---

## 1. Prerequisites

**OS**: Ubuntu 22.04 or 24.04  
**DNS**: Any with wildcard A record

### Install dependencies

```bash
apt update && apt upgrade -y
apt install docker.io docker-compose -y
systemctl enable docker
systemctl start docker
```

### DNS setup

On Cloudflare (or similar DNS provider):

- Create an A record: `*.s3.domain.com` → your server IP
- Set the record to **DNS Only** to allow HTTP-01 challenges

---

## 2. Single-Instance Quick Start

```bash
git clone https://github.com/AttilaTheDog/s3-training-stack.git
cd s3-training-stack
cp .env.example .env
nano .env     # Fill in ACME_EMAIL
```

### Create secrets folder and credentials

```bash
mkdir secrets
echo "MINIO_ROOT_USER=adminuser" > secrets/minio01.env
echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio01.env
```

---

## 3. Multi-Instance Setup (01–15)

### Generate secrets

```bash
for i in $(seq -w 1 15); do
  echo "MINIO_ROOT_USER=adminuser" > secrets/minio${i}.env
  echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio${i}.env
done
```

### Use example compose file

```bash
cp docker-compose-1-15.yml docker-compose.yml
nano docker-compose.yml     # Ensure domains match your DNS setup
```

---

## 4. Start the Stack

```bash
docker-compose up -d
```

### Test your instance(s)

- API: `https://training01.s3.domain.com`
- Console: `https://console-training01.s3.domain.com`

Repeat for `training02`, `training03`, ... up to `training15`.

---

## Troubleshooting

**Check logs:**

```bash
docker logs traefik
docker logs minio01
```

**Check active containers:**

```bash
docker ps
```

**Inspect SSL:**

```bash
cat ./letsencrypt/acme.json
```

---

## License

MIT License
