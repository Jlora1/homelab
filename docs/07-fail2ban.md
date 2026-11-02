# Lesson 07: fail2ban

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Automatically ban any IP address that fails to log in over SSH too many times.

## What I Did

- Installed fail2ban.
- Created my own settings file, `/etc/fail2ban/jail.local`, instead of editing `jail.conf`, which package updates can overwrite.
- Tested the config, restarted the service, and checked the `sshd` jail.

```bash
sudo apt install fail2ban
sudo nano /etc/fail2ban/jail.local
sudo fail2ban-client -t              # test the config
sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

Contents of `jail.local`:

```
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24

[sshd]
enabled = true
```

What the settings mean: 5 failed logins within 10 minutes means a 1-hour ban. `ignoreip` exempts localhost and my home network (192.168.1.x) so I can't ban myself.

Results worth noting:
- `fail2ban-client -t` printed `OK: configuration test is successful`.
- `status sshd` showed the jail running, reading the SSH log (`_SYSTEMD_UNIT=ssh.service`), with 0 failed and 0 banned.
- Password login is already disabled, so fail2ban is an extra layer. It adds protection against repeated attempts and reduces log noise.

## What Broke

- Nothing broke. I did open `nano` twice, because the first time I didn't paste the settings in. Checking the file's contents before saving avoids that.

## What I Learned
- fail2ban reads log files and adds firewall bans for IPs that keep failing.
- Put custom settings in `jail.local`, not `jail.conf`.
- `ignoreip` prevents locking myself out from my own network.
- Test the config (`-t`) before restarting a service.

## Update (Lesson 17): Ignoring My Tailnet

After adding Tailscale (lesson 16) I log in from the `100.` tailnet addresses as well as from the home network, so failed logins over Tailscale would count toward a ban. I added the tailnet range to the ignore list.

```bash
# On the server: change the ignoreip line, test, restart, and check
sudo sed -i 's|^ignoreip = .*|ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 100.64.0.0/10|' /etc/fail2ban/jail.local
sudo head -12 /etc/fail2ban/jail.local
sudo fail2ban-client -t && sudo systemctl restart fail2ban
sudo systemctl is-active fail2ban
sudo fail2ban-client get sshd ignoreip
```

- `100.64.0.0/10` is the range Tailscale uses for device addresses.
- The check listed `127.0.0.0/8`, `192.168.1.0/24`, `100.64.0.0/10` and `::1`.
- What broke: a stray `x` got typed at the start of `jail.local`, so the config test failed with "File contains no section headers." Because the commands were joined with `&&`, the restart never ran and fail2ban kept running with its old, working settings. I fixed it with `sed` and checked the top of the file with `head`.
- Right after a restart, `fail2ban-client` printed "Failed to access socket path... Is fail2ban running?" because the service needs a second to start. Running `systemctl is-active fail2ban` and trying again worked.
- Lesson: chain test and restart with `&&` so a bad config never gets applied, and look at the file after editing it.

## Next

Updates: install what's waiting and confirm automatic security updates are on.
