# Lesson 32: Monitoring the Lab With Uptime Kuma

**Date:** 2026-11-22
**Machine:** EliteDesk 800 G3 Mini (`goodmedia`)

## Goal

Find out when something in the lab goes down, instead of discovering it later. In lesson 29 the Tower was unplugged and the nightly backups failed without anything telling me.

## Background

- **Uptime Kuma** is a self-hosted dashboard. It checks each service every 60 seconds, shows green or red, keeps an uptime history, and can send alerts.
- Check types I used:
  - **Ping** asks whether a machine answers at all.
  - **HTTP(s)** asks whether a web page answers. A `200` reply means OK.
  - **DNS** asks the DNS server for a name and checks it answers.
- Proxmox and the UniFi controller use **self-signed certificates**, so their HTTPS checks need **Ignore TLS/SSL errors** ticked, or they show red while working.
- Docker image tags matter: `latest` for Uptime Kuma still points at the old, unmaintained **v1**. The recommended tag is **`2`**.
- **ntfy** sends push notifications to a phone app. On the free `ntfy.sh` server anyone who knows a topic name can read it, so the topic name should be long and random, and it stays out of this repo.

## What I Did

**Created the folders and compose file** (copy in [`configs/uptime-kuma/`](../configs/uptime-kuma/docker-compose.yml)). The port is bound to `192.168.1.187` only:

```bash
mkdir -p ~/uptime-kuma && cd ~/uptime-kuma
sudo mkdir -p /srv/uptime-kuma/data
# docker-compose.yml with image louislam/uptime-kuma:2
sudo docker compose up -d
sudo docker ps --format '{{.Names}}: {{.Image}} {{.Status}}'
```

It reported `uptime-kuma: louislam/uptime-kuma:2 Up ... (healthy)`. The logs showed version **2.5.12**.

**Ran the setup** at `http://192.168.1.187:3001`: chose **SQLite** as the database, then created the admin account.

**Added six monitors**, every 60 seconds:

| Name | Type | Target |
|------|------|--------|
| Tower | Ping | `192.168.1.178` |
| ProxMox | HTTP(s) | `https://192.168.1.178:8006` (ignore TLS errors) |
| JellyFin | HTTP(s) | `http://192.168.1.187:8096/health` |
| Unifi controller | HTTP(s) | `https://192.168.1.187:8443` (ignore TLS errors) |
| Switch sw-office | Ping | `192.168.1.205` |
| DNS | DNS | `google.com` through `192.168.1.187`, port 53 |

All six turned green: ProxMox and the UniFi controller answered `200 - OK`.

**Set up phone alerts:** installed the ntfy app, subscribed to a private random topic, and added an **ntfy** notification in Kuma (Settings → Notifications) with **Default enabled** and **Apply on all existing monitors**.

## What Broke

1. The first start showed **"This Uptime Kuma version is outdated!"** (1.23.17, the `latest`/v1 image).
2. Clicking **Create** on the account page did nothing.
3. Three monitors showed red:

   ```
   [JellyFin] [DOWN] getaddrinfo ENOTFOUND http
   [ProxMox] [DOWN] getaddrinfo ENOTFOUND https
   [Unifi controller] [DOWN] getaddrinfo ENOTFOUND https
   [Tower] [DOWN] connect ECONNREFUSED 192.168.1.178:443
   ```

4. The first ntfy test notification didn't arrive.

## How I Fixed It

1. Stopped it, cleared the empty data folder, and switched the image to the v2 tag:

   ```bash
   sudo docker compose down
   sudo rm -rf /srv/uptime-kuma/data/*
   sed -i 's|louislam/uptime-kuma:.*|louislam/uptime-kuma:2|' docker-compose.yml
   sudo docker compose pull && sudo docker compose up -d
   ```

2. The old browser tab was still talking to the v1 container. A fresh tab showed v2's **database choice** first (SQLite). The browser window was half off-screen, which hid that button. After that, creating the account worked.
3. The URL box already starts with `https://`, and I typed the address after it, making `https://http://...`. Kuma then looked for a computer called "http". Clearing the box and typing the full URL once fixed all three. The Tower alert came from before I switched that monitor to **Ping**: the Tower has no web page on port 443.
4. Fixed the ntfy settings until the test notification reached my phone.

## What I Learned

- Check a Docker image's recommended tag. `latest` doesn't always mean newest.
- `ENOTFOUND` means the name couldn't be looked up, which is often a typo in the address.
- `ECONNREFUSED` means the machine is up, but nothing is listening on that port.
- Self-signed certificates are normal in a homelab. Monitors need to be told to accept them.
- Monitoring turns "I'll notice eventually" into an alert within a minute.
