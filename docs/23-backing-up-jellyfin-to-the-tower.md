# Lesson 23: Backing Up the EliteDesk's Jellyfin Settings to the Tower

**Date:** 2026-11-11
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`, the Jellyfin server) copying to the OptiPlex 7040 Tower (`pve`)

## Goal

Make a second copy of Jellyfin's settings and its compose file on a different machine, so a dead drive or a bad update on the EliteDesk doesn't mean rebuilding everything by hand.

## Background

- **`rsync`** copies files and skips anything that hasn't changed, so repeat runs are fast. It can copy over SSH.
- A **dedicated backup user** (here `goodbackup`) can only write to one folder. That's safer than letting one machine log into another as `root`.
- A **backup-only SSH key** has no passphrase so a scheduled job can use it. It's safe because it can only log in as that one low-privilege user, and only from one address.
- **What to back up:** Jellyfin's config folder holds settings, users and library data. The cache folder is rebuilt automatically, and the media folder is huge and is a separate job.
- This is the "2 copies on different machines" part of the **3-2-1 rule**. A third copy somewhere off the Tower is still to do.

## What I Did

Found what Jellyfin uses on the EliteDesk (`sudo` was needed for Docker):

```bash
sudo docker ps --format '{{.Names}}'
sudo docker inspect jellyfin --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}'
sudo docker inspect jellyfin --format '{{index .Config.Labels "com.docker.compose.project.config_files"}}'
sudo du -sh /srv/jellyfin/config
```

| What | Where on the EliteDesk | Back up? |
|------|------------------------|----------|
| Settings, users, library data | `/srv/jellyfin/config` (6.7 MB) | Yes |
| Compose file | `/home/lzmula/jellyfin/docker-compose.yml` | Yes |
| Cache | `/srv/jellyfin/cache` | No, it rebuilds |
| Media | `/srv/media` | Separate job |

On the Tower (`backup1` is at `/mnt/pve/backup1`, 860 GB free), as `root`:

```bash
adduser --disabled-password --gecos "" goodbackup
mkdir -p /mnt/pve/backup1/goodmedia
chown goodbackup:goodbackup /mnt/pve/backup1/goodmedia
```

On the EliteDesk, made a key used only for backups:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_backup -N "" -C "goodmedia-backup"
cat ~/.ssh/id_backup.pub
```

On the Tower, installed the **public** key for `goodbackup`, allowed only from the EliteDesk's address:

```bash
install -d -m 700 -o goodbackup -g goodbackup /home/goodbackup/.ssh
echo 'from="192.168.1.187" ssh-ed25519 AAAA...(public key)... goodmedia-backup' > /home/goodbackup/.ssh/authorized_keys
chown goodbackup:goodbackup /home/goodbackup/.ssh/authorized_keys
chmod 600 /home/goodbackup/.ssh/authorized_keys
```

Tested the login from the EliteDesk, then ran the first copy:

```bash
ssh -i ~/.ssh/id_backup goodbackup@192.168.1.178 'hostname; ls -ld /mnt/pve/backup1/goodmedia'

sudo rsync -rlptv -e "ssh -i /home/lzmula/.ssh/id_backup -o StrictHostKeyChecking=accept-new" \
  /srv/jellyfin/config /home/lzmula/jellyfin/docker-compose.yml \
  goodbackup@192.168.1.178:/mnt/pve/backup1/goodmedia/
```

Checked on the Tower:

```bash
ls -la /mnt/pve/backup1/goodmedia
du -sh /mnt/pve/backup1/goodmedia/config
```

Results:
- The login worked with no password and printed `pve`.
- The copy sent about 6.6 MB (6,636,348 bytes) in well under a second.
- On the Tower, `config` was 6.7 MB, the same as the original, and `docker-compose.yml` was 417 bytes. Both are owned by `goodbackup`, and the files kept their original dates.

## What Broke

- **I ran the key-making command on the wrong machine.** The first `ssh-keygen` ran in the Tower window, so the private key was on the Tower, not the EliteDesk. I made a new key on the EliteDesk, replaced the public key in `authorized_keys` on the Tower, and deleted the stray pair from `/root/.ssh`.
- **I ran Tower commands in the EliteDesk window (twice).** They failed harmlessly with `No such file or directory` and `invalid user`. I now read the prompt before pressing Enter: `lzmula@goodmedia` is the EliteDesk and `root@pve` is the Tower.
- **The username `backup` already existed.** Debian has a built-in system account with that name, so I made `goodbackup` instead.
- **Docker said `permission denied`.** My user isn't in the `docker` group, so Docker commands need `sudo`. I mistyped my password twice before it worked.
- **A typo in a file name** (`authorized_key` without the `s`) made `chown` fail. I re-ran the commands with the right name.

## How I Fixed It

- Made the key on the EliteDesk and swapped the public key on the Tower.
- Used a different user name, and `sudo` for Docker and for reading the config folder.
- Checked the prompt for the machine name before each command.
- Verified the result on the Tower with `ls` and `du`, not just by trusting the copy's output.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A backup on the same machine isn't enough. This one lives on a different computer.
- A dedicated low-privilege user and a key limited to one address means a problem on one machine can't spread to the other.
- Only back up what you can't rebuild. Settings are small. The cache rebuilds, and media is a separate job.
- `rsync` skips what hasn't changed, so repeat runs are fast.
- Always verify the copy on the destination machine.
- Always check which machine a terminal window is connected to before running a command.

## Not Done Yet

- Run this copy **automatically** every night (a `cron` job on the EliteDesk) instead of by hand.
- **Test a restore** of the Jellyfin config (for example into a throwaway folder or container) to prove it's usable.
- Back up the **media** drive, or decide what's replaceable.
- A **third copy** somewhere off the Tower (3-2-1).
- Install the **28 updates** waiting on the EliteDesk (20 are security updates).
- Restoring from this copy may need `chown` to give the files back to the right owner, because the copy is owned by `goodbackup`.
- Delete the test VM 101 on the Tower when I no longer need it.

## Next

Put the copy on a nightly schedule, then test a restore. After that comes networking, the managed switch and the ad blocker (see `PLAN.md`).
