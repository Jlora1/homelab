# Lesson 29: Switch Tour and Backing Up the UniFi Controller

**Date:** 2026-11-22
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`, UniFi controller in Docker), USW-Flex-2.5G-8 switch (`sw-office`), OptiPlex 7040 Tower (`pve`, backup storage)

## Goal

Get to know the new switch's page in the controller, name it, turn on the controller's backups, and copy those backups to the Tower every night, like the Jellyfin backup in lesson 23.

## Background

- With UniFi, the switch's settings live in the **controller**, not on the switch. Backing up the controller backs up the switch's config.
- The controller saves backups as **`.unf`** files. They're encrypted and can only be restored through the controller (Settings → Backups → Restore), not opened in an editor.
- The container's `/config` folder is `/srv/unifi/config` on `goodmedia`, so its backups are in `/srv/unifi/config/data/backup/`. The weekly ones go in the `autobackup` folder inside it.
- `echo '...' | sudo crontab -` **replaces** the whole crontab. To add a job without deleting the others, save the current crontab to a file, add the line, and load the file back in.

## What I Did

**Toured the switch's Ports page** (UniFi Devices → the switch → Ports):

- Port 9 (10 GbE copper) is the **uplink** to the router, linked at **2.5 GbE**.
- Ports 1–8 are 2.5 GbE, and port 10 is an SFP+ cage.
- Every port's **Native VLAN** is **Default**: one flat network for now.
- **STP: Participant** on every port, so Spanning Tree blocks loops.
- **PoE: None.** This switch can be powered by PoE but doesn't supply it.
- Switch firmware **2.1.8**, UniFi Network **10.6.109**.

**Renamed the switch** to `sw-office` in its settings.

**Turned on backups:** Settings → System → Backups → **Auto Backup: Weekly**, and clicked **Download** to save a first backup to my PC (`network_backup_11.22.2026_06-08-PM_v10.6.109.unf`).

**Found where the container keeps them** on `goodmedia`:

```bash
sudo docker inspect unifi-network-application --format '{{range .Mounts}}{{.Source}}{{"\n"}}{{end}}'
sudo find $(sudo docker inspect unifi-network-application --format '{{range .Mounts}}{{.Source}} {{end}}') \( -name '*.unf' -o -type d -name 'autobackup' \) 2>/dev/null
```

```
/srv/unifi/config
/srv/unifi/config/data/backup/10.6.109.unf
/srv/unifi/config/data/backup/autobackup
```

**Wrote a backup script**, `/usr/local/bin/backup-unifi.sh` (copy in [`scripts/backup-unifi.sh`](../scripts/backup-unifi.sh)). It uses the same backup-only SSH key and log format as the Jellyfin one:

```bash
rsync -rlpt -e "ssh -i /home/lzmula/.ssh/id_backup -o BatchMode=yes" \
  /srv/unifi/config/data/backup/ \
  goodbackup@192.168.1.178:/mnt/pve/backup1/goodmedia/unifi-backups/
```

**Tested it** (once the Tower was back up, see lesson 30):

```bash
sudo /usr/local/bin/backup-unifi.sh; echo "exit $?"
ssh -i ~/.ssh/id_backup goodbackup@192.168.1.178 'ls -la /mnt/pve/backup1/goodmedia/unifi-backups'
```

It printed `exit 0`, and the Tower listed `10.6.109.unf`, `meta.json` and the `autobackup` folder.

**Scheduled it** next to the Jellyfin job, without replacing the crontab:

```bash
sudo crontab -l > /tmp/rootcron
echo '15 8 * * * /usr/local/bin/backup-unifi.sh' >> /tmp/rootcron
sudo crontab /tmp/rootcron && sudo crontab -l
```

```
0 8 * * * /usr/local/bin/backup-jellyfin.sh
15 8 * * * /usr/local/bin/backup-unifi.sh
```

`15 8` UTC is 3:15 AM my time, just after the Jellyfin backup. I also ran the Jellyfin backup by hand to check it still worked: `exit 0`.

## What Broke

1. Windows asked which app should open the downloaded `.unf` file.
2. The first test run failed:

   ```
   rsync: connection unexpectedly closed (0 bytes received so far) [sender]
   ssh: connect to host 192.168.1.178 port 22: No route to host
   exit 255
   ```

3. With the Tower plugged into the switch, its port (port 1) shows **FE**: Fast Ethernet, 100 Mbps, instead of 1 GbE.

## How I Fixed It

1. Nothing opens a `.unf` file. It's only for restoring in a controller, so I closed the box and kept the file.
2. "No route to host" on my own network means nothing answered at that address. The Tower was unplugged. Plugging it back in led to the boot problem in lesson 30. Once it was running again, the script worked.
3. Not fixed yet. A link stuck at 100 Mbps usually means a damaged or old cable (gigabit needs all four wire pairs). Next step: try a different cable, then another port.

## What I Learned

- On UniFi, backing up the controller is backing up the switch.
- `docker inspect` shows which folder on the host a container's data really lives in.
- `crontab -` replaces the whole crontab. To add a job, save the crontab to a file, append the line, and load the file back.
- A backup script that has never run successfully isn't a backup. Testing it is what showed the Tower was missing.
- The port page shows link speed, which is a quick way to spot a bad cable.
