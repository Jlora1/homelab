# Hardening a Fresh Linux Server

**Date:** 2026-10-28
**Server:** HP EliteDesk 800 G3 Mini running Ubuntu Server 26.04.1 LTS, managed over SSH from a Windows PC (WSL)

A summary of how I took a freshly installed Ubuntu server and secured it, layer by layer, and how I checked that each layer worked. Each step links to the full lesson with the commands, the mistakes I made, and how I fixed them.

## Starting Point

A clean install on a home network with SSH enabled, a normal user with `sudo`, and password login. Nothing was protecting it beyond a password.

## What I Set Up

| Layer | What it does | How I checked it | Lesson |
|-------|--------------|------------------|--------|
| **Key-only SSH** | Logs in with an ed25519 key (protected by a passphrase) instead of a password | Logged in with the key after the change | [05](05-ssh-hardening.md) |
| **Password and root login off** | Removes password guessing as an attack, and blocks direct root login (`/etc/ssh/sshd_config.d/10-hardening.conf`) | `sshd -t` for syntax, `sshd -T` for the effective settings, and both refused from another machine with `Permission denied (publickey)` | [05](05-ssh-hardening.md) |
| **Firewall (UFW)** | Blocks all incoming connections except SSH | `ufw status verbose` showed `deny (incoming)` with SSH allowed, then a new SSH login still worked | [06](06-firewall-ufw.md) |
| **fail2ban** | Bans an IP for 1 hour after 5 failed SSH logins in 10 minutes; my home network is exempt | `fail2ban-client -t` for the config, `status sshd` showed the jail running | [07](07-fail2ban.md) |
| **Automatic updates** | Installs security updates daily without me | Setting `"1"` in `20auto-upgrades`, a clean `unattended-upgrade --dry-run`, 22 packages upgraded by hand, including a new kernel | [08](08-updates.md) |
| **Reboot test** | Proves the server recovers on its own | After a reboot: new kernel running, firewall active, fail2ban jail running | [08](08-updates.md) |
| **Log review** | Shows who logged in, what failed, and what services did | Read `auth.log` and `journalctl`; found my own logins, my own typos, and harmless hardware warnings | [09](09-reading-logs.md) |
| **Scheduled health check** | A script run by cron every 5 minutes records uptime, disk, memory, and the state of SSH, the firewall, and fail2ban | New log lines appeared every 5 minutes with no input from me | [10](10-services-and-cron.md) |

## Design Choices

- **Order matters.** I confirmed key login worked before turning password login off, and allowed SSH in the firewall before enabling it. Both prevent locking myself out.
- **Test from a second connection.** I kept one session open while checking a change from another, so a mistake could be undone.
- **Check, then apply.** Config checks (`sshd -t`, `fail2ban-client -t`) came before every reload or restart.
- **Custom settings in their own files.** SSH settings went in a `sshd_config.d` drop-in and fail2ban settings in `jail.local`, so package updates don't overwrite my changes.
- **Defense in depth.** Even with password login off, the firewall and fail2ban add layers, and each one is checked separately.

## Mistakes and What They Taught Me

- Running a test on the wrong machine proved nothing. I now check the prompt before every command.
- Typing a file path by itself runs it as a command. Open files with an editor.
- Pasting into the wrong window runs the text as commands. Wait for nano to open first.
- A reboot is a useful test, not just a chore.

## Key Configuration

SSH hardening, in `/etc/ssh/sshd_config.d/10-hardening.conf`:

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

Firewall:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw enable
```

fail2ban, in `/etc/fail2ban/jail.local`:

```
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1 <home-network>/24

[sshd]
enabled = true
```

Health check: [`scripts/healthcheck.sh`](../scripts/healthcheck.sh), run by cron every 5 minutes (`*/5 * * * *`).

## Scope and Next Steps

This is a home-lab server on my local network. Still to do: a fixed address for the server, backups with a tested restore, monitoring, and then Docker and Jellyfin ([plan](PLAN.md)).
