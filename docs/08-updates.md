# Lesson 08: Updates and Automatic Security Patches

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Install pending updates, make sure security updates install automatically, and confirm the server recovers cleanly from a reboot with the firewall and fail2ban still running.

## What I Did

- Installed the waiting updates (22 packages upgraded, 8 installed, including a new kernel).
- Checked that automatic security updates were already enabled and did a dry run.
- Rebooted to load the new kernel, logged back in, and checked the kernel, firewall, and fail2ban.

```bash
sudo apt update
sudo apt upgrade
sudo apt autoremove

systemctl is-enabled unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
sudo unattended-upgrade --dry-run --debug 2>&1 | tail -15

sudo reboot
# after logging back in:
uname -r
sudo ufw status
sudo fail2ban-client status sshd
```

Results worth noting:
- Before the reboot, the server ran kernel 7.0.0-38 while 7.0.0-42 was installed. After the reboot, `uname -r` showed `7.0.0-42-generic`.
- `unattended-upgrades` was `enabled`, and `20auto-upgrades` had both settings set to `"1"` (refresh package lists daily, install security updates daily).
- The dry run ended with "No packages found that can be upgraded unattended", so nothing was left to patch and the tool ran without errors.
- After the reboot, the firewall was `active` with SSH allowed, and the fail2ban `sshd` jail was running. Both start on their own.
- `apt autoremove` removed nothing, even after the reboot. Ubuntu keeps the previous kernel as a fallback.

## What Broke

- **Typed `y` as a command.** `apt autoremove` had nothing to remove and no prompt, so the `y` ran as a command and gave "command not found." Read the screen before typing an answer.

## What I Learned
- Most attacks use bugs that already have fixes, so staying patched matters as much as the firewall.
- `unattended-upgrades` installs security updates automatically. The two lines in `20auto-upgrades` control it.
- A new kernel only takes effect after a reboot. `uname -r` shows which one is running.
- Rebooting is also a test: SSH, the firewall, and fail2ban all came back without help.
- A dry run (`--dry-run`) shows what would happen without changing anything.

## Next

Reading logs, then systemd services, cron jobs, and bash scripts.
