# Lesson 31: The UniFi Network Controller in Docker

**Date:** 2026-11-22 (set up the same day, before lesson 28. Written up afterwards from the live files.)
**Machine:** EliteDesk 800 G3 Mini (`goodmedia`)

## Goal

Run Ubiquiti's UniFi Network controller on my own server, so it can adopt and manage the new switch (lesson 28) without a cloud account or a separate UniFi box.

## Background

- The controller is two containers:
  - **`unifi-network-application`** (the linuxserver.io image) is the controller itself, with the web page and the inform port devices report to.
  - **`unifi-db`** (`mongo:7.0`) is the MongoDB database it keeps everything in. Newer versions of the controller no longer bundle a database, so it runs separately.
- **`init-mongo.sh`** runs only once, the first time `unifi-db` starts with an empty data folder, and creates the `unifi` database user.
- **Passwords live in `~/unifi/.env`**, readable only by me (`-rw-------`). Docker Compose reads `.env` from the same folder automatically and fills in `${MONGO_PASS}` and `${MONGO_ROOT_PASS}`. The repo has only `.env.example` with dummy values, and `.gitignore` blocks any real `.env`.
- The container talks to the database by its name, **`unifi-db`**, because both are on the same Compose network.

## What I Did

Files on `goodmedia` (copies in [`configs/unifi/`](../configs/unifi/)):

```
~/unifi/docker-compose.yml   # both containers
~/unifi/init-mongo.sh        # first-start database user setup
~/unifi/.env                 # passwords (chmod 600, not in the repo)
```

Data is stored outside the containers, like Jellyfin:

| Host folder | Container | What's in it |
|-------------|-----------|--------------|
| `/srv/unifi/db` | `unifi-db:/data/db` | the MongoDB database |
| `/srv/unifi/config` | `unifi-network-application:/config` | controller settings and backups (`data/backup/`) |

Published ports on the controller:

| Port | Used for |
|------|----------|
| 8443/tcp | web page (`https://192.168.1.187:8443`) |
| 8080/tcp | inform: adopted devices report here |
| 3478/udp | STUN |
| 10001/udp | device discovery |
| 8843, 8880, 6789 | guest portal and speed test |

Started it from `~/unifi`:

```bash
cd ~/unifi
sudo docker compose up -d
sudo docker ps --format '{{.Names}}: {{.Ports}}'
```

Then set up the controller in the browser. In **Device Updates & Settings**, I set **Inform Host Override** to `192.168.1.187`, so adopted devices report to the server's real address instead of the container's internal Docker one.

Found where each compose file lives later with:

```bash
sudo docker inspect unifi-network-application unifi-db --format '{{.Name}}: {{index .Config.Labels "com.docker.compose.project.config_files"}}'
```

## What Broke

Not recorded at the time. The problems that came up when adopting the switch are in lesson 28.

## How I Fixed It

See lesson 28. The main Docker-specific lesson: discovery broadcasts don't reach a container on Docker's default network, so devices have to be given the inform URL some other way.

**Still to check:** whether the live `~/unifi/docker-compose.yml` reads the passwords from `.env` (`${...}`) or has them typed in directly. If they're typed in, move them into `.env` like the repo copy.

## What I Learned

- Some apps need a separate database container. Compose starts them together and lets them find each other by name.
- Secrets go in a `chmod 600` `.env` file next to the compose file, never in the repo. A `.env.example` shows which values are needed.
- Mapping the data folders to `/srv/...` means the containers can be deleted and recreated without losing anything. It's also what makes backing them up easy (lesson 29).
- `docker inspect` can show where a container's compose file and data folders are.
