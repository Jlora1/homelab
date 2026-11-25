# Lesson 34: Swapping the Verizon Router for OPNsense (in progress)

**Date:** 2026-11-24 to 2026-11-25 (late night, while everyone was asleep)
**Machines:** Protectli Vault FW4C (OPNsense), Fios ONT, USW-Flex-2.5G-8 switch, EliteDesk (`goodmedia`), Netgear Orbi RBR760 (bought secondhand), Windows PC

## Goal

Replace the Verizon router with the Protectli running OPNsense as the house's real router and firewall, keep every server at its usual address, and get Wi-Fi back from the Orbi mesh instead of the Verizon router.

## Background

- **Fios fiber:** the Verizon router plugs into a wall box (the **ONT**) by Ethernet. Any router can plug in there instead. No modem to replace.
- The Verizon router had no bridge or access-point mode, and its extenders only work with it. So the plan was to retire it fully and use the **Orbi in Access Point (AP) mode** for Wi-Fi.
- In **AP mode**, the Orbi stops handing out addresses and routing. It only provides Wi-Fi and passes every device through to OPNsense.
- **Firewall rules after a fresh install:** LAN has "allow LAN to any" (IPv4 and IPv6). WAN has no pass rules, so everything coming in from the internet is blocked except replies.
- **Unbound** is OPNsense's built-in DNS server. I turned on **DNSSEC**, which checks that DNS answers haven't been tampered with.
- A **DHCP reservation** ("Host" in Dnsmasq) ties a MAC address to a fixed IP. A USB network adapter has its **own MAC**, different from the computer's built-in port.
- Netplan files must use correct YAML. The one-line form `{key: value}` avoids indentation mistakes, and the file must be `chmod 600`.

## What I Did

**Prepared beforehand:**

- Set the Protectli's BIOS (Advanced → Power Management Features → **Restore From AC Power Loss**) from **Power Off** to **Power On**, so the house internet comes back by itself after a power cut. Saved with F4.
- Turned on **DNSSEC** in Services → Unbound DNS → General.
- Already had a config backup from lesson 33 (kept off GitHub).

**The cutover:**

1. Unplugged the Verizon router.
2. Moved the ONT cable to the Protectli's **WAN** port and the switch uplink to its **LAN** port.
3. On the OPNsense console, option **2** (Set interface IP address) → LAN:
   - IPv4 `192.168.1.1/24`, no upstream gateway
   - DHCP server on, range `192.168.1.100`–`192.168.1.170` (keeps clear of the Tower .178, goodmedia .187, switch .205)
4. The console then showed the WAN with a **public address straight from Fios** (no MAC cloning needed) and IPv6 on the LAN. OPNsense also updated itself to 26.7.9_3.

```
LAN (igc0) -> v4: 192.168.1.1/24
              v6/ia6: <IPv6 prefix from Fios>/56
WAN (igc1) -> v4/DHCP4: <public address>/24
```

**Reserved addresses** in Services → Dnsmasq DNS & DHCP → **Hosts**, then **Apply**:

| Host | IP |
|------|----|
| goodmedia | 192.168.1.187 |
| sw-office | 192.168.1.205 |

**goodmedia's network:** goodmedia's cable is in a **USB 2.5 GbE adapter**, not its built-in `eno1` port, and Ubuntu had no settings for the adapter. At goodmedia's own keyboard:

```bash
ip -br link        # the adapter shows as enx<its MAC>
cd /etc/netplan
echo 'network: {version: 2, ethernets: {enx<MAC>: {dhcp4: true}}}' | sudo tee 60-usb-ethernet.yaml
sudo chmod 600 60-usb-ethernet.yaml
sudo netplan apply
```

Then I changed goodmedia's reservation to the **adapter's** MAC and rebooted. Result:

```
IPv4 address for enx<MAC>: 192.168.1.187
```

All five containers came back up (Jellyfin and Uptime Kuma healthy).

**Wi-Fi with the Orbi:**

1. Plugged the Orbi's **Internet** port into the switch and factory reset it (paperclip, 7 seconds), because it was secondhand.
2. Plugged my PC into one of the Orbi's other ports. It got `10.0.0.2`: the Orbi starts as its own router.
3. At `http://10.0.0.1`: ran the setup wizard (it said "Existing Router or Gateway Detected"), set the Wi-Fi name and password to match the old Verizon Wi-Fi, then **Advanced → Advanced Setup → Router / AP Mode → AP Mode → Apply**.
4. Checked from the PC:

```
ipconfig /release
ipconfig /renew
```

```
Connection-specific DNS Suffix . : home.arpa
IPv4 Address. . . . . . . . . . . : 192.168.1.155
Default Gateway . . . . . . . . . : 192.168.1.1
```

The address came from OPNsense through the Orbi, so AP mode was working.

## What Broke

1. F11 at boot showed "Please select boot device" instead of the BIOS.
2. After the swap, goodmedia didn't answer at `192.168.1.187` (UniFi page timed out, `ssh goodmedia` gave "No route to host").
3. My netplan file failed several times:

   ```
   ** WARNING **: Permissions for /etc/netplan/60-usb-ethernet.yaml are too open.
   Error in network definition: expected mapping (check indentation)
   ```

   I also hit `chom: command not found`, `networkct1: command not found`, `Device "ADAPTER" does not exist`, and `Permission denied`.
4. goodmedia and the switch got pool addresses (`.123`, `.128`) instead of their reservations.
5. Registering the Orbi said **"Serial Number is already registered in our database."**
6. Too many wrong Orbi logins locked the page for 5 minutes.
7. Phones wouldn't join the Wi-Fi, even with the same name and password.

## How I Fixed It

1. F11 is only the boot menu. Choosing **UEFI OS** booted OPNsense normally. The BIOS is the Delete key.
2. goodmedia's cable was in the USB adapter, which Ubuntu wasn't configured to use, so goodmedia had no network. I added the adapter in netplan.
3. Typos: `ethernet` vs `ethernets`, missing spaces after colons, `chmod` misspelled, `networkctl` ends in a lowercase **L** (not the number 1), and `ADAPTER` was a placeholder. A command split over two lines ran the file name as its own command, which gave "Permission denied". The one-line YAML form and doing it from inside `/etc/netplan` fixed it. After `chmod 600`, reading the file needs `sudo cat`.
4. The reservations had been saved without IPs and the wrong MAC (built-in port, not the adapter). Fixed both, clicked **Apply**, and rebooted goodmedia.
5. The previous owner registered it. Registration is optional, so I skipped it. The factory reset already cleared the previous owner's settings.
6. Waited 5 minutes and used the Orbi's own password reset (serial number + security questions).
7. Phones remembered the old network's security settings. **Forget network**, then join again with the same password.

**Still to do:**

- [ ] Plug in the two Orbi satellites where the Verizon extenders were.
- [ ] Power-cycle the switch so it picks up `192.168.1.205`.
- [ ] DNS: have OPNsense's DHCP hand out the DNS server on goodmedia (`192.168.1.187`), which forwards to Unbound on `192.168.1.1`.
- [ ] Keep the Verizon router boxed as the fallback.

## What I Learned

- On Fios, swapping routers is just moving the ONT cable. The new router got a public address straight away.
- Plan the addresses first: a DHCP range that avoids the fixed addresses, and reservations for every server.
- A USB network adapter is a separate interface with its own name and MAC. The OS, the reservation and the cable all have to agree on which port is used.
- In AP mode, a mesh router just extends the network. `ipconfig` showing the main router's gateway proves it.
- With secondhand network gear, factory reset it first.
- "Forget network" fixes devices that won't join after a router change, even with the same Wi-Fi name and password.
