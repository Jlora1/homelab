# Lesson 16: Tailscale (Remote Access Without Opening Ports)

**Date:** 2026-11-01
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`), my phone, and my Windows PC (managed from WSL)

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
- Installed Tailscale on my Windows PC, signed in with the same account, and tested SSH and file copying (`scp`) from WSL to the server's `100.` address.
- Disabled key expiry for the server, the PC and the phone in the admin console.

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

## Testing From My PC (WSL)

WSL reaches the tailnet through the Windows Tailscale app, so I used the server's `100.` address from WSL:

```bash
ping -c 3 <server-tailscale-ip>
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-tailscale-ip>

# On the server, check how this session arrived
echo $SSH_CONNECTION

# From WSL: copy a file over the tunnel and read it back
scp -i ~/.ssh/id_ed25519_goodmedia ~/tailnet-test.txt <server-user>@<server-tailscale-ip>:/home/<server-user>/tailnet-test.txt
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-tailscale-ip> "cat ~/tailnet-test.txt && rm ~/tailnet-test.txt"
```

Results worth noting:
- The ping from WSL got replies in about 2-12 ms with 0% loss.
- SSH asked me to trust the host key on first use, and said the key was already known under the server's LAN address. That is the same server, reached by a second address.
- `echo $SSH_CONNECTION` printed my PC's tailnet address, the client port, the server's tailnet address and port 22, which shows the session really came over Tailscale and not over the home network.
- `scp` copied the file (`100%`) and `cat` printed it back.
- `who` and `last` printed nothing on this Ubuntu version, because newer releases no longer keep the old login records those commands read. `$SSH_CONNECTION` is a simple alternative for the current session.

## Key Expiry

By default a device's Tailscale key expires after a while, and the device would drop off the tailnet until I signed in again. For a server I can't easily reach, that could lock me out, so I disabled key expiry (Machines, the three dots on the device's row, Disable key expiry) for the server, the PC and the phone.

## Not Tested Yet

- SSH and `scp` from my PC while **outside my home network** (for example on a hotspot, or at a library or a friend's Wi-Fi). Jellyfin was already reached from my phone on cellular data through the tunnel, and SSH and `scp` work from the PC on my home network, but I haven't run SSH or `scp` from the PC on a different network. I didn't have a hotspot available, so I'll test this next time I'm on another network.
- `fail2ban` originally only ignored my home network, so failed logins arriving over Tailscale would have counted toward a ban. I added the tailnet range (`100.64.0.0/10`) to `ignoreip` and recorded it in [lesson 07](07-fail2ban.md).

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A VPN like Tailscale lets me reach home devices without opening ports, which keeps the router closed to the internet.
- Only devices signed in to my account can reach the private addresses.
- Download and look at an installer before running it, instead of piping it into the shell.
- Firewall rules are tied to network interfaces. My Docker rule watches the regular port, so tunnel traffic comes through a different door.
- Test from the places that matter: home Wi-Fi, away from home, and with the VPN off.
- `echo $SSH_CONNECTION` shows which address a session came in on, which proves which network path was used.
- Keys expire by default. Decide per device whether that's what I want, and turn it off for a headless server.

## Next

Copy my own media to the server and see it appear in Jellyfin ([lesson 17](17-copying-media-to-the-server.md)), then add a bigger media drive.
