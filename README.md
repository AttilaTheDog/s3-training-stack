# S3 Training Stack (MinIO + Traefik)

Multi-tenant or single-tenant **MinIO** object storage behind **Traefik** with **HTTPS** and host‑based routing.

- Example single instance:
  - S3: `https://training01.s3.domain.com`
  - Console: `https://console-training01.s3.domain.com`

---

## 1) Prerequisites (Ubuntu Server 22.04/24.04)

Update Your Packages

```bash
apt update && apt upgrade -y
```

Install Docker & Docker Compose

```bash
apt install docker.io docker-compose -y
```
Enable the Docker Service

```bash
systemctl enable docker
```
Start the Docker Service

```bash
systemctl start docker
```
Optionally create another user then root and add the user to the docker group, this way you don't have to run docker with sudo

```bash
newgrp docker
```

```bash
sudo usermod -aG docker $USER
```

**DNS:**
- Create an **A record** for example `*.s3.domain.com` to your server IP.
  the *. will act as a wildcard if you want to create multiple instances pointing to the same server IP.
- Set to **DNS‑Only (grey cloud)** so Let's Encrypt HTTP‑01 works. (Cloudflare)

---



## 2) Single-instance quick start (dev)

```bash
git clone https://github.com/marcmylemans/s3-training-stack.git
```

```bash
cd s3-training-stack/
```

Create secrets and `.env`:

```bash
cp .env.example .env
```
Edit the .env file and change ACME_EMAIL and BASE_DOMAIN

```bash
nano .env
```
Save the changes with ctrl+x

Create a secrets directory for the .env files for each MinIO instance

```bash
mkdir secrets
```

Populate the .env file for minio01, change 'adminuser' and 'ChangeMe-Long-Secret' to a unique username and password.

```bash
echo "MINIO_ROOT_USER=adminuser" > secrets/minio01.env
echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio01.env
echo "MINIO_HOST=training01.s3.domain.com" >> secrets/minio01.env
echo "MINIO_CONSOLE_HOST=console-training01.s3.domain.com" >> secrets/minio01.env

```

Bring up:

```bash
docker-compose up -d
```

Test:
  - S3: `https://training01.s3.domain.com`
  - Console: `https://console-training01.s3.domain.com`

---

## 3) Use a Hetzner Volume for MinIO data (recommended)

> This maps your MinIO `/data` to a mounted Hetzner Volume so object data is stored off the root disk.

### 3.1 Attach, format, and mount the Volume

> **Only format if it’s a new/empty volume.** Replace the device path with yours from `/dev/disk/by-id/`.

```bash
# Find the device path (example output contains 'HC_Volume_XXXX')
ls -l /dev/disk/by-id/ | grep Volume

# Example device path (edit to your actual path)
VOL=/dev/disk/by-id/scsi-0HC_Volume_123456

# Format as XFS (recommended for MinIO); skip if filesystem already exists
sudo mkfs.xfs -f "$VOL"

# Create mount point and mount it
sudo mkdir -p /mnt/minio
sudo mount "$VOL" /mnt/minio

# Persist across reboots (use the stable by-id path)
echo "$VOL  /mnt/minio  xfs  noatime,nodiratime  0  2" | sudo tee -a /etc/fstab
```

Verify:
```bash
mount | grep /mnt/minio
df -h /mnt/minio
```

### 3.2 Prepare directories

**Single instance**
```bash
sudo mkdir -p /mnt/minio/minio01
sudo chown root:root /mnt/minio/minio01
```

**Multiple instances (01..15)**
```bash
for i in $(seq -w 01 15); do
  sudo mkdir -p "/mnt/minio/minio${i}"
done
```

### 3.3 (Optional) Move existing data

If you already had data under `./data/minio01` on the root disk:

```bash
cd /opt/minio-stack
docker-compose stop minio01

sudo rsync -aH --info=progress2 ./data/minio01/ /mnt/minio/minio01/
# Optionally keep a temporary backup:
# sudo mv ./data/minio01 ./data/minio01.bak
```

For many instances:
```bash
for i in $(seq -w 01 15); do
  docker compose stop "minio${i}" || true
  sudo rsync -aH ./data/minio${i}/ /mnt/minio/minio${i}/ || true
done
```

### 3.4 Update docker-compose volumes

**Single instance**
```yaml
minio01:
  # ...
  volumes:
    - /mnt/minio/minio01:/data
```

**Multiple instances**
```Bash
for i in $(seq -w 1 15); do
  echo "MINIO_ROOT_USER=adminuser" > secrets/minio$i.env
  echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio$i.env
  echo "MINIO_HOST=training$i.s3.domain.com" >> secrets/minio$i.env
  echo "MINIO_CONSOLE_HOST=console-training$i.s3.domain.com" >> secrets/minio$i.env
done

```

Bring the stack back up:
```bash
docker-compose up -d
```

Sanity checks:
```bash
docker ps --format "table {{.Names}}	{{.Status}}"
df -h /mnt/minio
sudo ls -lah /mnt/minio/minio01
```


## License
MIT
