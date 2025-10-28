# DECISION.md

## 🧠 Overview
Here's my reasoning and design choices behind my Stage 2 DevOps task: Automated Blue/Green setup using Nginx upstreams for seamless traffic switching and health-based failover.

---

## ⚙️ Key Design Decisions

### 1. **Using Docker Compose**
Using Docker Compose to orchestrate Nginx, Blue, and Green containers because it provides:
- Simple YAML-based orchestration
- Easy environment variable injection via `.env`
- Portable setup that works identically in CI and locally

---

### 2. **Blue/Green Architecture**
- **Blue** is the active service.
- **Green** is the standby (backup) service.
- Nginx routes traffic to Blue by default.
- On failure, Nginx automatically retries and routes to Green (as the backup).

This ensures *zero downtime* during application failure or deployment rollout.

---

### 3. **Dynamic Failover Agent (`health_agent.sh`)**
This health monitoring script runs **inside the Nginx container** as part of the same service process in Docker Compose, avoiding the need for a separate sidecar container.

It performs the following actions:
- Continuously checks the /healthz endpoint of both Blue and Green services.
- Detects when the active app (Blue) becomes unhealthy (timeout or non-200 response).
- Automatically updates the Nginx upstream target using `envsubst` and reloads Nginx (`nginx -s reload`).
- Validates the new configuration with `nginx -t` before applying changes.

Once Blue recovers, the script switches traffic back seamlessly.

This design eliminates the need for external orchestrators like Kubernetes or HAProxy while still achieving near-real-time, zero-downtime failover using only lightweight Docker and shell scripting.

---

### 4. **Nginx Configuration Templating**
`envsubst` was used to dynamically render the Nginx configuration template:
- Keeps `nginx.conf.template` generic
- Automatically adjusts based on `$ACTIVE_POOL` and `$RELEASE_ID`
- Prevents manual config editing

---

### 5. **Environment Parameterization**
All variables (images, release IDs, ports, and active pool) are in `.env`:
- CI can inject values easily
- Same Compose file works for both local and automated environments

---

### 6. **Why No Third-Party Tools**
- Simplicity and transparency were key requirements for this task, so tools like Consul, HAProxy, or Traefik were intentionally avoided.
- Task constraints prohibit service meshes or Kubernetes

---

## 🔍 Trade-offs Considered
- This workflow was built with simplicity over full automation (manual toggle still possible)
- Nginx reloads instead of hot-swap upstreams (acceptable for small setup)
- Health checks every 5 seconds for balance between responsiveness and stability

---

## ✅ Outcome
This setup achieves:
- Fully working Blue/Green deployment
- Zero-failure automatic failover
- Clean CI-ready design
- Easy manual override if needed

---

## 🧰 Future Improvements
- Add Prometheus exporter for health metrics
- Use Lua or Nginx Plus for smoother live upstream rebalancing
- Containerize `health_agent.sh` as a separate lightweight sidecar

---

## 🏁 Summary
This Blue/Green deployment demonstrates a lightweight, Docker-native failover solution using Nginx and shell scripting. It balances reliability and simplicity, aligning perfectly with DevOps best practices for CI-ready environments.

---

## Author: Faith Omobude
`DevOps Intern - HNG13`