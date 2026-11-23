#!/bin/bash
# Copies the UniFi controller's backups (manual and weekly auto backups)
# from the EliteDesk to the Tower. Installed as /usr/local/bin/backup-unifi.sh
# and run from root's crontab at 15 8 * * * (3:15 AM local; the server runs on UTC).
LOG=/var/log/backup-unifi.log
echo "=== $(date '+%F %T') start" >> "$LOG"
rsync -rlpt -e "ssh -i /home/lzmula/.ssh/id_backup -o BatchMode=yes" \
  /srv/unifi/config/data/backup/ \
  goodbackup@192.168.1.178:/mnt/pve/backup1/goodmedia/unifi-backups/ >> "$LOG" 2>&1
rc=$?
echo "=== $(date '+%F %T') finished, exit code $rc" >> "$LOG"
exit $rc
