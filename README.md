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
