# Lesson 05: SSH Hardening on the Server

**Date:** 2026-10-18
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`), managed from WSL on the Windows PC

## Goal

Make SSH on the server safer: log in with a key instead of a password, and turn off password and root login so guessing passwords over the network no longer works.

## What I Did

- Created an SSH key pair on my WSL machine with a passphrase.
- Copied the public key to the server so it accepts my key.
- Added a small config file on the server that turns off password login and root login.
- Checked the config for errors, confirmed the settings that were actually in effect, and reloaded SSH.
- From WSL, tested that password login and root login are now refused.

```bash
# On WSL: create a key pair (ed25519) and copy the public key to the server
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_goodmedia
ssh-copy-id -i ~/.ssh/id_ed25519_goodmedia.pub <server-user>@<server-ip>

# On the server: add a drop-in config file
sudo nano /etc/ssh/sshd_config.d/10-hardening.conf
```

Contents of `10-hardening.conf`:

```
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
```

```bash
# On the server: check the syntax, see the settings SSH actually uses, then reload
sudo sshd -t
sudo sshd -T | grep -Ei 'passwordauthentication|kbdinteractiveauthentication|permitrootlogin'
sudo systemctl reload ssh

# From WSL: confirm password and root login are refused
ssh -o PubkeyAuthentication=no <server-user>@<server-ip>
ssh root@<server-ip>
```

Results worth noting:
- `sshd -t` printed nothing, which means the config is valid.
- `sshd -T` showed `passwordauthentication no`, `kbdinteractiveauthentication no`, and `permitrootlogin no`.
- Both refusal tests from WSL ended with `Permission denied (publickey)`.
- The file is named `10-...` on purpose. SSH uses the first value it finds for a setting, and the files in `sshd_config.d` are read in order, so a low number makes sure my settings win.

## What Broke

- **Ran the refusal tests from the wrong machine.** My first tests ran from inside the server, so they proved nothing. The prompt tells you where you are: `admingoodfella@DESKTOP-...` is WSL, and `<server-user>@goodmedia` is the server. I had to `exit` and re-run them from WSL.
- **Typed `~/.ssh/config` as a command.** Bash tried to run the file and said "Permission denied." A file path by itself is not a command. Open it with an editor (`nano ~/.ssh/config`).
- **Typo `~.ssh/config`** (missing `/`) gave "No such file or directory."
- **Created the shortcut file on the server instead of WSL.** The `~/.ssh/config` shortcut belongs on the machine I connect *from*.
- **`ssh goodmedia` tried to log in as my WSL username** (`admingoodfella`) and got `Permission denied (publickey)`. The shortcut file wasn't being applied, so SSH used my local username. Fix: connect with the full command (`ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip>`) and check the config file with `cat ~/.ssh/config`.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A key pair has a private half that stays on my machine and a public half that goes on the server. The passphrase protects the private key if someone copies it.
- Key login is much harder to attack than passwords, because there is nothing to guess over the network.
- Turn password login off only after key login is proven to work, or I can lock myself out.
- `sshd -t` checks the config before I reload, and `sshd -T` shows what SSH is really using.
- `reload` applies the new settings without dropping the sessions that are already open.
- "Permission denied (publickey)" is the right answer when I try to log in without the key.
- Always check which machine the prompt belongs to before running a command.

## Next

A firewall (UFW), then `fail2ban` and automatic security updates.
