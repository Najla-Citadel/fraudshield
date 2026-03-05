# FraudShield Database Backups (Task D3)

This folder contains the `backup_db.sh` script, which automates the backup of the production PostgreSQL database running in Docker.

## Setup Instructions

To ensure this script runs automatically every night (e.g., at 3:00 AM UTC) and prevents permanent data loss, you must register it with the Ubuntu server's cron daemon on your DigitalOcean Droplet.

### 1. SSH into your Droplet
```bash
ssh root@152.42.241.157
```

### 2. Make the script executable
By default, the script might not have permission to execute. Run this from your FraudShield backend directory:
```bash
cd /root/fraudshield/fraudshield-backend
chmod +x scripts/backup_db.sh
```

### 3. Test the script manually
Before automating it, ensure it works:
```bash
./scripts/backup_db.sh
```
You should see a message saying "Backup completed successfully" and a new `backups` folder should appear containing the `.sql.gz` file.

### 4. Register with Cron
Open the cron editor:
```bash
crontab -e
```
*(If prompted, select `nano` as your editor).*

Add the following line to the very bottom of the file (adjust `/root/fraudshield` if your project is in a different directory):

```cron
0 3 * * * /root/fraudshield/fraudshield-backend/scripts/backup_db.sh >> /root/fraudshield/fraudshield-backend/backups/backup.log 2>&1
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X` in nano).

That's it! Your database will now automatically back up every night at 3:00 AM, and backups older than 7 days will be automatically deleted to save disk space.
