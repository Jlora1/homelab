# Lesson 27: Restoring Jellyfin From the Backup (Restore Drill)

**Date:** 2026-11-12
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`, the Jellyfin server) restoring from the OptiPlex 7040 Tower (`pve`)

## Goal

Prove that the nightly backup from lesson 23 can bring Jellyfin back, not just that the files are intact. Stop Jellyfin, put the backed-up config in place, start it, and check that it works.

## Background

- A backup isn't proven until it has been **restored**. In lesson 23 I showed the files came back identical (`diff`). This time I started Jellyfin from the restored files.
- Jellyfin's settings, users and library data live in its **config folder** (`/srv/jellyfin/config`). The media files are separate and weren't touched.
- I **moved the current config aside instead of deleting it**, so I could undo the restore if it went wrong.
- Files copied back by `root` belong to `root`. The container runs as user `1000:1000`, so the restored files have to be given back to that owner, or Jellyfin can't write to them.
- A restore puts things back **as they were at the last backup**. Anything that changed after the 3 AM copy, such as login sessions, is gone.

## What I Did

**Before (nothing stopped):** I opened Jellyfin and noted the **Movies** library and the **Continue Watching** row. Then I compared the live config with the backup:

```bash
sudo docker ps --format '{{.Names}}: {{.Status}}'
sudo du -sh /srv/jellyfin/config
ssh -i ~/.ssh/id_backup goodbackup@192.168.1.178 'du -sh /mnt/pve/backup1/goodmedia/config; ls -la --time-style=long-iso /mnt/pve/backup1/goodmedia/'
```

The live config was 6.8 MB and the backup was 6.7 MB. The small difference is Jellyfin writing small changes after the 3 AM copy.

**Stop Jellyfin, save the owner, move the config aside:**

```bash
cd ~/jellyfin
OWNER=$(sudo stat -c '%u:%g' /srv/jellyfin/config); echo "owner is $OWNER"
sudo docker compose stop
sudo mv /srv/jellyfin/config /srv/jellyfin/config.before-restore
sudo ls /srv/jellyfin
```

The owner was `1000:1000`, and the folder listing showed `cache` and `config.before-restore`, with no plain `config`.

**Restore from the Tower and fix the owner:**

```bash
sudo rsync -rlpt -e "ssh -i /home/lzmula/.ssh/id_backup -o BatchMode=yes" goodbackup@192.168.1.178:/mnt/pve/backup1/goodmedia/config /srv/jellyfin/
sudo chown -R "$OWNER" /srv/jellyfin/config
sudo du -sh /srv/jellyfin/config
sudo ls -ln /srv/jellyfin/config | head
```

The restored config was **6.7 MB**, every entry was owned by `1000 1000`, and the files kept their original dates (the `data` folder was dated 07:04 that morning, from the 3 AM backup).

**Start Jellyfin and check it:**

```bash
sudo docker compose start
sleep 40
sudo docker ps --format '{{.Names}}: {{.Status}}'
sudo docker logs --tail 15 jellyfin
```

Results:
- Jellyfin showed `Up ... (healthy)`, and the startup lines had no `permission denied` or `database is locked` errors.
- The log showed `Invalid token` errors for my browser. My browser had logged in **after** the 3 AM backup, so the restored database didn't know that session. That is expected, and it shows the old state was really put back.
- After a full reload (Ctrl+F5), the browser **asked me to log in**. My account worked, so the user accounts came back.
- The **Movies** library showed both movies (Big Buck Bunny and Transfer Test), and I played one without problems.
- Jellyfin was down for about 5 minutes in total.

## What Broke

Nothing broke. Two small things happened:

- I pasted several commands at once and the pause (`sleep 40`) made the window look stuck, so I pressed Ctrl+C and ran the commands again. It was harmless.
- The `Invalid token` lines in the log looked alarming at first. They only meant my browser's login was newer than the backup.

## How I Fixed It

There was nothing to fix. I checked each result before moving to the next step (size, owner, health, logs, then the web page).

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A backup is proven only after the service starts from it. Matching files isn't the same thing.
- Move the current data aside instead of deleting it, so the restore can be undone.
- Save the original owner before changing anything, and give it back to the restored files.
- A restore returns the state as of the last backup. Things that happened after it, such as new login sessions, are lost.
- Read the logs before panicking. `Invalid token` after a restore is normal.
- Check each step's result before starting the next one.

## Not Done Yet

- Delete `/srv/jellyfin/config.before-restore` after a few days, once I'm sure Jellyfin is fine. It holds a copy of my settings, so it shouldn't stay around.
- I only restored the **config folder**. I haven't tested restoring the **compose file**, or rebuilding the whole server on a new machine from the backups.
- Back up the **media** drive, or decide what's replaceable, and add a **third copy** off the Tower (3-2-1).
- Buy a UPS, so a power cut doesn't hard-stop the machines.
- Install the 51 updates in the practice VM, or delete the VM, and delete the test VM 101.

## Next

Switch basics when the managed switch arrives on the 17th, then the Protectli router. See `PLAN.md`.
