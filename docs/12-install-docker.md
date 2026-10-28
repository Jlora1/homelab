# Lesson 12: Install Docker and Docker Compose

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Install Docker and Docker Compose on the server so I can run services like Jellyfin in containers instead of installing them directly on the system.

## What I Did

- Checked that Ubuntu's own repositories offer both packages for this release.
- Installed `docker.io` (Docker Engine) and `docker-compose-v2` (the `docker compose` command).
- Confirmed the service was running and the versions, then ran the `hello-world` test container.

```bash
apt-cache policy docker.io docker-compose-v2
sudo apt install docker.io docker-compose-v2

sudo systemctl is-active docker
sudo docker --version
docker compose version
sudo docker run hello-world
```

Results worth noting:
- Both packages had a candidate version: Docker 29.1.3 and Compose 2.40.3.
- The install pulled in 9 packages in total (about 348 MB), including `containerd` and `runc`, the pieces that actually run containers.
- `docker` showed `active`, and `hello-world` printed `Hello from Docker!`, which confirms the whole chain works: the client talked to the daemon, which pulled an image from Docker Hub and ran it.
- I'm using `sudo` with Docker rather than adding my user to the `docker` group. Membership in that group gives root-level power over the machine, so it follows least privilege (Lesson 03) to keep using `sudo` for now.

## What Broke

- **Ran the install on the wrong machine first.** My prompt said `<wsl-user>@DESKTOP-...`, so Docker was installed in WSL, not on the server. The clue was the disk line: the installer said "1024 GB available", but the server's disk is about 232 GB. I connected to the server over SSH and ran the same commands there. Docker in WSL is harmless and still useful for testing.
- **Sudo password rejected once** before it was accepted.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A container is a small, isolated package with a program and everything it needs. It's easier to update or remove than installing software directly.
- Docker Engine is the service that runs containers. `docker compose` reads a file that describes a whole setup, which I can save in this repo.
- `hello-world` is a quick test that the install works.
- Docker can open ports in a way that bypasses UFW rules. I need to account for that before exposing anything, which I'll do with Jellyfin.
- Check the prompt and the disk size to know which machine I'm on.

## Next

Run Jellyfin in a container with a compose file, using hardware transcoding (Intel Quick Sync) and proper storage and permissions.
