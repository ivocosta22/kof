# Kof Deployment Guide

This guide explains how to run Kof on:

- ✅ Windows (testing machine)
- ✅ Raspberry Pi (production / coffee shop mode)

These instructions are written for basic computer users.

---

# PART 1 — Running Kof on Windows (Testing)

## Install Node.js

1. Go to: https://nodejs.org
2. Download the LTS version
3. Install it (click Next until finished)

After installation, open PowerShell and check:
```bash
node -v  
npm -v  
```
You should see version numbers.

---

## Download the Kof Project

Either:

- Download the ZIP and extract it  
OR  
- Clone from Git (if you know how)

Open PowerShell inside the project folder.

---

## Install Dependencies

Run:
```bash
npm install
```
Wait until it finishes.

---

## Create the .env File

In the project root folder, create a file named:
```bash
.env
```
Inside it, add:
```bash
KOF_TOKEN_SECRET=put-a-long-random-secret-here  
KOF_ORDER_RETENTION_DAYS=30  
KOF_BACKUP_KEEP_DAYS=30  
KOF_PRIVACY_MODE=true  
```
You can generate a secure secret with:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```
Copy the result into the .env file.

---

## Start the Server

Run:
```bash
npm run dev
```
You should see:
```bash
Kof server running on http://0.0.0.0:3000
```
---

## Access From Other Devices (Phone, Tablet)

Find your computer’s IP address:
```bash
ipconfig  
```
Look for: IPv4 Address  

Example:
```bash
192.168.1.23  
```
On your phone/tablet, open:
```bash
http://192.168.1.23:3000  
```
Staff page:
```bash
http://192.168.1.23:3000/staff.html  
```
Admin page:
```bash
http://192.168.1.23:3000/admin.html  
```

Default admin login for first setup:
```text
username: admin
pin: 1234
```
Change it after you verify the installation works.
---

# PART 2 — Running Kof on Raspberry Pi (Production)

These instructions assume:

- Raspberry Pi 4 (recommended)  
- Raspberry Pi OS (64-bit Lite or Desktop)

---

## Install Raspberry Pi OS

Use Raspberry Pi Imager:  
https://www.raspberrypi.com/software/

Install Raspberry Pi OS and complete initial setup.  
Connect the Pi to the internet.

---

## Install Node.js on Raspberry Pi

Open Terminal and run:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -  
sudo apt install -y nodejs  
```
Check:
```bash
node -v  
npm -v  
```
---

## Copy Kof Project to the Pi

Copy the project folder to:
```bash
/opt/kof-server  
```
You can use:

- USB stick (simplest)  
- scp from your PC  

---

## Install Dependencies

Inside the project folder:
```bash
npm install  
```
---

## Create the .env File on the Pi

Inside:
```bash
/opt/kof-server
```
Run:
```bash
nano .env  
```
Add:
```bash
KOF_TOKEN_SECRET=put-a-long-random-secret-here
KOF_PUBLIC_BASE_URL=http://yourRaspberryIP:3000
KOF_DB_PATH=kof.sqlite
KOF_BACKUP_DIR=backups
KOF_BACKUP_KEEP_DAYS=30
KOF_ORDER_RETENTION_DAYS=30
```
Save with:  
CTRL + O  
ENTER  
CTRL + X  

---

## Test Run

Run:
```bash
npm start  
```
Find the Pi IP:
```bash
hostname -I  
```
Open from another device:
```bash
http://<pi-ip>:3000  
```
If it works, continue.

Default admin login for first setup:
```text
username: admin
pin: 1234
```
Change it after you verify the installation works.

---

# PART 3 — Auto Start on Boot (Very Important)

We want Kof to start automatically when power is turned on.

## Create Service File
```bash
sudo nano /etc/systemd/system/kof.service  
```
Paste:
```bash
[Unit]  
Description=Kof Local Server  
After=network.target  

[Service]  
Type=simple  
WorkingDirectory=/opt/kof-server  
ExecStart=/usr/bin/npm start  
Restart=always  
RestartSec=2  
EnvironmentFile=/opt/kof-server/.env  
User=pi  

[Install]  
WantedBy=multi-user.target  
```
Save and exit.

---

## Enable Service
```bash
sudo systemctl daemon-reload  
sudo systemctl enable kof  
sudo systemctl start kof  
```
Check status:
```bash
sudo systemctl status kof  
```
Now Kof will start automatically after reboot.

