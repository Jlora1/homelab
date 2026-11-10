# Homelab & IT Career Plan

Goal: build a documented Linux homelab and media server, publish everything to GitHub, and use it to land an entry-level IT job (help desk, IT support, junior sysadmin, NOC).

**Schedule:** about 2 hrs on weekdays, 4+ hrs on weekends (roughly 18 hrs/week)
**Timeline:** 12 weeks

## Hardware

| Machine | Role | Specs |
|---------|------|-------|
| HP EliteDesk 800 G3 Mini | Always-on server (Ubuntu Server, Docker, Jellyfin; later Pi-hole and monitoring) | i5 vPro (7th gen), 8 GB RAM, 256 GB NVMe SSD |
| Dell OptiPlex 7040 Tower | Proxmox VE 9.2 host (installed), backup storage on two 1 TB drives | i7-6700, 16 GB RAM, 238 GB SSD |
| Lenovo ThinkCentre Tiny | Planned: OPNsense firewall/router (second network port via a mini PCIe Intel card) | i5-4570T, 16 GB RAM, 256 GB SSD |
| Lenovo ThinkCentre M93p Tiny | Planned: lab and practice virtual machines | i7-4765T, 16 GB RAM, 128 GB SSD |
| TP-Link Omada SG2210XMP-M2 | Managed switch for VLAN practice, and PoE for access points | 8 x 2.5 GbE PoE+ (160 W), 2 x 10G SFP+ |
| Loose 3.5" hard drives | Media storage and backups (health check first) | 4 TB WD Re, 3 x 1 TB (about 2017-2018) |
| Windows PC (WSL) | Daily PC, not part of the lab; used for WSL practice and for managing the servers over SSH | |

**Why several machines:** The EliteDesk runs Linux directly, like a real server, and is managed over SSH from my Windows PC. Early lessons (Git, files, permissions, sudo and users) run in WSL on the Windows PC; the server work started once Ubuntu Server was installed on the EliteDesk. The other machines are being given jobs one at a time, in this order: Proxmox on the Tower, services on the EliteDesk, a lab machine, and OPNsense last (the whole house's internet depends on it).

**Note on storage:** A media library fills 256 GB fast. The 4 TB drive goes in the Tower and the 1 TB drives hold backups, which is enough while the library is under 1 TB. When it grows, add a bigger backup drive. Keep backups on a different drive than the data they protect, and check each old drive's health (SMART) before trusting it. The Tower has one 3.5" bay (the optical bay needs checking), so spare drives live in a USB dock or enclosure.

**Layout decisions so far:**
- Jellyfin stays on the EliteDesk, because its 7th-gen Quick Sync chip transcodes 10-bit HEVC and HDR, which the Tower's 6th-gen chip does not.
- The ThinkCentre Tiny only has one network port and a mini PCIe Wi-Fi slot, so the second port comes from a mini PCIe Intel card (the Wi-Fi card is removed). An M.2 module I bought does not fit it.
- OPNsense is tested on a separate small network before it replaces the Verizon router. Before that: a UPS and the BIOS "After Power Loss: Power On" setting, because a power cut already left the server off for four days.
- Wi-Fi comes from separate access points wired to the switch, not from the router box.

**Later (parked):**
- Local AI tools, on dedicated hardware bought for the purpose. The gaming PC stays out of the lab.
- A bigger backup drive once the library passes 1 TB.
- A commercial VPN for the download client only (kill switch, no leaks). Tailscale already covers remote access to my own machines.
- Home Assistant (smart home control), run as a VM or container on the Tower's Proxmox. Plan the network first: smart devices need to reach it, so decide on VLANs once the switch is set up, and keep them apart from my computers.
- A UPS (battery backup) for the always-on machines.
- A media automation stack, modelled on a diagram of someone else's setup: Seerr (requests), Sonarr and Radarr (manage TV and movies), Prowlarr (indexers), qBittorrent (downloads), feeding Jellyfin through shared storage. Run it as separate containers on the Tower's Proxmox, after the media drive and Samba shares are done. Only use it with content I'm allowed to have (my own media, public domain, Creative Commons, Linux ISOs), and decide how download traffic is kept off my home IP before starting.

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
    14-fixed-ip-dhcp-reservation.md
    15-docker-and-the-firewall.md
    16-tailscale.md
    17-copying-media-to-the-server.md
    18-ssh-agent-and-shortcuts.md
    19-install-proxmox.md
    20-drive-health-and-backup-storage.md
    21-new-ssh-key-and-locking-down-the-servers.md
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

### Weeks 7-8: Networking (TP-Link managed switch)
- [x] Fixed IP for the server (DHCP reservation on the router)
- [ ] IP addressing and DNS basics
- [ ] Switch basics: management page, VLANs, PoE, backing up the config
- [ ] AdGuard Home (network-wide ad blocker, also DNS practice). Run it on the EliteDesk or in a Proxmox container, and point the router's DNS at it once it's tested. Pi-hole does the same job and is the fallback
- [x] Make Docker respect the firewall (Docker bypasses UFW for published ports; restrict with `DOCKER-USER` rules and test)
- [x] Remote access VPN (WireGuard or Tailscale) to reach the server and add my own media from outside the house, with no router port forwarding for Jellyfin

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
| 2026-11-01 | Fixed IP for the server (DHCP reservation) | [14-fixed-ip-dhcp-reservation.md](14-fixed-ip-dhcp-reservation.md) |
| 2026-11-01 | Docker and the firewall (`DOCKER-USER` rules) | [15-docker-and-the-firewall.md](15-docker-and-the-firewall.md) |
| 2026-11-01 | Tailscale (remote access VPN), tested from the PC | [16-tailscale.md](16-tailscale.md) |
| 2026-11-01 | Copy my own media with scp and play it in Jellyfin | [17-copying-media-to-the-server.md](17-copying-media-to-the-server.md) |
| 2026-11-01 | fail2ban now ignores the tailnet range | [07-fail2ban.md](07-fail2ban.md) |
| 2026-11-01 | ssh-agent, keychain and the `ssh goodmedia` shortcut | [18-ssh-agent-and-shortcuts.md](18-ssh-agent-and-shortcuts.md) |
| 2026-11-08 | Install Proxmox VE on the OptiPlex Tower | [19-install-proxmox.md](19-install-proxmox.md) |
| 2026-11-09 | Drive health (SMART) and backup storage in Proxmox | [20-drive-health-and-backup-storage.md](20-drive-health-and-backup-storage.md) |
| 2026-11-09 | New SSH key, and key-only logins on both servers | [21-new-ssh-key-and-locking-down-the-servers.md](21-new-ssh-key-and-locking-down-the-servers.md) |
| | First practice VM, a backup job for it, and a test restore | next up |
| | The media drive (the old 4 TB failed its SMART test; buy a replacement with a warranty) | parked |
