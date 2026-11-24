# Homelab

A documented Linux homelab and media server, built step by step as a hands-on path into entry-level IT work (help desk, IT support, junior sysadmin, NOC).

## Lab Hardware

| Machine | Role | Specs |
|---------|------|-------|
| HP EliteDesk 800 G3 Mini | Always-on server (Ubuntu Server, Docker, Jellyfin) | Intel i5 vPro (7th gen), 8 GB RAM, 256 GB NVMe SSD |
| Windows PC (WSL) | Daily PC and learning machine (Ubuntu in WSL), not part of the lab | |
| Dell OptiPlex 7040 Tower | Proxmox VE host, with backup storage on two 1 TB drives | Intel i7-6700, 16 GB RAM, 238 GB SSD |
| Protectli Vault FW4C | OPNsense firewall/router, in testing | 4 x 2.5 GbE, 8 GB RAM, 120 GB SSD |
| Lenovo ThinkCentre Tiny (2) | Lab and practice machines | i5-4570T and i7-4765T, 16 GB RAM each |
| Ubiquiti USW-Flex-2.5G-8 | Managed switch, adopted into the UniFi controller (in Docker on the EliteDesk) | 8 x 2.5 GbE, 10 GbE uplink |

## What's Here

- [`docs/PLAN.md`](docs/PLAN.md): the 12-week plan and progress log
- [`docs/11-hardening-a-fresh-linux-server.md`](docs/11-hardening-a-fresh-linux-server.md): start here. A one-page summary of how I secured the server.
- `docs/`: one write-up per lesson (what I did, the commands, what broke, how I fixed it)
- `configs/`: configuration files (docker-compose, service configs)
- `scripts/`: bash scripts I've written (`jpush` adds, commits, and pushes this repo in one command; `healthcheck.sh` logs the server's status every 5 minutes via cron; `backup-unifi.sh` copies the UniFi controller's backups to the Tower nightly)
- `diagrams/`: network and lab diagrams

## Progress

See the progress log in [`docs/PLAN.md`](docs/PLAN.md).

## Skills Practiced

Linux administration, users and permissions, SSH, firewalls, Docker, networking, backups, documentation, and Git.