---

# PART 4 — Set Static IP (Recommended)

To prevent QR codes from breaking:

## Recommended Method (Router DHCP Reservation)

1. Open your router settings in a browser
2. Find "DHCP Reservation" or "Static Lease"
3. Assign your Raspberry Pi a fixed IP
   Example: 192.168.1.50  

Now always access:
```bash
http://192.168.1.50:3000  
```
---

# PART 5 — Automatic Backups

Kof uses SQLite (a file-based database).  
We recommend daily backups.

## Manual Backup

Inside project folder:
```bash
npm run backup  
```
Backups will appear in:
```bash
/opt/kof-server/backups  
```
---

## Automatic Daily Backup

Open:
```bash
crontab -e  
```
Add:
```bash
0 3 * * * cd /opt/kof-server && /usr/bin/npm run backup  
```
This runs backup every day at 03:00 AM.

---

# PART 6 — Automatic Order Cleanup (GDPR / Storage)

Kof can automatically delete old orders after a set number of days.

Retention is controlled by:
```bash
KOF_ORDER_RETENTION_DAYS=30  
```
0 disables automatic cleanup.

## Manual Cleanup Test
```bash
npm run cleanup  
```
## Automatic Daily Cleanup

Open:
```bash
crontab -e  
```
Add:
```bash
0 4 * * * cd /opt/kof-server && /usr/bin/npm run cleanup  
```
Recommended schedule:

03:00 → Backup  
04:00 → Cleanup old orders  

---

# PART 7 — System Status (Health + Maintenance Info)

Open in a browser:
```bash
http://<ip>:3000/api/status  
```
This shows:

- Privacy mode on/off  
- Retention settings  
- Last backup run (time + result)  
- Last cleanup run (time + result)  

---

# PART 8 — Updating Kof

To update later:
```bash
cd /opt/kof-server  
npm install  
sudo systemctl restart kof  
```
---

# PART 9 — Default Login

Admin page:
```bash
http://<ip>:3000/admin.html  
```
Default login:

Username: admin  
PIN: 1234  

⚠ Change the PIN immediately.

---

# PART 10 — Future Raspberry Pi Hostname Setup (`kof.local`)

If you later deploy Kof on a Raspberry Pi for real table QR code usage,
prefer a local hostname such as:

```bash
http://kof.local:3000
```

instead of a raw IP address like:

```bash
http://192.168.1.204:3000
```

This usually gives a smoother QR scan experience on phones than a raw LAN IP.

## Check or Set the Raspberry Pi Hostname

Check current hostname:

```bash
hostname
```

If needed, change it to:

```bash
kof
```

You can do this with:

```bash
sudo raspi-config
```

or by editing:

```bash
/etc/hostname
```

## Enable Local Hostname Discovery (`.local`)

Install Avahi:

```bash
sudo apt update
sudo apt install avahi-daemon
```

Enable and start it:

```bash
sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon
```

## Test From Another Device on the Same Wi-Fi

Open:

```bash
http://kof.local:3000
```

If it loads correctly, the hostname is working.

## Set Kof Base URL in `.env`

Inside:

```bash
/opt/kof-server/.env
```

set:

```bash
KOF_PUBLIC_BASE_URL=http://kof.local:3000
```

Then restart Kof:

```bash
sudo systemctl restart kof
```

## Regenerate Table QR Codes

After updating `KOF_PUBLIC_BASE_URL`, open the admin page and regenerate the
table QR codes so they point to:

```bash
http://kof.local:3000
```

instead of the old LAN IP.

## Notes

- `:3000` is still required unless you later place Kof behind a reverse proxy.
- If `.local` resolution does not work well on your network, keep using the
  Raspberry Pi LAN IP as fallback.
- If iPhones show network privacy warnings for raw IP QR codes, `.local`
  usually behaves better.

---

# Raspberry Pi Quick Setup Summary

When deploying on a Raspberry Pi:

1. Copy project to /opt/kof-server
2. Create .env inside /opt/kof-server
3. Run npm install
4. Enable and start systemd service
5. Add daily backup cron (03:00)
6. Add daily cleanup cron (04:00)
7. Set router DHCP reservation

---

# DONE

Kof is now:

- Running locally
- Offline capable
- Auto-starting
- Backing up daily
- Automatically cleaning old data
- GDPR-friendly
- Accessible from phones and tablets
