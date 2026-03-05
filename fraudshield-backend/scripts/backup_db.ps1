# FraudShield Database Backup Script
# Performs an on-demand backup of the production PostgreSQL container.

$BACKUP_DIR = "backups"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"
$CONTAINER_NAME = "fraudshield-postgres-prod"
$DB_NAME = "fraudshield"
$DB_USER = "fraudshield"
$FILENAME = "$BACKUP_DIR/db_backup_$TIMESTAMP.sql.gz"

# Create backup directory if it doesn't exist
if (!(Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
    Write-Host "📂 Created backup directory: $BACKUP_DIR" -ForegroundColor Cyan
}

Write-Host "🚀 Starting database backup for $DB_NAME..." -ForegroundColor Green

# Use docker exec to run pg_dump and compress the output
# Note: We use -it for interactivity if needed, but for scripts typically -t is enough or no flags.
# Here we pipe the output to gzip on the host for better control.
try {
    docker exec $CONTAINER_NAME pg_dump -U $DB_USER $DB_NAME | gzip > $FILENAME
    
    if ($LASTEXITCODE -eq 0) {
        $filesize = (Get-Item $FILENAME).Length / 1KB
        Write-Host "✅ Backup successful: $FILENAME ($($filesize.ToString('F2')) KB)" -ForegroundColor Green
    }
    else {
        Write-Error "❌ Backup failed with exit code $LASTEXITCODE"
    }
}
catch {
    Write-Error "❌ Error during backup: $_"
}

# --- Cleanup Logic ---
# Retain only the last 7 days of backups
Write-Host "Cleaning up backups older than 7 days..." -ForegroundColor Gray
$limitDate = (Get-Date).AddDays(-7)
Get-ChildItem $BACKUP_DIR -Filter "*.sql.gz" | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force
Write-Host "Done." -ForegroundColor Gray
