# Homelab & IT Career Plan

Goal: build a documented Linux homelab and media server, publish everything to GitHub, and use it to land an entry-level IT job (help desk, IT support, junior sysadmin, NOC).

**Schedule:** about 2 hrs on weekdays, 4+ hrs on weekends (roughly 18 hrs/week)
**Timeline:** 12 weeks

## Hardware

| Machine | Role | Specs |
|---------|------|-------|
| HP EliteDesk 800 G3 Mini | Always-on server (Ubuntu Server, Docker, Jellyfin) | i5 vPro (7th gen), 8 GB RAM, 256 GB NVMe SSD |
| Dell OptiPlex 7040 Micro | Daily PC and learning machine (Windows + Ubuntu in WSL) | i5, 16 GB RAM, 256 GB SSD |
| Cisco switch (old, managed) | Lab networking practice | |

**Why two machines:** The EliteDesk runs Linux directly, like a real server, and is managed over SSH from the OptiPlex. The OptiPlex stays on Windows so there's always a working daily machine. Early lessons (Git, files, permissions, sudo and users) run in WSL on the OptiPlex; the server work starts once Ubuntu Server is installed on the EliteDesk.

**Note on storage:** A media library fills 256 GB fast. Plan a 1-2 TB drive for the EliteDesk (internal if it has a free bay, otherwise external USB), and check its drive slots before buying. Keep backups on a different drive than the data they protect. If the OptiPlex gets an upgrade instead: it has one 2.5" SATA bay and one M.2 slot, and a drive-compatibility listing says the M.2 slot is SATA-only, so buy a SATA SSD, not NVMe.

**vPro note:** The EliteDesk has Intel AMT (remote management). It isn't needed, so leave it disabled unless I'm deliberately learning it, since a poorly secured AMT is a security risk.

## Working Method

- Every lesson gets a short write-up in the `homelab` GitHub repo: what I did, the commands, what broke, how I fixed it.
- Commit configs (docker-compose files, scripts) alongside the write-ups.
- Never commit passwords, keys, or private IPs you want hidden.

Suggested repo layout:

```
homelab/
  README.md
  docs/
    01-git-ssh-github.md
    02-files-scripts-permissions.md
    03-sudo-and-users.md
    04-install-ubuntu-server.md
    05-ssh-hardening.md
    06-firewall-ufw.md
    07-fail2ban.md
    08-updates.md
    09-reading-logs.md
    10-services-and-cron.md
    11-hardening-a-fresh-linux-server.md
    12-install-docker.md
    13-jellyfin-in-docker.md
    ...
  configs/
  scripts/
  diagrams/
```

## 12-Week Plan

### Weeks 1-2: Foundations
- [x] Ubuntu running in WSL for learning
- [x] Git, SSH keys, and GitHub set up
- [x] File commands, nano, first bash script, rwx permissions
- [x] Create `homelab` repo structure, README, first write-ups
- [x] Sudo and users (in WSL)
- [x] Install Ubuntu Server on the EliteDesk (USB installer, wired network), then SSH in from the OptiPlex
- [x] SSH hardening on the server (key-only login, disable root login)

### Weeks 3-4: Security and system basics
- [x] Firewall (UFW), fail2ban, automatic updates
- [x] Reading logs
- [x] systemd services, cron jobs, simple bash scripts
- [x] Write-up: "Hardening a fresh Linux server"

### Weeks 5-6: Docker and media server
- [x] Install Docker and Docker Compose
- [x] Run Jellyfin in a container with proper storage and permissions
- [ ] Add the media drive to the EliteDesk and set up its mount and permissions
- [x] Commit `docker-compose.yml` and write-up

### Weeks 7-8: Networking (Cisco switch)
- [ ] IP addressing, DHCP, DNS basics, static IP for the server
- [ ] Switch basics: console access, hostname, VLANs, saving configs
- [ ] Optional: Pi-hole for DNS practice
- [ ] Make Docker respect the firewall (Docker bypasses UFW for published ports; restrict with `DOCKER-USER` rules and test)
- [ ] Remote access VPN (WireGuard or Tailscale) to reach the server and add my own media from outside the house, with no router port forwarding for Jellyfin

### Weeks 9-10: Backups and file sharing
- [ ] Samba file shares
- [ ] Automated backups with rsync, plus a tested restore
- [ ] Basic monitoring (htop, Uptime Kuma, or Netdata)

### Weeks 11-12: Polish and apply
- [ ] Clean up repo, add a lab diagram
- [ ] Finalize resume
- [ ] Start applying; keep the lab growing

## Target Jobs

Help desk, IT support technician, Linux support, junior sysadmin, NOC technician. Many are remote or hybrid and mostly seated.

## Resume Framing

- **Headline:** Entry-Level IT / Linux Support Technician, with GitHub link
- **Projects:** Homelab with 3-4 bullets (hardened a Linux server, deployed a Dockerized media server, configured a managed switch, automated backups with tested restores)
- **Past experience:** Truck delivery driver. Emphasize independence, time management, customer interaction, safety and compliance, reliability, troubleshooting on the road.
- **Gap:** One line, e.g. "2023-2026: Recovered from injury; completed self-directed Linux and networking training (see GitHub projects)."

## Certifications (later)

1. CompTIA A+ (most common help desk requirement)
2. Linux+ or Network+

## Back-Friendly Notes

- Aim for seated, remote, or hybrid roles.
- Plan a sit-stand desk setup for working hours.
- Take movement breaks during long study sessions.

## Progress Log

| Date | Lesson | Notes |
|------|--------|-------|
| 2026-10-15 | Git, SSH keys, GitHub | [01-git-ssh-github.md](01-git-ssh-github.md) |
| 2026-10-16 | Files, scripts, permissions | [02-files-scripts-permissions.md](02-files-scripts-permissions.md) |
| 2026-10-18 | Sudo and users | [03-sudo-and-users.md](03-sudo-and-users.md) |
| 2026-10-18 | Install Ubuntu Server on the EliteDesk | [04-install-ubuntu-server.md](04-install-ubuntu-server.md) |
| 2026-10-18 | SSH hardening on the server | [05-ssh-hardening.md](05-ssh-hardening.md) |
| 2026-10-28 | Firewall (UFW) | [06-firewall-ufw.md](06-firewall-ufw.md) |
| 2026-10-28 | fail2ban | [07-fail2ban.md](07-fail2ban.md) |
| 2026-10-28 | Updates and automatic security patches | [08-updates.md](08-updates.md) |
| 2026-10-28 | Reading logs | [09-reading-logs.md](09-reading-logs.md) |
| 2026-10-28 | systemd services, health-check script, cron | [10-services-and-cron.md](10-services-and-cron.md) |
| 2026-10-28 | Write-up: Hardening a fresh Linux server | [11-hardening-a-fresh-linux-server.md](11-hardening-a-fresh-linux-server.md) |
| 2026-10-28 | Install Docker and Docker Compose | [12-install-docker.md](12-install-docker.md) |
| 2026-10-28 | Jellyfin in Docker (Quick Sync hardware transcoding) | [13-jellyfin-in-docker.md](13-jellyfin-in-docker.md) |
| | Fixed IP for the server, then media drive | next up |
