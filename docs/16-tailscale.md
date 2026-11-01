# Lesson 16: Tailscale (Remote Access Without Opening Ports)

**Date:** 2026-11-01
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`), plus my phone

## Goal

Reach my home server (SSH, Jellyfin, copying my own files) from anywhere, without forwarding any ports on my router and without exposing Jellyfin to the internet.

## Background

- Tailscale builds a private network (a "tailnet") that contains only my own devices. Each device gets a private address (starting with `100.`) and talks to the others over an encrypted tunnel.
- The server only makes *outgoing* connections to set it up, so there's nothing to forward on the router. This is the safe alternative to the port forwarding I decided never to do (lesson 13).
- Without the Tailscale app turned on, those `100.` addresses don't exist for a device, so nothing can connect to them.

## What I Did

- Created a Tailscale account with an identity provider I already use, and turned on two-step verification for it.
- Downloaded Tailscale's official installer script to a file instead of piping it straight into the shell, so I could look at it before running it, then installed Tailscale on the server.
- Joined the server to my tailnet, approving the device in the browser, then checked its status.
- Installed the Tailscale app on my phone, signed in with the same account, and tested.

```bash
curl -fsSL https://tailscale.com/install.sh -o /tmp/tailscale-install.sh
head -40 /tmp/tailscale-install.sh
sudo sh /tmp/tailscale-install.sh

sudo systemctl is-active tailscaled
sudo tailscale up --hostname=goodmedia
tailscale status
```

Results worth noting:
- `tailscale status` showed the server as `goodmedia` with its private `100.` address, signed in to my account.
- Phone tests against Jellyfin at `http://<tailscale-ip>:8096`:

| Phone setup | Result |
|-------------|--------|
| Home Wi-Fi, Tailscale on | Jellyfin loaded |
| Cellular data (away from home), Tailscale on | Jellyfin loaded |
| Wi-Fi off and Tailscale off | "Server not found" |

- So the server is reachable from my own devices from anywhere, and not reachable from a device that isn't on my tailnet.

## How It Fits with My Firewall

- UFW needed no new rule. Tailscale's traffic arrives through its own network interface (`tailscale0`) and SSH was already allowed.
- My Docker firewall rule from lesson 15 only drops traffic that arrives on the server's regular network port (`eno1`) from outside the home network. Tailscale traffic isn't affected by it, so Jellyfin is reachable from my home network and from my tailnet, and from nowhere else.

## What Broke

- Nothing broke. The first time I tested, I wasn't sure which network the phone was on, so I repeated the test with Wi-Fi on and off to be sure. Name the network you're testing from.

## Still To Do

- In the Tailscale admin console, disable key expiry for the server (Machines, the three dots on the `goodmedia` row, Disable key expiry). By default, a device's key expires after a while, and then the server would drop off my tailnet until I sign in again. I'll leave expiry on for my phone and PC.
- Install Tailscale on my Windows PC, then test SSH and file copying (`scp`) to the server over the tunnel, which is how I'll add my own media from outside the house.
- I haven't tested SSH or file copying over Tailscale yet.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A VPN like Tailscale lets me reach home devices without opening ports, which keeps the router closed to the internet.
- Only devices signed in to my account can reach the private addresses.
- Download and look at an installer before running it, instead of piping it into the shell.
- Firewall rules are tied to network interfaces. My Docker rule watches the regular port, so tunnel traffic comes through a different door.
- Test from the places that matter: home Wi-Fi, away from home, and with the VPN off.

## Next

Install Tailscale on my PC, test SSH and file copying over the tunnel, and then add a bigger media drive.
