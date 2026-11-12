# Lesson 25: IP Addressing and DNS Basics

**Date:** 2026-11-11
**Machine:** EliteDesk 800 G3 Mini (`goodmedia`), all commands read-only

## Goal

Learn to read my own network (addresses, gateway, DNS), test it layer by layer, and watch DNS answers, so the router and ad blocker work later makes sense.

## Background

- An **IP address** identifies a device on a network. My EliteDesk is `192.168.1.187`.
- A **subnet** is the group of addresses that share a network. In `192.168.1.0/24`, the `/24` means the first three numbers name the network and the last number picks the device, so about 254 devices fit.
- The **gateway** is the router that carries traffic to anywhere outside the subnet. Mine is `192.168.1.1`.
- **DNS** turns names like `google.com` into addresses. Without it, I'd need to type numbers.
- **IPv4** addresses look like `142.251.45.174`. **IPv6** addresses are longer and use hex, like `2607:f8b0:4004:c21::8a`. A DNS **A** record holds an IPv4 address and an **AAAA** record holds an IPv6 one.
- **TTL** (time to live) is how many seconds an answer can be remembered before asking again.
- **NXDOMAIN** is DNS saying "that name doesn't exist." A DNS ad blocker uses this kind of answer so ad domains never load.

## What I Did

Looked at the server's addresses, routes and DNS settings:

```bash
ip -br addr
ip route
resolvectl status | head -20
```

Tested each layer, from nearest to farthest:

```bash
ping -c 3 192.168.1.1     # the router
ping -c 3 1.1.1.1         # the internet, by address (no DNS)
ping -c 3 google.com      # the internet, by name (needs DNS)
```

Watched DNS answers with `dig` (`bind9-dnsutils`, already installed):

```bash
dig google.com +noall +answer +stats
dig @1.1.1.1 google.com +noall +answer +stats
dig thisnamedoesnotexist-12345.com +noall +comments | grep status
dig google.com AAAA +short
```

Results:

| Test | Result |
|------|--------|
| Router `192.168.1.1` | 0.6 ms, 0% loss |
| Internet `1.1.1.1` | about 4 ms, 0% loss |
| `google.com` by name | about 10 ms, 0% loss (over IPv6) |
| `dig google.com` | answered by `127.0.0.53` in 0 ms, address `142.251.45.174`, TTL 173 |
| `dig @1.1.1.1 google.com` | answered by Cloudflare in 1 ms, same address, TTL 169 |
| A made-up name | `status: NXDOMAIN` |
| `AAAA` lookup | four IPv6 addresses |

What the network looks like:
- The home network is `192.168.1.0/24`, with the router (and the gateway) at `192.168.1.1`.
- Docker uses its own private networks inside the server (`172.17.0.0/16` and `172.18.0.0/16`), separate from my home network.
- The server's DNS is `192.168.1.1` (the router) and a Verizon IPv6 DNS address. `tailscale0` has its own DNS, `100.100.100.100`.
- The Wi-Fi card (`wlp1s0`) is unused. The server uses only the cable.
- The server doesn't ask the router directly. It asks a helper on itself, `127.0.0.53` (`systemd-resolved`), which remembers recent answers and passes new questions to the router.

## What Broke

Nothing broke. These commands only look at things.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- When something is wrong with the network, test in order: router, then internet by address, then internet by name. Where it fails tells me which part is broken.
- If pinging `1.1.1.1` works but pinging `google.com` fails, the problem is DNS.
- A subnet like `/24` tells me which numbers name the network.
- DNS answers are remembered for a while (TTL), which is why repeat lookups are fast.
- Different DNS servers give the same answer for a normal name, so changing which server I use (for example, to an ad blocker) changes only what it chooses to answer.
- `NXDOMAIN` is how a DNS ad blocker can make ad domains disappear.

## Not Done Yet

- ~~Remove the old kernel files and check the three held-back packages.~~ Done in lesson 26: the old kernel was already auto-removed, and the held-back packages were only phased updates.
- Pick the managed switch, then OPNsense on the Protectli (see `PLAN.md`).

## Next

The managed switch, then more network practice on the Protectli router (see `PLAN.md`).
