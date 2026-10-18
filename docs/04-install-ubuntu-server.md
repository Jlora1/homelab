# Lesson 04: Install Ubuntu Server on the EliteDesk

**Date:** 2026-10-18
**Machine:** HP EliteDesk 800 G3 Mini (server), managed from a Windows PC over SSH

## Goal

Turn the EliteDesk into a real always-on Linux server: install Ubuntu Server, log in remotely over SSH, apply updates, and use the whole disk.

## What I Did

- Downloaded the Ubuntu Server 26.04.1 LTS ISO and wrote it to a USB stick on my Windows PC.
- Connected the EliteDesk to a monitor, keyboard, and wired network, booted it from the USB, and ran the installer. I set the server name (`goodmedia`), created my user, and enabled the OpenSSH server.
- Logged in at the server's own console first and checked who I was and what users existed.
- Connected from my other PC over SSH, applied updates, grew the root volume to fill the disk, rebooted, and reconnected.

```bash
# At the server console
whoami
ls /home

# From my other PC: connect over SSH
ssh <server-user>@<server-ip>

# Apply updates
sudo apt update
sudo apt upgrade

# Look at how the disk is laid out
lsblk
sudo lvs
df -h /

# Grow the root volume and its filesystem to use the whole disk
sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
df -h /

# Reboot and confirm it comes back
sudo reboot
ssh <server-user>@<server-ip>
```

Results worth noting:
- The disk is a 238.5 GB NVMe drive. The installer's default LVM setup made the root volume only **100 GB**, so `df -h /` showed 98 GB.
- After `lvextend`, `df -h /` showed **232 GB**. The resize happened while the system was running, with no downtime.
- After `apt upgrade`, a message said some services and sessions were still running older versions until a restart. A reboot cleared that, and the next login showed 0 pending updates.

## What Broke

- **Typed a device path as a command.** I entered `/dev/ubuntu-vg/ubuntu-lv` by itself and got "Permission denied." That path is a device file, not a program. It happened because a long command wrapped when pasted. Fix: paste long commands as one line and check the prompt before pressing Enter.
- **Mistyped my password once** on the first SSH attempt after the reboot, then got in on the second try.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A server needs no screen once it's set up: install it, then manage it over SSH from another machine.
- Storage on Ubuntu Server is layered: the disk is split into partitions, one partition holds LVM, which holds a logical volume, which holds the filesystem. `lsblk` shows the layers, `lvs` shows the logical volumes, and `df -h` shows what's actually usable.
- The installer's default LVM setup may not use the whole disk. `lvextend -r -l +100%FREE` grows the volume and the filesystem together, and it works on a mounted, running system.
- After updates, a reboot applies changes to services that are still running old versions. Rebooting and reconnecting is also a quick test that a server recovers on its own.
- "Connection reset by peer" and "Broken pipe" during a reboot are normal. The server dropped my session.

## Next

SSH hardening: key-only login, disabling root login, and other basic protections on the server.
