# Lesson 14: A Fixed IP Address for the Server (DHCP Reservation)

**Date:** 2026-11-01
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`) and the home router (Verizon Fios CR1000A)

## Goal

Make sure the server always gets the same IP address, so my SSH command, my Jellyfin bookmark, and my firewall settings never break when the router hands out a different address.

## Background

- **DHCP** is the service in the router that gives each device an address when it joins the network. By default the address is only *lent* for a set time (a **lease**), so it can change.
- Two ways to get a fixed address: set it on the server itself (a static IP), or tell the router to always give the same address to that device (a **DHCP reservation**). I used a reservation. It's managed in one place, and the router won't hand the same address to another device by mistake.
- A device is identified to the router by its **MAC address**, the hardware address of its network port.

## What I Did

On the server, I gathered the details I needed:

```bash
ip -br address show eno1      # current address
ip link show eno1             # MAC address (after "link/ether")
ip route | grep default       # the router's address ("default via ...")
```

- The route line said `proto dhcp`, which confirmed the address came from the router and wasn't reserved.
- The router's address was `<router-ip>` (the `default via` address).

In the router's web page (opened in a browser on my PC at its address), I made the reservation:

1. **Advanced → Network Settings → IPv4 Address Distribution** showed the DHCP server: a pool of addresses it lends out, and a lease time of 1440 minutes (24 hours).
2. **Connection List** showed every device, with `goodmedia` listed as **Dynamic**.
3. **Edit** on the `goodmedia` row showed the host name, IP address, and MAC address, plus a **Static Lease Type** checkbox. I checked it, kept the address the server already had (`<server-ip>`), and clicked **Apply**.

Results worth noting:
- The router's Connection List now shows `goodmedia` as **Static** with a lease of **Never**, so it doesn't expire.
- On the server, `ip -br address show eno1` still showed `<server-ip>/24` after I logged in again.
- The server's IPv6 address changed at some point, because the internet provider changes the IPv6 prefix over time. That doesn't matter here. I fixed the IPv4 address, which is what SSH, Jellyfin and the firewall rules use.

## What Broke

- **Started on the wrong machine.** My first `ip` output came from WSL (`172.22.x.x`, a virtual network inside Windows), not the server. The prompt and the address gave it away. I logged in to the server over SSH and ran the commands there.
- **Hunted for the right page.** Router menus differ by model, and a reservation isn't always under "Devices". I took screenshots at each step to find it. The Device Settings page and the *Network (Home/Office)* page didn't have it. It was under **IPv4 Address Distribution → Connection List → Edit**.
- **The router's "Devices" page showed my Netgear access point as Offline** even though it was working and holding a lease in the Connection List. The status label was stale, and I ignored it.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- DHCP lends addresses for a limited time. A reservation makes the router give the same address to the same device every time.
- A MAC address identifies a network port. The router uses it to match a device to its reservation.
- Reserving the address the server already has avoids changing anything else.
- Router menus differ, and some labels are misleading. Screenshots and careful reading found the right page.
- Changes to a router affect every device at home, so check each field before clicking Apply.

## Plan for Later (not done yet)

I plan to replace the router with an OPNsense box on its own mini PC. When that happens:
- DHCP moves to OPNsense, and I'll redo this reservation there.
- If I give OPNsense the same network (`<router-ip>` as its own address, same range), the server's address, SSH command, and the firewall's home-network exception keep working.
- The Verizon router's options (IP Passthrough, or plugging OPNsense directly into the ONT with no Fios TV) need to be checked before I change anything. I haven't verified either.

## Next

Make Docker respect the firewall: Docker's published ports bypass UFW, so I'll restrict them with rules in Docker's `DOCKER-USER` chain and test from outside the allowed network.
