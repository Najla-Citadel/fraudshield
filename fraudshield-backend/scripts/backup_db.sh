#!/bin/bash
# fraudshield-backend/scripts/backup_db.sh
# 
# This script runs pg_dump inside the running postgres docker container
# and saves a compressed backup to the host machine.
# It also deletes backups older than 7 days to save disk space.

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
# Go up one directory from the scripts folder to the project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${PROJECT_DIR}/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Dynamically find the running postgres container 
# (handles weird prefixes like 2445d6785ff1_fraudshield-postgres-prod)
CONTAINER_NAME=$(docker ps --filter "ancestor=postgres:16-alpine" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "Error: Could not find any running container based on postgres:16-alpine."
    exit 1
fi

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting FraudShield database backup..."

# Extract PostgreSQL credentials from the .env.prod file
# We use grep to find the line and cut to get the value
if [ -f "$PROJECT_DIR/.env.prod" ]; then
    DB_USER=$(grep -P '^POSTGRES_USER=' "$PROJECT_DIR/.env.prod" | cut -d '=' -f 2)
    DB_NAME=$(grep -P '^POSTGRES_DB=' "$PROJECT_DIR/.env.prod" | cut -d '=' -f 2)
else
    echo "Warning: .env.prod file not found in $PROJECT_DIR. Falling back to default credentials."
fi

# Fallback to default names if the env vars are missing or empty
DB_USER=${DB_USER:-fraudshield}
DB_NAME=${DB_NAME:-fraudshield}

# Provide the fully qualified path for the output file
FINAL_BACKUP_LOCATION="$BACKUP_DIR/fraudshield_db_$TIMESTAMP.sql.gz"

# Run pg_dump inside the docker container and pipe it to gzip on the host machine
echo "[$(date)] Dumping database: $DB_NAME using user: $DB_USER..."
docker exec "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c | gzip > "$FINAL_BACKUP_LOCATION"

# Verify the backup file was created and has a size greater than 0
if [ -s "$FINAL_BACKUP_LOCATION" ]; then
    echo "[$(date)] Backup completed successfully: $FINAL_BACKUP_LOCATION"
else
    echo "[$(date)] Backup failed or file is empty!"
    rm -f "$FINAL_BACKUP_LOCATION"
    exit 1
fi

# Cleanup old backups (older than 7 days)
echo "[$(date)] Cleaning up backups older than 7 days..."
find "$BACKUP_DIR" -type f -name "fraudshield_db_*.sql.gz" -mtime +7 -exec rm {} \;
echo "[$(date)] Cleanup finished."
