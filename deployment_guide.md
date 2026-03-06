# DigitalOcean Deployment Guide — FraudShield

This guide covers the step-by-step process for deploying the FraudShield backend to a DigitalOcean Droplet with HTTPS enabled via Nginx and Certbot.

---

## 🛒 0. Domain Purchase & DNS Setup (New)

If you haven't purchased a domain yet, follow these steps:

### A. Choose a Registrar & Buy
1.  **Select a Registrar**: Popular options include [Namecheap](https://www.namecheap.com/), [GoDaddy](https://www.godaddy.com/), or [Squarespace Domains](https://domains.squarespace.com/).
2.  **Search & Purchase**: Search for your desired name (e.g., `fraudshield-api.com`). Follow the checkout process.
3.  **Disable Auto-Renew (Optional)**: If this is just for testing, you might want to disable auto-renewal.

### B. Point Domain to DigitalOcean
There are two ways to do this. We recommend **Option 1** for better integration with DO.

#### Option 1: Use DigitalOcean Name Servers (Recommended)
1.  In your Domain Registrar (e.g., Namecheap), find the **Name Servers** section.
2.  Change from "Standard" to "Custom DNS".
3.  Enter DigitalOcean's name servers:
    - `ns1.digitalocean.com`
    - `ns2.digitalocean.com`
    - `ns3.digitalocean.com`
4.  **In DigitalOcean Dashboard**:
    - Go to **Networking** > **Domains**.
    - Add your domain (e.g., `yourdomain.com`).
    - Click on the domain name and Add an **A Record**:
        - **HOSTNAME**: `api` (this creates `api.yourdomain.com`)
        - **WILL DIRECT TO**: Select your Droplet IP.

#### Option 2: Use Registrar DNS (Simpler)
1.  In your Domain Registrar, find the **DNS Management** or **Advanced DNS** section.
2.  Add an **A Record**:
    - **Host**: `api`
    - **Value**: Your Droplet's IP Address (e.g., `123.456.78.90`)
    - **TTL**: Automatic or 1 Hour.

> [!NOTE]
> DNS Propagation can take anywhere from **5 minutes to 24 hours**. Check your progress at [DNSChecker.org](https://dnschecker.org/).

---

## 🏗️ 1. Droplet & Domain Setup

1.  **Create a Droplet**:
    - Choose **Ubuntu 22.04 LTS**.
    - Performance: At least 1GB RAM (2GB recommended for Prisma/Docker builds).
2.  **Point your Domain**:
    - Create an `A` record for your domain (e.g., `api.yourdomain.com`) pointing to the Droplet's IP address.

---

## 🛠️ 2. Server Preparation

Connect to your droplet via SSH and install the required stack:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-v2 -y

# Verify installations
docker --version
docker compose version
```

---

## 📂 3. Clone & Configure

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Najla-Citadel/fraudshield.git
    cd fraudshield/fraudshield-backend
    ```

2.  **Environment Variables**:
    Copy the production example and fill in sensitive values:
    ```bash
    cp .env.prod.example .env
    nano .env
    ```
    **Critical variables to set:**
    - `POSTGRES_PASSWORD`: Use a strong random string.
    - `REDIS_PASSWORD`: Use a strong random string.
    - `JWT_SECRET` & `JWT_REFRESH_SECRET`: Use `openssl rand -base64 32`.
    - `DOMAIN_NAME`: Set to your actual domain (e.g., `api.yourdomain.com`).
    - `DATABASE_URL`: Ensure the password matches `POSTGRES_PASSWORD`.

---

## 🔒 4. Initial SSL Certificate & Launch

Because the `api.conf.template` expects SSL certificates to exist, we must perform a two-step launch.

### Step A: Temporary "Dummy" Certificates
Run this helper command to bootstrap the certificates (or manually acquire them):

```bash
# Pull the latest images
docker compose -f docker-compose.prod.yml pull

# Start services (Nginx might fail initially if certs aren't there)
docker compose -f docker-compose.prod.yml up -d
```

### Step B: Acquire Real Certificates
Execute Certbot to get the real certificates from Let's Encrypt:

```bash
docker compose -f docker-compose.prod.yml run --rm --entrypoint \
  "certbot certonly --webroot -w /var/www/certbot \
  --email your-email@example.com -d api.yourdomain.com \
  --agree-tos --no-eff-email" certbot

# Restart Nginx to pick up the real certs
docker compose -f docker-compose.prod.yml restart nginx
```

---

## 🗄️ 5. Database Initialization

Once the containers are running, push the Prisma schema to the production database:

```bash
# Enter the API container
docker exec -it fraudshield-api-prod npx prisma db push
```

---

## 🔄 6. Maintenance & Updates

### A. Regular Updates (Same Branch)
- **View Logs**: `docker compose -f docker-compose.prod.yml logs -f api`
- **Rebuild after Code Update**:
    ```bash
    git pull
    docker compose -f docker-compose.prod.yml up -d --build
    ```

### B. Switching Repositories or Branches
If you are switching from a team repository to your own repository or changing branches:

1.  **Update Remote URL** (if repo changed):
    ```bash
    git remote set-url origin https://github.com/karyuanfangwork-ui/fraudshield-v2.git
    git remote -v  # Verify it points to your repo
    ```
2.  **Fetch and Switch Branch**:
    ```bash
    git fetch origin
    git checkout main  # Or your specific branch name
    git reset --hard origin/main
    ```
3.  **Rebuild Container**:
    ```bash
    cd fraudshield-backend
    docker compose -f docker-compose.prod.yml up -d --build
    ```

- **SSL Renewal**: Certbot is already configured in the `docker-compose.prod.yml` to attempt renewal every 12 hours automatically.

---

## 📱 7. Update Mobile App

Finally, update your Flutter app's `.env` or configuration to point to the new secure URL:
```env
API_BASE_URL=https://api.yourdomain.com/api/v1
```
*(Note: Use **HTTPS**, as the backend now forces encryption.)*
