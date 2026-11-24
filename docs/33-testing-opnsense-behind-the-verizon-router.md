# Lesson 33: Testing OPNsense Behind the Verizon Router

**Date:** 2026-11-23 (OPNsense itself was installed on the Protectli earlier, around Nov 18. This lesson covers checking and testing it.)
**Machines:** Protectli Vault FW4C (OPNsense, hostname `OPNsense-test`), Windows PC as the test client

## Goal

Make sure the Protectli with OPNsense works as a router on a **separate test network**, without touching the house's internet, before it replaces the Verizon router.

## Background

- A router has two sides:
  - **WAN** faces the internet. Here it's plugged into the Verizon router, which gives it an address like any other device.
  - **LAN** faces my devices. OPNsense hands out addresses there with its own DHCP server and answers DNS.
- The Protectli's ports are labeled **WAN, LAN, OPT1, OPT2**. In OPNsense they appear as `igc1` (WAN) and `igc0` (LAN).
- For testing behind Verizon, the OPNsense LAN must use a **different range** from the home network (192.168.1.x). Otherwise both sides use the same addresses and routing breaks. My LAN is **10.10.10.1/24**.
- **Only the test computer** goes on the LAN port. Plugging that port into the home switch would put a second DHCP server on the home network.
- Updates that include `base` and `kernel` update the FreeBSD system underneath OPNsense and need a reboot.

## What I Did

**Checked the console** on the Protectli (monitor + keyboard):

```
*** OPNsense-test.home.arpa: OPNsense 26.7 (amd64) ***
 LAN (igc0)  -> v4: 10.10.10.1/24
 WAN (igc1)  ->
```

The WAN had no address yet.

**Cabled it for the test:**

```
Verizon router (LAN port) --grey--> Protectli WAN (igc1)
Protectli LAN (igc0)      --black--> Windows PC (its normal cable unplugged)
```

**Checked the PC got an address from OPNsense** (Command Prompt on Windows):

```
ipconfig
```

```
Connection-specific DNS Suffix . : home.arpa
IPv4 Address. . . . . . . . . . . : 10.10.10.170
Subnet Mask . . . . . . . . . . . : 255.255.255.0
Default Gateway . . . . . . . . . : 10.10.10.1
```

**Reset the root password** from the console menu (option **3**), because I didn't remember it, then logged in to the web page at `https://10.10.10.1`.

**Checked the dashboard:**

- **WAN:** `192.168.1.202/24` from the Verizon router, plus an IPv6 address. Gateway `WAN_DHCP` at `192.168.1.1`, active.
- **LAN:** `10.10.10.1/24`.
- Both ports linked at **2500Base-T full-duplex**.
- All services green (DHCP/DNS, Unbound, firewall, web GUI), and the traffic graph showed the PC's traffic going in and out. The internet worked through OPNsense.

**Updated it from 26.7 to 26.7.9:** System → Firmware → **Check for updates**. It found 91 packages to upgrade and 3 new ones, about 173 MiB, including `base` and `kernel`. I clicked **Update** on the Updates tab and let it download, install and reboot.

## What Broke

1. The WAN showed no address on the console.
2. The old terminal window on the PC froze when I swapped the PC's network cable.
3. I didn't remember the OPNsense root password.
4. The Firmware **Status** tab only had **Check for updates**, with no Update button.

## How I Fixed It

1. The console screen doesn't refresh by itself. With the WAN cable to the Verizon router in, the dashboard showed it had `192.168.1.202`.
2. That window held SSH sessions to the server. Unplugging the cable froze them. A fresh Command Prompt (Windows + R → `cmd`) worked fine.
3. Console option **3** resets the root password. That's allowed because I'm at the machine. The web page uses the same password.
4. The **Update** button only appears on the **Updates** tab after a check. A release-notes pop-up covered it until I closed it.

**Still to do:**

- [ ] Download a config backup (System → Configuration → Backups). It contains password hashes, so it stays off GitHub.
- [ ] Review the default firewall rules and the DNS setup.
- [ ] Plan the swap: change the LAN to `192.168.1.1/24` so the server (.187), the Tower (.178) and the switch (.205) keep their addresses, add DHCP reservations, then move the cables at a quiet time, with the Verizon router as the fallback.

## What I Learned

- Testing behind the existing router is safe as long as the LAN uses a different range and only the test PC is on it.
- `ipconfig` on Windows (not in WSL) shows which network the PC is really on: address, gateway and DNS suffix.
- The console shows each interface's address at a glance and has recovery options, like resetting the password.
- A firewall update can include the whole operating system, so expect a reboot and don't touch it while it runs.
