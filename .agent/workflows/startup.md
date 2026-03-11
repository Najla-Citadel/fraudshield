---
description: How to start FraudShield dev environment daily
---

Follow these steps every time you open your laptop to start developing:

1. **Open Docker Desktop**: Ensure the whale icon is visible in your menu bar.
2. **Start Database & Cache**: Open a terminal and run:
   ```bash
   cd /Users/najla/projects/fraudshield/fraudshield-backend
   docker-compose up -d
   ```
3. **Start the Backend**: In the same (or new) terminal, run:
   ```bash
   npm run dev
   ```
   *(Keep this terminal window running!)*
4. **Find your IP (if it changed)**:
   ```bash
   ipconfig getifaddr en0
   ```
5. **Start the App**: Open a NEW terminal window and run:
   ```bash
   cd /Users/najla/projects/fraudshield/fraudshield
   flutter run --dart-define=API_BASE_URL=http://<YOUR_IP>:3000/api/v1
   ```
   *(Replace `<YOUR_IP>` with the result from Step 4, e.g., 192.168.100.201)*
