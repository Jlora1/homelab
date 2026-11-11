# Lesson 22: My First Virtual Machine, a Backup, and a Test Restore

**Date:** 2026-11-10
**Machine:** Dell OptiPlex 7040 Tower (Proxmox host `pve`), managed from my Windows PC's browser

## Goal

Build a practice virtual machine (VM) on the Tower, back it up to `backup1`, and restore the backup as a second VM to prove the backup really works.

## Background

- A **VM** is a whole computer simulated in software. Proxmox gives it a virtual CPU, memory, disk and network card, and I install an operating system on it like on a real machine.
- An **ISO** is the installer disc as one file. Proxmox keeps ISOs in storage named `local`, and a VM's virtual CD drive reads from them.
- A **backup** is only proven by a **test restore**. Until I've brought one back, I don't know it's usable.
- **Snapshot mode** backs up a running VM without stopping it. **ZSTD** is a fast compression format.
- The **QEMU guest agent** is a small program inside the VM that lets Proxmox see its IP address and shut it down cleanly.
- Restoring a backup under a new **VM ID** makes a separate copy and leaves the original alone.

## What I Did

- Opened **local (pve) > ISO Images > Download from URL** and downloaded the Ubuntu Server 26.04.1 ISO (about 2.9 GB) straight onto the Tower. It's the same release as my EliteDesk.
- Created the VM with **Create VM**, using these settings:

| Setting | Value |
|---------|-------|
| VM ID and name | 100, `practice-ubuntu` |
| OS | the Ubuntu ISO, type Linux |
| System | defaults, with **Qemu Agent** ticked |
| Disk | `local-lvm`, 20 GiB |
| CPU and memory | 2 cores, 2048 MiB |
| Network | bridge `vmbr0`, VirtIO |

- Started it, opened the **Console**, and ran the Ubuntu Server installer: the guided storage layout on the whole virtual disk with no encryption, my name and the server name, and **Install OpenSSH server**. <!-- TODO: note whether the GitHub key import worked, and whether I turned off password logins -->
- Took out the virtual CD (**Hardware > CD/DVD Drive > Do not use any media**), restarted the VM, logged in at the console, and found its address with `ip -br addr`.
- Installed the guest agent inside the VM and started it:

```bash
sudo apt update && sudo apt install -y qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

- Backed up the VM: **VM 100 > Backup > Backup now**, with storage `backup1`, mode **Snapshot** and compression **ZSTD**.
- Restored it as a copy: **backup1 > Backups**, selected the file, **Restore**, with VM ID **101**, **Unique** ticked and **Start after restore** unticked.
- Compared the two VMs' network cards, started 101, logged in at its console and checked its address.

Results worth noting:
- The download of the 2.9 GB ISO took about 32 seconds, at roughly 88 MB/s.
- After the guest agent started, the VM's **Summary** page showed its IP address, `192.168.1.200`, where it had said "Guest Agent not running."
- The backup file was `vzdump-qemu-100-2026_11_10-18_02_16`, format `vma.zst`, **3.16 GiB**, for a VM with a 20 GiB disk. The backup task took about 35 seconds.
- The restore took about 40 seconds.
- The restored VM 101 has its own disk (`vm-101-disk-0`, 20 GiB) and a different MAC address (`BC:24:11:1A:8D:53`, against `BC:24:11:78:4D:5B` for VM 100), because I ticked **Unique**.
- VM 101 booted and let me log in. Its address was `192.168.1.201`, against `192.168.1.200` for the original.

## What Broke

- **The file name had a stray character.** In the Download from URL box, the file name began with a `(`. I deleted it, ran **Query URL**, and checked that the size appeared before clicking Download.
- **The console was black after the installer.** After the install, the console showed only a cursor. I checked **Options > Boot Order** (the disk `scsi0` was first and the CD drive was empty), then used **Reset** and opened the console again, and it booted to a login prompt. <!-- TODO: note what I think fixed it -->
- **I looked at the wrong VM.** To check the restored copy's MAC address, I first had the original VM 100 selected. The header at the top of the page says which VM I'm looking at.
- **The schedule briefly became hourly.** When I edited the job, the Schedule box kept only a `2` from what I typed, and Proxmox reads that as minute 2 of every hour (Next Run said 19:02). I cleared the box, picked `02:30` from the dropdown, and checked that Next Run showed tomorrow at 02:30.
- **I mistyped my username.** I typed `lzmua` in place of `lzmula`. A failed login just needs a retry.
- **The root partition looks small.** The installer's default LVM layout used about half of the 20 GiB disk for `/` (the login message said about 9.75 GB). That's fine for practice.

## How I Fixed It

- Picked the schedule from the dropdown instead of typing it, then checked Next Run.
- Retyped the file name and ran Query URL before downloading.
- Checked the boot order and the CD drive before resetting the VM.
- Ticked **Unique** when restoring, so the copy didn't share a MAC address with the original.
- Restored to a new VM ID (101) so the original VM 100 was never at risk.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A backup isn't proven until I've restored it. The restore worked in under a minute, and the copy booted and let me in.
- Restoring to a new VM ID makes a safe copy. Restoring over the same ID replaces the original.
- A restored copy needs a new MAC address (the **Unique** option), or two VMs on the same network can clash.
- The guest agent lets Proxmox show a VM's IP address and shut it down cleanly.
- A VM's disk is a file-like volume on the host, so a 20 GiB disk with little on it compresses to a few GiB.
- Check which VM is selected before reading its settings or changing them.

## Not Done Yet

- ~~Put the backup on a schedule.~~ Done: a job in **Datacenter > Backup** backs up VM 100 to `backup1` at `02:30` every day, Snapshot mode, ZSTD, keeping the last 3. I tested it with **Run now**, and `backup1 > Backups` then showed two files for VM 100 (18:02 and 18:52, about 3.16 and 3.17 GiB).
- Make a copy of the backups outside the Tower, to meet the "1 copy somewhere else" part of 3-2-1.
- Copy the EliteDesk's Jellyfin config and compose files to `backup1`.
- Delete the test VM 101 when I no longer need it, so it stops using space.
- Install the 51 waiting updates inside the VM.
- Reserve an address for the VM in the router, if I keep it.

## Next

Back up the EliteDesk's important files to the Tower. After that comes networking, the managed switch and the ad blocker (see `PLAN.md`).
