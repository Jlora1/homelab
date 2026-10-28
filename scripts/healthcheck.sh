#!/usr/bin/env bash
# healthcheck.sh - appends a one-line server status to a log file
# Runs from cron every 5 minutes on the server (see docs/10-services-and-cron.md).
LOG="$HOME/healthcheck.log"
echo "$(date '+%F %T') | $(uptime -p) | disk $(df -h / | awk 'NR==2{print $5}') | mem $(free -m | awk '/Mem:/{printf "%d%%", $3*100/$2}') | ssh $(systemctl is-active ssh) | ufw $(systemctl is-active ufw) | fail2ban $(systemctl is-active fail2ban)" >> "$LOG"
