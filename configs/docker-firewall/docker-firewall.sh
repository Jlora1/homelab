#!/usr/bin/env bash
# Allow the Docker-published Jellyfin port (8096) only from the home network.
# Installed on the server as /usr/local/sbin/docker-firewall.sh (chmod 755).
# Edit the interface (eno1) and network (192.168.1.0/24) to match your setup.
# See docs/15-docker-and-the-firewall.md
set -euo pipefail
RULE=(-i eno1 -p tcp -m conntrack --ctorigdstport 8096 --ctdir ORIGINAL ! -s 192.168.1.0/24 -j DROP)
iptables -C DOCKER-USER "${RULE[@]}" 2>/dev/null || iptables -I DOCKER-USER "${RULE[@]}"
