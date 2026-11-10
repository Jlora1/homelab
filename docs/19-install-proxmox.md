# Lesson 19: Installing Proxmox VE on the OptiPlex Tower

**Date:** 2026-11-08
**Machine:** Dell OptiPlex 7040 Tower (host name `pve`), managed from my Windows PC's browser

## Goal

Turn the Tower into a virtualization host with Proxmox VE, so I can run practice virtual machines and containers, and keep backups, without touching the always-on EliteDesk.

## Background

- **Proxmox VE** is a hypervisor: it runs on Debian Linux and lets one computer host many virtual machines (VMs) and containers, managed from a web page.
- An **ISO** is a disc image: a single file that holds the contents of an installer disc. It's not like WSL. WSL runs Linux inside Windows, while Proxmox replaces the operating system on the machine and then runs the VMs.
- The installer **erases the disk I pick**, so choosing the right one matters more than anything else in this lesson.
- Proxmox's web page lives on port **8006** over HTTPS and is only for my home network. It is not exposed to the internet.

## What I Did

- Downloaded the Proxmox VE 9.2 ISO for **x86-64** (Intel and AMD processors) and wrote it to a USB stick with Rufus, in **DD Image mode**, with a **GPT** partition scheme and **UEFI (non-CSM)** target.
- Booted the Tower from the stick with **F12**, chose `UEFI: General USB Flash Disk`, then **Install Proxmox VE (Graphical)**.
- Worked through the installer screens:
  - **Target harddisk:** the 256 GB Samsung SSD (`/dev/nvme0n1`), with the **ext4** filesystem. I picked ext4 over ZFS because the Tower has 16 GB of RAM and ZFS uses a lot of it.
  - **Location and time zone:** United States, America/New_York, U.S. keyboard.
  - **Password and email:** a strong root password, typed only into the installer.
  - **Network:** the wired port, with the address the router had just given the Tower, kept as its address. I reserved it in the router afterwards, so it never changes (see [lesson 21](21-new-ssh-key-and-locking-down-the-servers.md)).
  - **Summary:** checked the disk, filesystem, time zone and network, then installed.
- Took the USB stick out when it rebooted and opened `https://<tower-ip>:8006` from my PC. The browser warned about the certificate because Proxmox makes its own. I accepted it, since it's my own machine on my own network, and logged in as `root`.
- Fixed the update sources (see below), then updated everything from the web page's Shell, and rebooted for the new kernel.

```bash
# In the Proxmox web page: pve > Shell
apt update
apt dist-upgrade -y
uname -r          # after the reboot, shows the new kernel version
```

Results worth noting:
- After the repository fix, `apt update` reported 212 packages to upgrade, which is normal for a fresh install.
- After the reboot, `uname -r` showed `7.0.14-28-pve` instead of the older `7.0.2-6-pve` that came on the ISO.

## What Broke

- **I downloaded the wrong ISO.** The first file was the **ARM64** build, which is for ARM processors. The Tower has an Intel chip, so the screen stayed blank and the BIOS never listed a bootable stick. I only found out from the file name in a screenshot. I re-downloaded the x86-64 ISO and wrote the stick again.
- **The F12 menu didn't list the USB stick.** With the wrong ISO there was nothing to boot, and even after I rewrote the stick with the right one, the first F12 menu still showed no USB entry. I checked that it was plugged in, and after that the stick showed up as `UEFI: General USB Flash Disk`. I never pinned down exactly which step fixed it. <!-- TODO: note what I did differently -->
- **The installer's disk list started on the wrong drive.** The first screen of **Target harddisk** was set to the **4 TB WD hard drive**, and I almost clicked Next. Pressing the arrow keys cycles through the disks, and the only safe choice was the SSD. Check the model and size before every Next.
- **The time zone defaulted to `America/Adak`.** I caught it on the Summary screen, went back with Previous and set `America/New_York`.
- **`Update package database` failed with an error.** Proxmox's default update source is the paid enterprise one, and a free install can't use it.
- **The Refresh and Upgrade buttons didn't do anything for me.** I used `apt update` and `apt dist-upgrade -y` in the Shell instead, which worked.
- **After a drive swap and a power-off, the Tower stopped booting.** It showed `ALERT! /dev/mapper/pve-root does not exist. Dropping to a shell` at an `(initramfs)` prompt. The BIOS had gone back to its default of **SATA Operation: RAID On**, and in that mode Linux can't see the NVMe SSD. Proxmox was installed with **AHCI**.
- **A "CPU 0 fan failure" alert appeared at boot** after I had been working inside the case. It did not come back on the next start. <!-- TODO: add what I actually did to the fan cable -->

## How I Fixed It

- Got the right ISO (x86-64) and rewrote the stick.
- Disabled the two `enterprise` repositories and added the `pve-no-subscription` one under **pve > Updates > Repositories**. The yellow "not recommended for production use" warning that follows is normal for a home lab.
- Set **SATA Operation** back to **AHCI** in BIOS Setup (F2 > System Configuration > SATA Operation), applied it and exited. Proxmox booted normally.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- Check the CPU type before downloading an ISO. **x86-64** is Intel and AMD, **ARM64** is not.
- The installer wipes whichever disk is selected, so read the model name and size on that screen before clicking Next.
- Proxmox is the operating system on the machine, not a program inside Windows.
- A BIOS can reset its settings (for example when the power is unplugged for a while). The SATA mode has to match how the OS was installed, or Linux can't find its own disk.
- An error ending in `Dropping to a shell` with `(initramfs)` means Linux started but couldn't find the root disk. It's not a broken install.
- The free no-subscription repository is the right one for a home lab. The error from the enterprise repository is expected.
- Check which kernel is running with `uname -r`. A new kernel only runs after a reboot.

## Not Done Yet

- Intel virtualization turned out to be on (checked in lesson 21). Still to confirm: **AC Recovery** set to **Power On**, so the Tower restarts itself after a power outage.
- A UPS to protect the drives from power loss.

## Next

Check the health of the drives and set up backup storage ([lesson 20](20-drive-health-and-backup-storage.md)).
