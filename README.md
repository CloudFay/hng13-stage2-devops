# 🚀 Blue/Green Deployment with Nginx — HNG13 Stage 2 (DevOps)

This project implements a Blue/Green deployment architecture using Nginx upstreams for seamless traffic routing, automatic health-based failover, and manual toggle capability — all running inside Docker Compose.

It demonstrates how to maintain zero downtime when the primary (Blue) service becomes unavailable by instantly switching traffic to the backup (Green) instance.

---


## 📋 Features

- Blue/Green architecture using Nginx upstreams
- Automatic failover when the active (Blue) app becomes unhealthy
- Seamless switch back when Blue recovers
- Environment-variable-based Nginx templating with `envsubst`
- Fully parameterized via `.env` (for local & CI use)
- Simple Docker Compose orchestration — no rebuilds required
- Clean, production-style logging and isolation between services

---


## ⚙️ Components

| Component           | Description                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------- |
| **Nginx**           | Reverse proxy that routes traffic to Blue by default and fails over to Green on errors.     |
| **Blue Service**    | Active Node.js instance (receives live traffic).                                            |
| **Green Service**   | Backup Node.js instance (used when Blue fails).                                             |
| **health_agent.sh** | Custom shell agent that monitors health, switches upstreams, and reloads Nginx dynamically. |
| **Docker Compose**  | Orchestrates containers and injects environment variables into Nginx templates.             |


---


## 🧰 Prerequisites

Before running the stack, ensure you have:
- Docker and Docker Compose installed
- Git for cloning the repository
- Bash shell (Linux, macOS, or WSL recommended)
- Internet connection (for pulling container images)

---


## ⚙️ Setup & Usage

### 1️⃣ Clone this Repository

`git clone https://github.com/CloudFay/hng13-stage2-devops.git`

`cd hng13-stage2-devops`


---


### 2️⃣ Create Environment File

`cp .env.example .env`

Then, edit .env to include your environment variables.

Example:

`BLUE_IMAGE=your-blue-image`

`GREEN_IMAGE=your-green-image`

`ACTIVE_POOL=blue`

`RELEASE_ID_BLUE=v1.0-blue`

`RELEASE_ID_GREEN=v1.0-green`

`PORT=8080`



---



### 3️⃣ Run the Stack

`docker-compose up -d`


---


### 4️⃣ Verify Containers

`docker ps`

**You should see the three containers running.**



---


## 🔍 Testing NGINX routing & Validation


### ✅ Check Active Pool (Blue)


`curl -i http://localhost:8080/version`


Expected response:

`HTTP/1.1 200 OK`

`Server: nginx/1.27.0`

`Content-Type: text/html`

...

`<html>`

`<head><title>Welcome to nginx!</title></head>`


**This confirms Nginx → Blue → Client flow works fine.**


---


### Check individual app containers

You can directly hit Blue and Green too:

`curl -i http://localhost:8081`

`curl -i http://localhost:8082`


---


## 🧨 Simulate Failure

### Run:

`curl -X POST http://localhost:8081/chaos/start?mode=error`

Wait a few seconds, then:

`curl -i http://localhost:8080/version`

Expected response:

`X-App-Pool: green`

`X-Release-Id: v1.0-green`

**The switch occurs automatically with no client errors.**


---


### 🩵 Recover Blue

`curl -X POST http://localhost:8081/chaos/stop`


**The health agent detects recovery and reverts traffic back to Blue.**



---


## 🧰 Project Structure

hng13-stage2-devops/

├── docker-compose.yml

├── .env.example

├── nginx/

│   └── nginx.conf.template

├── scripts/

│   └── health_agent.sh

├── README.md

└── DECISION.md


---



## ⚙️ How It Works

1. **Nginx** starts with a config generated from `nginx.conf.template` using environment variables.

2. **health_agent.sh** runs inside the Nginx container and continuously checks the `/healthz` endpoints.

3. When Blue becomes unhealthy:

- The script sets `ACTIVE_POOL=green`

- Re-renders the Nginx config with `envsubst`

- Validates the new config (`nginx -t`)

- Reloads Nginx instantly (`nginx -s reload`)

4. When Blue recovers, traffic switches back seamlessly.

**This ensures no downtime and zero failed client requests during transition.**


---



## 🪵 Logging

View logs from the health agent and Nginx:

`docker logs nginx-proxy`


You’ll see messages like:

`[health-agent] Blue unhealthy → switching to green`

`[health-agent] Blue recovered → switching back`


---


## ⚙️ Manual Toggle (Optional)

You can manually switch the active pool:

`export ACTIVE_POOL=green`

`docker exec nginx-proxy nginx -s reload`


---


## ⚙️ TroubleShooting Fix


| Issue                | Possible Cause                                        | Fix                                    |
| -------------------- | ----------------------------------------------------- | -------------------------------------- |
| No failover detected | Health agent not running                              | Check `docker logs nginx-proxy`        |
| Nginx reload errors  | Invalid template                                      | Run `docker exec nginx-proxy nginx -t` |
| Wrong headers        | Ensure headers are forwarded in Nginx config          |                                        |
| Chaos tests fail     | Ensure the app containers expose port 8080 internally |                                        |


---


## 📦 Files Explained

| File                        | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `.env.example`              | Template for environment variables                |
| `docker-compose.yml`        | Service orchestration for Nginx + Blue/Green      |
| `nginx/nginx.conf.template` | Template used by `envsubst` for dynamic upstreams |
| `scripts/health_agent.sh`   | Health monitoring & failover logic                |
| `DECISION.md`               | Detailed explanation of design choices            |


---


## 🧰 Future Improvements

- Containerize `health_agent.sh` as a sidecar process

- Add Prometheus/Grafana metrics for visibility

- Integrate Slack or webhook notifications for failover events

- Implement rolling updates for release switching


---


## 👨‍💻 Author: Faith Omobude
`DevOps Intern — HNG13 🚀`
