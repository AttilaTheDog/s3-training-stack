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
```

**Multiple instances**
```Bash
for i in $(seq -w 1 15); do
  echo "MINIO_ROOT_USER=adminuser" > secrets/minio$i.env
  echo "MINIO_ROOT_PASSWORD=ChangeMe-Long-Secret" >> secrets/minio$i.env
done
```

Edit the docker-compose.yml file to point to the correct dns record for your domain.

```bash
nano docker-compose.yml
```

**Multiple instances**

See the docker-compose-1-15.yml example, rename to docker-compose.yml

Bring up:

```bash
docker-compose up -d
```

**Multiple instances**
```bash
nano docker-compose-1-15.yml
```

Test:
  - S3: `https://training01.s3.domain.com` => This url will be used for connecting to your storage. 
  - Console: `https://console-training01.s3.domain.com`  => This url will be used for the WebUI

---

Trouble shooting:

```bash
docker logs traefik
```

```bash
docker logs minio01
```


## License
MIT
