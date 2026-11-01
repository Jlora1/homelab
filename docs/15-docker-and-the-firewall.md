# Lesson 15: Making Docker Respect the Firewall

**Date:** 2026-11-01
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Docker opens the ports of the containers it runs by adding its own firewall rules, and those rules are checked *before* UFW's. That means UFW doesn't protect Docker's published ports. I wanted to prove the problem, fix it for Jellyfin's port (8096), and make the fix survive reboots.

## The Problem, Proven

On the server, UFW's status showed `deny (incoming)` with only SSH allowed and no rule for 8096. But Docker's own chain had a rule that accepted TCP port 8096 for the Jellyfin container, and Jellyfin was reachable from every device on my home network:

```bash
sudo ufw status verbose
sudo iptables -L DOCKER-USER -n -v --line-numbers    # empty: Docker leaves this chain for my own rules
sudo iptables -L DOCKER -n -v                         # shows "ACCEPT tcp ... dpt:8096"
```

## What I Did

**1. A test rule in `DOCKER-USER`.** Docker checks this chain before its own rules, so a rule here wins. I allowed only my PC and dropped everyone else:

```bash
sudo iptables -I DOCKER-USER -i eno1 -p tcp -m conntrack --ctorigdstport 8096 --ctdir ORIGINAL ! -s <my-pc-ip> -j DROP
```

- `-i eno1` means traffic coming in through the server's network port.
- `--ctorigdstport 8096` matches the *original* destination port. By the time Docker's chain sees the packet, the address has already been rewritten to the container's, so matching the original port with the connection-tracking module is what works.
- `! -s <my-pc-ip>` means "unless it comes from my PC".

My PC still loaded Jellyfin. After my phone tried to reach it, the rule's counter showed **10 packets (640 bytes) dropped**, proving the rule caught the traffic.

**2. The permanent rule.** I removed the test rule (`sudo iptables -D DOCKER-USER 1`) and wrote a script that drops traffic to port 8096 from outside my home network. My phone, TV, and other home devices need access, so the whole home network is allowed. It checks first (`iptables -C`) and only adds the rule if it's missing, so running it twice never creates duplicates:

- [`configs/docker-firewall/docker-firewall.sh`](../configs/docker-firewall/docker-firewall.sh), installed as `/usr/local/sbin/docker-firewall.sh`

**3. A systemd service** that runs the script after Docker starts at every boot (the rules in iptables are lost on reboot):

- [`configs/docker-firewall/docker-firewall.service`](../configs/docker-firewall/docker-firewall.service), installed in `/etc/systemd/system/`

```bash
sudo chmod 755 /usr/local/sbin/docker-firewall.sh
sudo systemctl daemon-reload
sudo systemctl enable --now docker-firewall.service
```

Results worth noting:
- With the permanent rule loaded, both my PC and my phone (on home Wi-Fi) still reached Jellyfin.
- After a reboot (`uptime -p` showed `up 1 minute`), both `docker` and `docker-firewall.service` were `active`, and the `DOCKER-USER` chain contained the rule again.
- The rule is also a safety net. If port 8096 were ever forwarded on my router by mistake, traffic from the internet would be dropped here.

## Limits (What This Doesn't Cover)

- It protects **port 8096 only.** Each new container port I publish needs its own rule, or I should bind it to a specific address in the compose file.
- I tested blocking with a device on my home network (my phone, with the test rule). I couldn't test from an outside address, so the final version's drop path rests on the same mechanism with a wider allowed range.
- I haven't checked IPv6 for Docker's ports. UFW's IPv6 rules apply to the Docker proxy listener, but I haven't tested it.
- Other approaches exist (for example, writing rules in UFW's `after.rules` so `ufw route` can manage Docker traffic). I chose `DOCKER-USER` because it's simple and easy to see.

## What Broke

- **Pasted old output again.** The first part of one of my pastes was the previous outputs, so I couldn't tell which result was new. Run one step at a time and paste only the new output.
- **Ran an `ssh` command from inside the server.** The prompt was `<server-user>@goodmedia`, so it tried to log in to the server from itself, and the key file only exists on WSL, which gave "Identity file not accessible". The prompt gave it away again. I answered `no` to the fingerprint question and restarted the server directly.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- Docker's published ports bypass UFW because Docker's rules are checked first. A rule in the `DOCKER-USER` chain is the supported place to filter them.
- By the time packets reach Docker's chain, their destination has been rewritten. Matching the original port (`--ctorigdstport`) avoids that problem.
- Firewall rules in iptables disappear at reboot, so they need a service that restores them.
- `iptables -C` checks whether a rule exists, which makes a script safe to run twice.
- A packet counter is real evidence that a rule caught traffic.
- Test with a rule that proves the point, then widen it to what I actually want.

## Next

Install Tailscale on the server for remote access, without opening any ports on the router.
