# Lesson 30: The Tower Won't Boot After Being Unplugged (BIOS Reset) (in progress)

**Date:** 2026-11-22
**Machine:** OptiPlex 7040 Tower (`pve`, Proxmox VE)

## Goal

Get Proxmox booting again after the Tower stopped at an emergency shell, and work out why it happened.

## Background

- Proxmox's own system lives on an **LVM volume** called `pve-root` on the boot SSD. Early in boot, a small temporary system (the **initramfs**) has to find that volume before Proxmox can start. If it can't, it gives up and drops to a **BusyBox `(initramfs)` shell**.
- Dell's **SATA Operation** BIOS setting controls how the board presents its drives. Linux needs **AHCI**. In **RAID On** mode, a drive can be hidden from Linux behind Intel's RAID driver.
- BIOS settings survive power-offs thanks to a small **CMOS coin battery** (CR2032) on the motherboard. If that battery is dead, unplugging the computer resets the BIOS to factory defaults, and a Dell OptiPlex's default is **RAID On**.

## What I Did

The Tower had been unplugged, which is why goodmedia's backups couldn't reach it (lesson 29). When I plugged it back in, it showed up on the switch, but nothing answered at `192.168.1.178`. On a monitor it showed:

```
Gave up waiting for root file system device.  Common problems:
 - Boot args (cat /proc/cmdline)
   - Check rootdelay= (did the system wait long enough?)
 - Missing modules (cat /proc/modules; ls /dev)
ALERT!  /dev/mapper/pve-root does not exist.  Dropping to a shell!
(initramfs)
```

**Checked which disks it could see**, at the `(initramfs)` prompt:

```
ls /dev/sd*
lvm vgscan
lvm vgchange -ay
ls /dev/mapper
```

- `ls /dev/sd*` showed only `/dev/sda /dev/sda1 /dev/sdb /dev/sdb1`: two disks with one partition each, which matches the two 1 TB backup drives.
- `lvm vgscan` found no volume groups at all.
- `/dev/mapper` held only `control`, with no `pve-root`.

So the **boot SSD had disappeared** after the bootloader had already loaded from it.

**Fixed the BIOS:** restarted, pressed **F2** at the Dell logo, went to **System Configuration → SATA Operation**, set it to **AHCI**, then **Apply → Exit**. Proxmox booted normally and answered pings again:

```bash
ping -c3 192.168.1.178    # 3 received, 0% packet loss
```

## What Broke

1. The first time, I typed the error message itself into the shell:

   ```
   sh: ALERT!: not found
   ```

2. The BIOS had lost its settings because the Tower had been **unplugged**, so SATA Operation was back on the factory default.

## How I Fixed It

1. `ALERT! ...` is the system's message, not a command. Typing real commands (`ls`, `lvm`) worked.
2. Set **SATA Operation → AHCI** again. The underlying cause, a BIOS that forgets its settings when unplugged, points to a **dead CMOS battery**.

**Still to do:**

- [ ] Replace the CMOS battery (CR2032). Then check that the BIOS keeps AHCI after being unplugged for a minute.
- [ ] Set the BIOS date and time, and check that **AC Recovery → Power On** (from lesson 26) is still set, since a reset clears it too.
- [ ] Until the battery is replaced, don't unplug the Tower. Shutting it down is fine.

## What I Learned

- `pve-root does not exist` means the boot disk or its LVM volume wasn't found. It isn't damage to Proxmox itself.
- In the initramfs shell, `ls /dev/sd*` and `lvm vgscan` show quickly whether a disk is missing or only its volume wasn't switched on.
- If unplugging resets the BIOS, the CMOS battery is dead. On a Dell, the reset defaults include RAID mode, which can hide the boot drive from Linux.
- Every BIOS setting I rely on (AHCI, AC Recovery) is lost when that happens, so they're worth writing down.
