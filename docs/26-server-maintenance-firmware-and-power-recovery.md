# Lesson 26: Server Maintenance, a Firmware Update, and Power Recovery

**Date:** 2026-11-12
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`) and the OptiPlex 7040 Tower (`pve`)

## Goal

Check that the first scheduled backup ran, finish the loose ends from the last update (old kernel, held-back packages, automatic updates, a firmware notice), update the Tower, and set the Tower to turn itself back on after a power cut.

## Background

- A **cron job** only counts as working once it has run by itself. The log is how I check.
- `autoremove` is an option of `apt` (`sudo apt autoremove`), not a command of its own. It removes packages that were installed only to support others and aren't needed now, such as old kernels.
- **Phased updates:** Ubuntu releases some updates to a small share of machines first and widens it over a few days. `apt` says "Not upgrading yet due to phasing" and holds them back. Nothing is wrong.
- **unattended-upgrades** installs security updates by itself. It does **not** reboot by default, so a new kernel only runs after I reboot.
- **fwupd** (`fwupdmgr`) installs firmware updates on Linux. The **UEFI dbx** is the Secure Boot blocklist of known-bad bootloaders. Updating it is a small data change, not a BIOS flash.
- **AC Recovery** is a BIOS setting that decides what the computer does when power returns after a cut: stay off, turn on, or go back to its last state.
- Proxmox is updated with `apt full-upgrade`, not plain `apt upgrade`.

## What I Did

**1. Checked the first scheduled backup** on the EliteDesk:

```bash
sudo tail -5 /var/log/backup-jellyfin.log
```

The log showed `2026-11-12 08:00:01 start` and `08:00:02 finished, exit code 0`. That is 3 AM my time, with nobody touching it, so the nightly job works.

**2. Cleaned up and checked updates:**

```bash
sudo apt autoremove
apt list --upgradable
sudo apt upgrade --dry-run
systemctl is-enabled unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades
grep -i "automatic-reboot" /etc/apt/apt.conf.d/50unattended-upgrades
sudo tail -5 /var/log/unattended-upgrades/unattended-upgrades.log
```

Results:
- `autoremove` removed nothing. The log showed that `unattended-upgrades` had already auto-removed the old kernel packages (`7.0.0-38`) at 06:22 UTC.
- Three packages were held back (`python3-software-properties`, `snapd`, `software-properties-common`). The dry run said **"Not upgrading yet due to phasing"**, so they will install by themselves in a few days.
- Automatic security updates were already on: the service was `enabled`, and both lines in `20auto-upgrades` ended in `"1"`.
- The `Automatic-Reboot` lines are commented out, so the server never reboots by itself. I choose when.

**3. Installed a firmware update.** The login screen said "1 device has a firmware upgrade available". I looked first, then installed:

```bash
fwupdmgr get-upgrades
sudo fwupdmgr update
sudo reboot
```

The only update was **UEFI dbx**, from `20230501` to `20260402`. After the reboot, Jellyfin was `Up (healthy)` and `fwupdmgr get-upgrades` showed nothing left to update. A prompt to upload a hardware report appeared. I sent one report, then cancelled the "upload automatically in future" question.

**4. Updated the Tower.** From my PC (`ssh pve`):

```bash
apt update
apt list --upgradable
```

The result was **All packages are up to date**, with no repository errors. The Tower already ran kernel `7.0.14-28-pve`, so it didn't need a full upgrade or a reboot for updates.

**5. Set the Tower to power on after a power cut.** I plugged a monitor and keyboard into the Tower, ran `reboot`, tapped **F2** at startup, and set **AC Recovery** to **Power On** (Applied, then Exit).

Then I tested it. I checked the Tower after it came back:

```bash
uptime
df -h /mnt/pve/backup1
qm list
```

`backup1` was mounted with 860 GB free, and VMs 100 and 101 were listed (stopped). Then I shut it down cleanly with `shutdown -h now`, waited for it to switch off, unplugged the power cable for 10 seconds and plugged it back in. **It turned on by itself** without me touching the power button.

## What Broke

- **`autoremove` on its own:** I typed `autoremove` and got `command not found`. It needs `apt` in front, and `sudo`.
- **`ssh pve` from the wrong machine:** In the EliteDesk window it said `Could not resolve hostname pve`, because the shortcut only exists on my PC.
- **I ran `reboot` twice on the Tower.** My SSH window connected again before the first reboot had finished, so the second command restarted it again. Harmless, but it taught me to wait for `Connection closed` and then give it time.
- **The Tower came back with no picture and no network.** After the reboot there was "no signal" on the monitor, SSH said `No route to host`, and `ping` said `Destination host unreachable`, for about 15 minutes. I unplugged everything, did a **full power drain** (cable out, power button held for 30 seconds), and plugged in only power and video. After that I reached the BIOS, set AC Recovery, and the Tower booted into Proxmox normally. **I don't know the exact cause.** It could have been a stuck startup that the power drain cleared, or a display that didn't wake up. I didn't change any other BIOS settings.

## How I Fixed It

- Used `sudo apt autoremove`, and read the log to see the old kernel was already gone.
- Ran `ssh pve` from my PC.
- Tested with `ping` to tell whether the Tower was really down or only had no display.
- Did a full power drain, then checked `backup1`, the VMs and the uptime after it booted.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A scheduled job isn't proven until I've seen it run by itself in the log.
- "Not upgrading yet due to phasing" isn't an error. Wait a few days.
- Automatic security updates install patches but don't reboot. A reboot is still my job.
- Look at what a firmware update is before installing it. A blocklist update is very different from a BIOS flash.
- A blank screen doesn't always mean a dead server. `ping` shows whether the network side is alive.
- A full power drain is a good step when a machine won't start and a normal restart doesn't help.
- Test a power setting for real: shut down cleanly, unplug, plug in and see what happens.

## Not Done Yet

- Buy a **UPS** (battery backup), so a power cut doesn't hard-stop the machines in the first place. AC Recovery only helps after the power returns.
- Install the 51 waiting updates inside the practice VM, or delete the VM.
- Delete the test VM 101 on the Tower when I no longer need it.
- Do a **full Jellyfin restore drill**: stop the container, put the config back, start it and check the libraries.
- Back up the **media** drive, or decide what's replaceable, and add a **third copy** off the Tower (3-2-1).
- Find out why the Tower had no picture after the reboot, if it happens again.

## Next

The managed switch arrives on the 17th, so the next networking lesson is switch basics. The OPNsense router on the Protectli comes after that (UPS first, and tested on a separate network before it replaces the Verizon router). See `PLAN.md`.
