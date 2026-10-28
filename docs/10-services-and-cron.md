# Lesson 10: systemd Services, a Health-Check Script, and cron

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Learn how Linux manages background services, write a bash script that checks the server's health, and have the system run it automatically on a schedule.

## What I Did

**Part 1: systemd services.** A service is a program that runs in the background (SSH, the firewall, fail2ban). `systemctl` controls them.

```bash
systemctl status ssh --no-pager
systemctl is-active ssh ufw fail2ban
systemctl list-units --type=service --state=failed
systemctl list-unit-files --type=service --state=enabled | head -20
```

**Part 2: the script.** I wrote `~/bin/healthcheck.sh` (a copy is in [`scripts/healthcheck.sh`](../scripts/healthcheck.sh)). It appends one line to `~/healthcheck.log` with the time, uptime, disk use, memory use, and whether SSH, the firewall, and fail2ban are active.

```bash
mkdir -p ~/bin
nano ~/bin/healthcheck.sh
chmod +x ~/bin/healthcheck.sh
~/bin/healthcheck.sh
cat ~/healthcheck.log
```

**Part 3: cron.** I scheduled the script to run every 5 minutes.

```bash
crontab -e
# line added:
*/5 * * * * /home/<server-user>/bin/healthcheck.sh

crontab -l
cat ~/healthcheck.log
```

The five fields in a cron line are minute, hour, day of month, month, and day of week. `*/5 * * * *` means every 5 minutes.

Results worth noting:
- `is-active` printed `active` three times, and the failed-services list showed `0 loaded units listed`.
- `cron.service`, `fail2ban.service` and others are in the enabled list, so they start at boot.
- `ssh.service` showed `disabled` while running, with `TriggeredBy: ssh.socket`. Ubuntu starts SSH on demand through a socket unit, so the service itself isn't marked enabled. It's normal.
- The script ran correctly by hand, then cron added new lines on its own at 19:40:01, 19:45:01, and 19:50:01.
- The log timestamps are in UTC, the server's time zone. That is four hours ahead of my local time (EDT), so 19:50 in the log was 3:50 PM for me.

## What Broke

- **Pasted the script into the shell instead of into nano.** The lines ran as plain commands: the `#` lines were ignored as comments, `LOG=...` set a temporary variable, and I cancelled the last line with Ctrl+C. Nothing was written. Fix: open nano first, then paste inside its window.
- **`cat` said "No such file" right after deleting the log.** The script recreates the log the next time cron runs it, so I had to wait for the next 5-minute mark.
- **`daemon-reload` warning** in `systemctl status ssh`: "unit file ... changed on disk." The update had replaced systemd files. It's harmless, and `sudo systemctl daemon-reload` clears it.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- `systemctl status` shows whether a service is running and its latest log lines. `is-active` gives a one-word answer, which is handy inside scripts.
- `enable` makes a service start at boot. `start` and `stop` change it only for now.
- A script needs a first line (`#!/usr/bin/env bash`) and the execute permission (`chmod +x`) to run on its own.
- `$(command)` puts a command's output inside another command.
- cron runs commands on a schedule. Use full paths in cron lines, because cron doesn't run with my usual shell setup.
- Automation proves itself in the log: new lines appeared without me typing anything.
- The server logs in UTC. Know which time zone I'm reading.

## Next

Write a summary of the whole security setup ("Hardening a fresh Linux server"), then move on to Docker.
