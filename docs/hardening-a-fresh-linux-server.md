# Hardening a Fresh Linux Server

A summary of how I secured a new Ubuntu Server on my homelab, with links to the detailed lesson write-ups. Every step was done by hand over SSH and tested before moving on.

**Server:** HP EliteDesk 800 G3 Mini, Ubuntu Server 26.04.1 LTS, wired network, no monitor needed after setup
**Managed from:** Ubuntu (WSL) on a Windows PC, over SSH

## The problem

A fresh server installs with password logins on and almost no protection beyond whatever the installer set up. Anything reachable on the network can be probed, and passwords can be guessed. The goal was to shrink what's exposed, make it hard to get in, and keep it patched, without locking myself out.

## What I did

| Layer | What I changed | Proof it worked | Lesson |
|-------|----------------|-----------------|--------|
| Base system | Installed Ubuntu Server, applied updates, grew the root volume to use the whole 238 GB disk (LVM) | `df -h /` showed 232 GB; clean reboot | [04](04-install-ubuntu-server.md) |
| Authentication | Created an ed25519 SSH key with a passphrase, installed the public key, turned off password and root login | `sshd -T` showed the settings in effect; password and root attempts from WSL gave `Permission denied (publickey)`; key login still worked | [05](05-ssh-hardening.md) |
| Firewall | UFW with default deny incoming, default allow outgoing, SSH allowed | `ufw status` active; new SSH login worked through the firewall | [06](06-firewall-ufw.md) |
| Brute-force protection | fail2ban `sshd` jail: 5 failures in 10 minutes means a 1-hour ban, home network exempt | `fail2ban-client -t` passed; jail running after a reboot | [07](07-fail2ban.md) |
| Patching | Installed pending updates and a new kernel, confirmed automatic security updates are on, ran a dry run, rebooted | `uname -r` showed the new kernel; firewall and fail2ban came back by themselves | [08](08-updates.md) |
| Visibility | Read `auth.log` and the systemd journal to see logins, failures, and service starts | Found my own key logins, my own mistyped sudo password, and routine router traffic blocked by the firewall | [09](09-reading-logs.md) |
| Monitoring | Wrote a health-check script and scheduled it with cron every 5 minutes | New log lines every 5 minutes with no input from me | [10](10-services-and-cron.md) |

## Key configuration

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

## Rules I followed

- **Never remove a way in before the replacement is proven.** I confirmed key login worked before disabling passwords, and allowed SSH before enabling the firewall.
- **Test from a second terminal.** I kept one session open while testing a new login, so a mistake couldn't lock me out.
- **Validate before applying.** `sshd -t` and `fail2ban-client -t` check a config before a service uses it.
- **Reboot as a test.** A server should come back with SSH, firewall, and fail2ban running without help.
- **Check which machine the prompt belongs to.** Most of my mistakes were commands run on the wrong machine or typed without the command name.

## What I'd do next

- Back up the server's configuration files into this repo.
- Reserve a fixed IP address for the server in the router.
- Run the server's services (Jellyfin) in Docker, and add only the firewall rules each one needs.
- Set up backups and test a restore.

## Skills shown

Linux administration, SSH key authentication, firewall configuration (UFW), intrusion prevention (fail2ban), patch management, log analysis (journalctl, auth.log), service management (systemd), shell scripting, cron scheduling, LVM storage, and documentation.
