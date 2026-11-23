# Lesson 28: Finding the New Switch and Adopting It Into the UniFi Controller

**Date:** 2026-11-22
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`, runs the UniFi Network controller in Docker), Ubiquiti **USW-Flex-2.5G-8** switch, Windows PC

## Goal

Find the new switch on the network and get the UniFi controller, which runs in a container on `goodmedia`, to adopt and manage it.

## Background

- A new switch gets its address from DHCP, so I don't know its IP at first. I know its **MAC address**, so I can find the IP by looking up which address that MAC answers on.
- `ip neigh` shows the computer's **neighbour (ARP) table**: the IPs it has recently talked to and their MAC addresses. A device only appears there after something has talked to it, which is why I ping the whole subnet first.
- A UniFi device has to be told where its controller is (the **inform URL**, `http://<controller-IP>:8080/inform`). The usual ways are:
  - SSH into it and run `set-inform`
  - it finds the controller by itself with a broadcast on the local network
  - DNS: it looks up the name `unifi`
  - DHCP option 43 from the router
- **Some small UniFi switches have no SSH login at all**, including the Flex Mini, the Ultra and the Flex 2.5G I have. On these, `set-inform` over SSH is impossible.
- When the controller runs in Docker on a bridge network, the broadcast discovery usually fails, because the container doesn't see the switch's broadcasts and would answer with its internal Docker address anyway.

## What I Did

**Pinged every address on the subnet** in the background, so every device that answers lands in the neighbour table:

```bash
for i in $(seq 1 254); do ping -c1 -W1 192.168.1.$i > /dev/null 2>&1 & done
```

Each ping is a background job. The `Exit 1` lines afterwards are just addresses where nothing answered.

**Looked up the switch's MAC address:**

```bash
ip neigh | grep -i <switch-MAC>
```

```
192.168.1.205 dev eno1 lladdr <switch-MAC> REACHABLE
```

The switch is at **192.168.1.205**.

**Tried to log in over SSH**, then tested the port with netcat:

```bash
ssh ubnt@192.168.1.205
nc -w 3 192.168.1.205 22
```

**Checked the controller container** and `goodmedia`'s address:

```bash
sudo docker ps --format '{{.Names}}: {{.Ports}}'
ip -4 addr show eno1 | grep inet
```

`unifi-network-application` publishes 8080 (inform), 8443 (web page), 3478/udp, 10001/udp and others. `unifi-db` is its database. `goodmedia` is **192.168.1.187**.

**Factory reset the switch** (held the reset pinhole about 10 seconds), waited, and tried again. It answered pings, but SSH was still refused.

**Opened the controller** at `https://192.168.1.187:8443` → UniFi Devices: "No UniFi Devices found". In Device Updates & Settings, **Inform Host Override** was already set to `192.168.1.187`.

**Added a local DNS record** on the DNS server running on `goodmedia`: `unifi` → `192.168.1.187`, and checked it:

```bash
nslookup unifi 192.168.1.187
```

It answered `192.168.1.187`.

**Checked that the firewall wasn't blocking the switch:**

```bash
sudo iptables -L DOCKER-USER -n -v --line-numbers
```

The four rules from lesson 15 only drop traffic from **outside** my network (`! 192.168.1.0/24`) to ports 53, 80 and 8096. Traffic from the switch to 8080 isn't blocked.

**Read the label under the switch:** model **USW-Flex-2.5G-8**, one of the UniFi switches without SSH.

**Sent the inform URL with the HostiFi Device Discovery Tool** (free Windows app) on my PC. It found the switch, I clicked **Adopt**, typed `http://192.168.1.187:8080/inform` and clicked **Adopt** again. It replied "Perfect! Adoption request sent".

**Adopted it in the controller.** The switch appeared under UniFi Devices, and after adopting it shows:

| Name | Status | IP | Uplink |
|------|--------|----|--------|
| USW Flex 2.5G 8 | Online | 192.168.1.205 | 2.5 GbE |

## What Broke

1. I copied `ssh ubnt@<that-IP>` literally:

   ```
   -bash: syntax error near unexpected token `newline'
   ```

2. SSH was refused before the login prompt, both before and after a factory reset:

   ```
   kex_exchange_identification: read: Connection reset by peer
   Connection reset by 192.168.1.205 port 22
   ```

   `nc` returned straight away and printed nothing. A working SSH server sends a greeting line first.

3. The controller showed "No UniFi Devices found", even though the switch was on the same network.

4. The first time I clicked Adopt in the HostiFi tool, nothing happened.

## How I Fixed It

1. `<that-IP>` was a placeholder. In bash, `<` means "read input from a file", so bash choked on it. Type the real IP with no angle brackets.

2. This wasn't a fault. The **USW-Flex-2.5G-8 has no SSH login**, so no password or reset would ever get me in. The port accepts the connection and then hangs up.

3. The controller runs in Docker, so it never heard the switch's discovery broadcast. The switch needed the inform URL from somewhere else. With no SSH, no way to set option 43 on the Verizon router, and no proof the switch used my DNS server, I used the HostiFi Discovery Tool to send it directly from my PC.

4. The Inform URL box only showed a grey hint (`http://unifi.your-domain.com:8080/inform`), so it was actually empty. Once I typed the real URL, the adoption request went through.

## What I Learned

- A `ping` sweep plus `ip neigh` finds a device by its MAC address without logging in to the router.
- Angle brackets in instructions are placeholders. Typed into bash, they're redirection.
- "Connection reset" during `kex_exchange_identification` means the network path is fine and the port is open, but the other end refuses SSH. Check the device's model before assuming it's broken. Some devices simply don't offer SSH.
- A controller in Docker can't rely on discovery broadcasts. Adopting needs `set-inform`, a `unifi` DNS record, DHCP option 43 or a tool like HostiFi's.
- A local `unifi` DNS record only helps devices that actually use that DNS server. Once the router hands it out (or option 43) by DHCP, future UniFi devices should show up for adoption by themselves.
