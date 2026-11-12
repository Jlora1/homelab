# Lesson 24: Updating the Jellyfin Server and Rebooting Safely

**Date:** 2026-11-11
**Machine:** EliteDesk 800 G3 Mini (`goodmedia`, Ubuntu Server 26.04.1)

## Goal

Install the 28 waiting updates (20 of them security updates) on the Jellyfin server, restart into the new kernel, and check that everything came back.

## Background

- `apt update` refreshes the list of available updates. `apt upgrade` installs them. They are two separate steps.
- Security updates fix known holes, so a server that is reachable on the network shouldn't sit on them.
- A new **kernel** (the core of the operating system) only starts running after a **reboot**. The installer prints "Pending kernel upgrade" and shows the running and expected versions.
- A Docker container only comes back after a reboot if it has a **restart policy** such as `unless-stopped` or `always`.
- I did this **after** the config backup to the Tower existed (lesson 23), so a bad update couldn't cost me my settings.

## What I Did

```bash
sudo apt update
sudo apt upgrade
```

- The upgrade ended with "Pending kernel upgrade! Running kernel version: 7.0.0-42-generic" and "No services need to be restarted" and "No containers need to be restarted".
- Checked that Jellyfin would return by itself, then restarted: `sudo reboot`. <!-- TODO: note what the restart policy check printed, and how long the reboot took -->
- Logged back in with `ssh goodmedia`. The login screen said **0 updates can be applied**.
- Checked the result:

```bash
uname -r
sudo docker ps --format '{{.Names}}: {{.Status}}'
```

Results:
- The kernel was `7.0.0-43-generic`, the new one.
- Jellyfin showed `Up 2 hours (healthy)`, so it started by itself after the reboot.
- The login screen showed 5% of the 231 GB disk used, memory 6%, and 38 °C.

## What Broke

Nothing broke this time.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- Updating takes two commands, and a new kernel needs a reboot before it counts.
- Do updates after a backup exists, not before.
- Check that a service restarts by itself before rebooting a server, and check it again afterwards.
- `docker ps` shows "healthy" when a container's built-in health check passes.

## Not Done Yet

- ~~Check the log for the first scheduled backup run.~~ Done: it ran at 08:00 UTC on 2026-11-12 with exit code 0 (lesson 26).
- ~~Check the Tower for updates.~~ Done in lesson 26: it was already up to date. The practice VM still has 51 waiting.
- ~~Turn on automatic security updates.~~ Already on by default (lesson 26). I still choose when to reboot.

## Next

Networking: pick the managed switch, then OPNsense on the Protectli and the ad blocker (see `PLAN.md`).
