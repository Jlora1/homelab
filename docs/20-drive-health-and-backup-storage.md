# Lesson 20: Drive Health (SMART) and Backup Storage in Proxmox

**Date:** 2026-11-09
**Machine:** Dell OptiPlex 7040 Tower (Proxmox host `pve`)

## Goal

Find out which of my old loose drives I can trust, retire the bad ones, and turn the good ones into backup storage that Proxmox can use.

## Background

- **SMART** is a self-report built into every drive. Proxmox shows a simple **PASSED** or **FAILED**, and the full table of attributes underneath.
- **PASSED only means no attribute has crossed its built-in failure limit.** A drive can pass while it is already getting worse, so the attributes matter more.
- The attributes I watch:
  - **Reallocated_Sector_Ct:** bad spots the drive has already moved to spares.
  - **Current_Pending_Sector** and **Offline_Uncorrectable:** spots the drive can't read and hasn't been able to fix. Both should be **0**.
  - **UDMA_CRC_Error_Count:** errors on the cable, not the drive.
  - **Power_On_Hours:** age.
- **Backups follow the 3-2-1 rule:** 3 copies of anything important, on 2 kinds of storage, with 1 copy somewhere else. A backup on the same disk as the original doesn't count.

## What I Did

- Looked at the drives in **pve > Disks** and opened **Show S.M.A.R.T. values** for each one.
- Started a long self-test on the 4 TB drive from the Shell, and read the result the next day.
- Swapped the 4 TB drive out for another 1 TB drive, and checked that one too.
- Wiped the two good 1 TB drives with **Wipe Disk**, since I'd confirmed they held nothing I needed.
- Created a directory storage on each one under **Disks > Directory > Create: Directory**, with the ext4 filesystem.

```bash
# In the Proxmox web page: pve > Shell
smartctl -t long /dev/sda            # start the long self-test (it runs inside the drive)
smartctl -a /dev/sda | grep -E "Pending|Reallocated|Uncorrectable|# 1"   # read the result later
```

Results worth noting:

| Drive | Findings | Decision |
|-------|----------|----------|
| Samsung 256 GB SSD (Proxmox) | PASSED, wearout 14% | Keep. About 86% of its life is left. |
| WD 4 TB hard drive (about 33,000 hours) | PASSED, but **Current_Pending_Sector 158** and **Offline_Uncorrectable 158**. The long self-test ended with **Completed: read failure** about 10% of the way through. | **Retire.** Don't store anything on it. |
| Seagate 1 TB (about 49,000 hours, 5.6 years) | PASSED, all error counts **0** | Keep, as the second backup copy. |
| Replacement 1 TB (about 450 head hours) | PASSED, all error counts **0** | Keep, as the main backup disk. |

- On the 4 TB, **Reallocated_Sector_Ct was 0** even though 158 sectors were unreadable. The drive hadn't remapped them yet, so the reallocated count alone would have looked fine.
- The Seagate shows a huge **Raw_Read_Error_Rate** and **Seek_Error_Rate**. That is normal for Seagate drives, because their raw numbers don't mean what they do on other brands. The normalized value (100) was well above its limit.
- Two 1 TB drives had old Windows **BitLocker** partitions. I'd confirmed they held nothing I needed before I wiped them.
- A new directory storage in Proxmox 9.2 already allows the **Backup** content type. I didn't have to change that.
- After the swap, the replacement drive became **`/dev/sda`**. Device names are handed out at boot, so they can change when drives are added or removed. The **model and serial number** are what identify a drive.

## What Broke

- **PASSED looked fine while the 4 TB drive was failing.** I only caught it by reading the attribute table.
- **The 4 TB self-test needed hours.** The estimate was about 8 hours (489 minutes), so I started it in the evening and read the result the next day. I couldn't reboot the Tower while it was running.
- **Wiping is where a wrong click costs the most.** Nothing went wrong, but the rule I used was to check the model and size of the row before pressing **Wipe Disk**, and never to wipe `nvme0n1`, the SSD that holds Proxmox.

## How I Fixed It

- Took the 4 TB drive out, so it can't stall the system with unreadable sectors.
- Chose the backup roles by health: the healthiest drive is the main backup, the next one is the second copy.
- Used the Create: Directory dialog, which only lists unused disks, so the SSD could not be picked by mistake.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A SMART **PASSED** isn't a guarantee. Read the pending and uncorrectable sector counts.
- Pending sectors that don't clear and a self-test that ends in a read failure mean the drive is failing, even if it still mostly works.
- Raw SMART numbers mean different things on different brands. Compare the normalized value to its limit.
- Linux device names like `sda` can change after a hardware swap, so identify drives by model and serial.
- Before wiping anything, say out loud what's on the disk, and check the row you've selected.
- A backup disk should be a different disk from the data it protects, and a backup is only proven after a test restore.

## Not Done Yet

- No virtual machines exist yet, so there's nothing to back up. The next steps are a first VM, a scheduled backup job for it, and a **test restore**.
- A copy of the backups outside the Tower (another machine, a USB drive kept elsewhere, or encrypted cloud storage), to meet the "1 copy somewhere else" part of 3-2-1.
- Copy the EliteDesk's important files (the Jellyfin config and compose files) to `backup1`.
- Replace the retired 4 TB drive with a new or refurbished one that has a warranty, when I want more storage.

## Next

Build a first practice VM on the Tower, back it up to `backup1`, and restore it to prove the backup works.
