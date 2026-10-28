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
- Key login still works after hardening. I logged in from WSL with `ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip>` and my key passphrase, with no server password asked.
- The file is named `10-...` on purpose. SSH uses the first value it finds for a setting, and the files in `sshd_config.d` are read in order, so a low number makes sure my settings win.

## What Broke

- **Ran the refusal tests from the wrong machine.** My first tests ran from inside the server, so they proved nothing. The prompt tells you where you are: `admingoodfella@DESKTOP-...` is WSL, and `<server-user>@goodmedia` is the server. I had to `exit` and re-run them from WSL.
- **Typed `~/.ssh/config` as a command.** Bash tried to run the file and said "Permission denied." A file path by itself is not a command. Open it with an editor (`nano ~/.ssh/config`).
- **Typo `~.ssh/config`** (missing `/`) gave "No such file or directory."
- **Created the shortcut file on the server instead of WSL.** The `~/.ssh/config` shortcut belongs on the machine I connect *from*.
- **`ssh goodmedia` tried to log in as my WSL username** (`admingoodfella`) and got `Permission denied (publickey)`. The shortcut file wasn't being applied, so SSH used my local username. Fix: connect with the full command (`ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip>`) and check the config file with `cat ~/.ssh/config`.

## What I Learned
An SSH key pair has two parts: a private key, which stays on my computer, and a public key, which I place on the server.

A passphrase adds extra protection to the private key in case someone gets a copy of it.

Logging in with SSH keys is more secure than using passwords because attackers cannot try to guess the password over the network.

Before disabling password logins, I should first make sure key-based logins work correctly. Otherwise, I could lock myself out of the server.

The command sshd -t checks the SSH configuration for mistakes before applying changes.

The command sshd -T shows the settings SSH is actually using.

A reload applies new SSH settings without disconnecting users who are already logged in.

If I get the message "Permission denied (publickey)," it means the server expected an SSH key but did not receive a valid one.

Before running any command, I should confirm which computer I'm connected to. This helps prevent running commands on the wrong machine by mistake.

## Next

A firewall (UFW), then `fail2ban` and automatic security updates.
