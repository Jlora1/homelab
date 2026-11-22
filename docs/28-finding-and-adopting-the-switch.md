# Lesson 28: Finding the New Switch and Connecting It to the Controller (in progress)

**Date:** 2026-11-22
**Machines:** EliteDesk 800 G3 Mini (`goodmedia`), the new Ubiquiti managed switch

## Goal

Find the new switch on the network, log in to it over SSH, and point it at the UniFi controller running in a container so the controller can adopt and manage it.

## Background

- A new switch gets its address from DHCP, so I don't know its IP at first. I know its **MAC address**, so I can find the IP by checking which address that MAC answers on.
- `ip neigh` shows the computer's **neighbour (ARP) table**: which IPs it has recently talked to and their MAC addresses. A device only shows up there after something has talked to it, which is why I ping the whole subnet first.
- A Ubiquiti device out of the box takes the login `ubnt` / `ubnt` (newer firmware: `ui` / `ui`).
- The switch has to be told where the controller is with `set-inform http://<controller-IP>:8080/inform`, unless it finds the controller by itself on the same network.

## What I Did

**Pinged every address on the subnet** in the background, so every device that answers lands in the neighbour table:

```bash
for i in $(seq 1 254); do ping -c1 -W1 192.168.1.$i > /dev/null & done
```

Each ping is a background job. The `Exit 1` lines afterwards are just addresses where nothing answered.

**Looked up the switch's MAC address** in the neighbour table:

```bash
ip neigh | grep -i <switch-MAC>
```

```
192.168.1.205 dev eno1 lladdr <switch-MAC> REACHABLE
```

The switch is at **192.168.1.205**.

**Tried to log in:**

```bash
ssh ubnt@192.168.1.205
```

**Tested the SSH port directly** with netcat:

```bash
nc -w 3 192.168.1.205 22
```

## What Broke

1. I copied `ssh ubnt@<that-IP>` literally:

   ```
   -bash: syntax error near unexpected token `newline'
   ```

2. With the real IP, SSH was refused before the login prompt:

   ```
   kex_exchange_identification: read: Connection reset by peer
   Connection reset by 192.168.1.205 port 22
   ```

3. `nc` returned straight away and printed nothing. A working SSH server sends a greeting line such as `SSH-2.0-dropbear` first.

## How I Fixed It

1. In instructions, `<that-IP>` is a placeholder. In bash, `<` means "read input from a file", so bash tried to read from a file named `that-IP>` and failed. Swap in the real IP and leave out the angle brackets.

2 and 3. Port 22 is open (the connection gets accepted), but the switch hangs up before sending its SSH greeting. That usually means:

- the switch was **adopted by another controller before**, which changed the login and may have turned SSH off, or
- it **hadn't finished booting**.

Next step: **factory reset** the switch (hold the reset button for about 10 seconds with the power on, then wait about 2 minutes), then:

```bash
ssh ubnt@192.168.1.205          # password ubnt, or ui / ui on newer firmware
set-inform http://<goodmedia-IP>:8080/inform
```

Then click **Adopt** in the controller and run `set-inform` once more if it gets stuck.

Before that, check the controller container can actually be reached:

```bash
sudo docker ps                     # 8080, 8443, 3478/udp, 10001/udp published (or host networking)
nc -zv <goodmedia-IP> 8080         # should say "succeeded"
```

_To finish: record the result of the reset, the adoption, and the controller's compose file in `configs/`._

## What I Learned

- `ping` sweep plus `ip neigh` finds a device by its MAC address without logging in to the router.
- Angle brackets in instructions are placeholders. Typed into bash, they're redirection.
- "Connection reset" during `kex_exchange_identification` means the network path is fine and the port is open. The SSH service on the other end is refusing, so the fix is on the device, not the network.
