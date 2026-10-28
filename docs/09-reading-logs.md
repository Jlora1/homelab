# Lesson 09: Reading Logs

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Learn where Linux records what happened on the server (logins, failures, service starts, errors) and how to read it.

## What I Did

```bash
# Latest system messages
journalctl -n 20 --no-pager

# Successful logins and failed attempts in the auth log
sudo grep "Accepted" /var/log/auth.log | tail -5
sudo grep -Ei "failed|invalid|refused" /var/log/auth.log | tail -10

# Errors since the last boot
journalctl -p err -b --no-pager

# What a specific service has been doing
sudo journalctl -u ssh --since today --no-pager | tail -15
sudo journalctl -u fail2ban -n 10 --no-pager

# Follow a service live (Ctrl+C to stop)
sudo journalctl -u ssh -f
```

What the logs showed:
- **Successful logins:** `Accepted publickey for <server-user> from <my-pc-ip> ... ED25519`. My key logins are recorded with the time, the source address, and the key type.
- **Failed attempts:** `password check failed for user (<server-user>)`. This was just me mistyping my own sudo password. Even my typos are logged.
- **sudo is logged too:** each `sudo` command I ran appeared in `auth.log` with the directory and the full command. Even my `grep` searches showed up in the output I was searching.
- **Errors since boot:** only two. `SGX disabled or unsupported by BIOS` (a CPU feature I don't use) and `Bluetooth: hci0: Reading supported features failed` (the server has no Bluetooth use). Neither matters here, but now I know where to look.
- **Services across the reboot:** the SSH and fail2ban logs show them stopping cleanly at shutdown, then starting again after boot (`Server ready`). That confirms they recover on their own.
- **Firewall noise:** most of the recent log lines were `[UFW BLOCK]` entries for multicast traffic (destination `224.0.0.1`, protocol 2) from my router and two other devices on the home network. These are routine "who's listening?" messages from network devices. The firewall blocks them, which is correct, and they are harmless.

## What Broke

- **`last` was not found.** Ubuntu 26.04 doesn't install it by default. It suggested installing `wtmpdb`. The journal and `auth.log` already answer "who logged in?", so I skipped it.
- **Sudo password rejected once** (the `password check failed` line above), then accepted.

## What I Learned
- `journalctl` reads the system journal. `-u` picks one service, `-n` limits the number of lines, `-p err` shows only errors, `-b` limits to this boot, `--since` limits by time, and `-f` follows live.
- `/var/log/auth.log` records logins and sudo use. It's the first place to look for "who got in?" and "who tried?"
- Not every error line is a problem. Read the message, then decide if it affects anything I use.
- The firewall logs blocked traffic. Most of it on a home network is routine background noise, not an attack.
- Logs record sudo commands, so there's a trail of who did what.

## Next

systemd services, cron jobs, and bash scripts.
