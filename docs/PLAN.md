# Homelab & IT Career Plan

Goal: build a documented Linux homelab and media server, publish everything to GitHub, and use it to land an entry-level IT job (help desk, IT support, junior sysadmin, NOC).

**Schedule:** about 2 hrs on weekdays, 4+ hrs on weekends (roughly 18 hrs/week)
**Timeline:** 12 weeks

## Hardware

| Item | Details |
|------|---------|
| Server | Dell OptiPlex 7040 Micro, i5 |
| RAM | 16 GB (plenty for Docker, Jellyfin, and more) |
| Storage | 256 GB (fine for the OS, Docker, and configs) |
| Network | Old Cisco switch |

**Note on storage:** 256 GB is enough for the system, but a media library fills it fast. Plan on adding an external USB drive (1-2 TB) for media and backups around Week 5-6.

## Working Method

- Every lesson gets a short write-up in the `homelab` GitHub repo: what I did, the commands, what broke, how I fixed it.
- Commit configs (docker-compose files, scripts) alongside the write-ups.
- Never commit passwords, keys, or private IPs you want hidden.

Suggested repo layout:

```
homelab/
  README.md
  docs/
    01-sudo-and-users.md
    02-ssh-hardening.md
    ...
  configs/
  scripts/
  diagrams/
```

## 12-Week Plan

### Weeks 1-2: Foundations
- [ ] Sudo, users, groups, file permissions
- [ ] Install Ubuntu Server or Debian on the 7040
- [ ] SSH hardening (key-only login, disable root login)
- [ ] Create `homelab` repo structure, README, first write-ups

### Weeks 3-4: Security and system basics
- [ ] Firewall (UFW), fail2ban, updates, reading logs
- [ ] systemd services, cron jobs, simple bash scripts
- [ ] Write-up: "Hardening a fresh Linux server"

### Weeks 5-6: Docker and media server
- [ ] Install Docker and Docker Compose
- [ ] Run Jellyfin in a container with proper storage and permissions
- [ ] Add external drive for media
- [ ] Commit `docker-compose.yml` and write-up

### Weeks 7-8: Networking (Cisco switch)
- [ ] IP addressing, DHCP, DNS basics, static IP for the server
- [ ] Switch basics: console access, hostname, VLANs, saving configs
- [ ] Optional: Pi-hole for DNS practice

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
| | Sudo and users | next up |
