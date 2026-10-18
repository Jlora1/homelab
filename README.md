# Homelab

A documented Linux homelab and media server, built step by step as a hands-on path into entry-level IT work (help desk, IT support, junior sysadmin, NOC).

## Lab Hardware

| Machine | Role | Specs |
|---------|------|-------|
| HP EliteDesk 800 G3 Mini | Always-on server (Ubuntu Server, Docker, Jellyfin) | Intel i5 vPro (7th gen), 8 GB RAM, 256 GB SSD |
| Dell OptiPlex 7040 Micro | Daily PC and learning machine (Windows + Ubuntu in WSL) | Intel i5, 16 GB RAM, 256 GB SSD |
| Cisco switch | Lab networking practice | Managed |

## What's Here

- [`docs/PLAN.md`](docs/PLAN.md): the 12-week plan and progress log
- `docs/`: one write-up per lesson (what I did, the commands, what broke, how I fixed it)
- `configs/`: configuration files (docker-compose, service configs)
- `scripts/`: bash scripts I've written (`jpush` adds, commits, and pushes this repo in one command)
- `diagrams/`: network and lab diagrams

## Progress

See the progress log in [`docs/PLAN.md`](docs/PLAN.md).

## Skills Practiced

Linux administration, users and permissions, SSH, firewalls, Docker, networking, backups, documentation, and Git.
