# Lesson 06: Firewall with UFW

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`), managed from WSL

## Goal

Block all incoming network connections to the server except the ones I choose to allow. For now, that means SSH only.

## What I Did

- Set the default rules: deny everything incoming, allow everything outgoing.
- Added a rule allowing SSH **before** turning the firewall on, so I couldn't lock myself out.
- Checked the queued rule, enabled the firewall, and confirmed its status.
- Opened a second terminal and logged in over SSH to prove the firewall still lets me in.

```bash
sudo ufw status verbose              # starts inactive
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH               # allow SSH first
sudo ufw show added                  # confirm the rule is queued
sudo ufw enable                      # answer y at the prompt
sudo ufw status verbose

# From WSL, in a second window: confirm SSH still works
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip>
```

Results worth noting:
- `ufw show added` listed `ufw allow OpenSSH` before the firewall was enabled.
- After enabling, `status verbose` showed `Status: active`, `Default: deny (incoming), allow (outgoing)`, and `22/tcp (OpenSSH) ALLOW IN` for both IPv4 and IPv6.
- The rule typed as `Openssh` still worked. UFW ignores capitalization in profile names.
- The new SSH login through the firewall worked with my key passphrase.

## What Broke

- **Typo `sude`** instead of `sudo` gave "command not found." It also meant I skipped the "check the status first" step, which didn't matter because the firewall was off.
- **Sudo password rejected twice.** Nothing is displayed while typing a sudo password, so it's easy to mistype. The third try worked.
- **Typed the key file as a command.** I left off `ssh -i` and ran the key path by itself, so bash said "Permission denied." The key was not harmed. Fix: use the Up arrow to bring back an earlier command that worked.

## What I Learned
A firewall helps protect a server by blocking unwanted network connections. A good setup blocks everything by default and only allows the connections that are needed.
When setting up a firewall, allow SSH access before turning the firewall on. Otherwise, you could accidentally block your own remote connection.
Before closing your current SSH session, open a second terminal and make sure you can still log in. Keep the first session open until you've confirmed everything works.
UFW (Uncomplicated Firewall) manages firewall rules for both IPv4 and IPv6, so the same protection applies to both types of network traffic.

## Next

fail2ban, which temporarily bans IP addresses that keep failing to log in.
