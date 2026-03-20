# mywebapp: Automated Web Service Deployment

[![OS: Ubuntu 24.04](https://img.shields.io/badge/OS-Ubuntu_24.04-orange?style=flat-square&logo=ubuntu)](https://ubuntu.com/)
[![Stack: Python/Flask](https://img.shields.io/badge/Stack-Python_Flask-blue?style=flat-square&logo=flask)](https://flask.palletsprojects.com/)
[![DB: PostgreSQL](https://img.shields.io/badge/DB-PostgreSQL-blue?style=flat-square&logo=postgresql)](https://www.postgresql.org/)

## 📖 Project Overview
This project is a fully automated deployment of a **Simple Inventory** web service. It uses **Nginx** as a reverse proxy, **PostgreSQL** for data persistence, and **Systemd** for process management. The deployment is fully scripted via Vagrant and Bash.

### 🧮 Individual Variant (N=29)
Based on the student number **29**, the following variants were implemented:
* **V2 (Database & Config):** `(29 % 2) + 1 = 2` → **PostgreSQL** and **TOML Config File**.
* **V3 (Application Topic):** `(29 % 3) + 1 = 3` → **Simple Inventory**.
* **V5 (Application Port):** `(29 % 5) + 1 = 5` → **Port 5000**.

---

## ⚙️ System Architecture

* **Reverse Proxy (Nginx):** Listens on Port 80, routes external traffic to the application, and blocks external access to health checks.
* **Application (Python/Flask):** Runs on Port 5000 as the restricted `app` user from `/opt/mywebapp`.
* **Database (PostgreSQL):** Bound to `127.0.0.1:5432`, restricted to local access.
* **Configuration:** Stored separately in `/etc/mywebapp/config.toml`.

---

## 🚀 Deployment Guide

To deploy the system automatically, clone the repository and run the setup script on a fresh Ubuntu machine (or via Vagrant):

```bash
vagrant up
```

### Access Credentials
* **student:** Full sudo access.
* **teacher:** Sudo access; default password `12345678` (reset required on first login).
* **operator:** Limited sudo access (only `systemctl start/stop/status/restart mywebapp` and `systemctl reload nginx`); default password `12345678` (reset required on first login).

---

## 👨‍🏫 Teacher Instructions & Grading Guide

This section is specifically for the instructor reviewing the laboratory work.

### 1. Initial Login & Password Reset
To begin grading, SSH into the virtual machine using the `teacher` account.
```bash
ssh -p 2222 teacher@127.0.0.1
```
* **Default Password:** `12345678`
* **Note:** The system is configured with `chage -d 0` to force a password change immediately upon your first login. You will be prompted to enter the current password, then a new password of your choosing.

### 2. Verify Infrastructure Requirements
Once logged in, you can verify the specific variant requirements have been met:

**Verify Database Schema & Migration (Requirement: Tables & Indexes):**
```bash
sudo -u postgres psql -d mywebapp_db -c "\d inventory"
sudo -u postgres psql -d mywebapp_db -c "\di"
```

**Verify Operator Permissions (Requirement: Limited sudo execution):**
```bash
sudo -l -U operator
```

**Verify Configuration File (Requirement: TOML format):**
```bash
sudo cat /etc/mywebapp/config.toml
```

**Verify Systemd & Execution Paths (Requirement: Run as app, migrate before start):**
```bash
systemctl cat mywebapp.service
```

**Verify Gradebook (Requirement: Contains variant number):**
```bash
cat /home/student/gradebook
```

---

## 🔌 API Testing Guide

The API supports **Content Negotiation**. It returns JSON by default but returns HTML structures if the `Accept: text/html` header is provided. You can test these endpoints directly from the VM terminal.

### Business Logic Endpoints (Public via Port 80)

**🏠 Root Directory (Lists endpoints)**
```bash
curl -i [http://127.0.0.1/](http://127.0.0.1/)
```

**➕ Create an Inventory Item**
```bash
curl -X POST [http://127.0.0.1/items](http://127.0.0.1/items) \
     -H "Content-Type: application/json" \
     -d '{"name": "Cisco Router", "quantity": 10}'
```

**📜 List All Items (Content Negotiation)**
```bash
# JSON output:
curl -H "Accept: application/json" [http://127.0.0.1/items](http://127.0.0.1/items)

# HTML table output:
curl -H "Accept: text/html" [http://127.0.0.1/items](http://127.0.0.1/items)
```

### Health Check Endpoints (Internal Only)
Per security requirements, these are **blocked by Nginx on port 80** and can only be accessed internally on port `5000`.

**💓 Liveness Probe**
```bash
# This will fail (404/403) via Nginx:
curl -I [http://127.0.0.1/health/alive](http://127.0.0.1/health/alive)

# This will succeed via internal port:
curl [http://127.0.0.1:5000/health/alive](http://127.0.0.1:5000/health/alive)
```

**🩺 Readiness Probe**
```bash
# This will succeed (200 OK) if DB is connected:
curl [http://127.0.0.1:5000/health/ready](http://127.0.0.1:5000/health/ready)
```
