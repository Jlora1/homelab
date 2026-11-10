# Lesson 21: A New SSH Key, and Key-Only Logins on Both Servers

**Date:** 2026-11-09
**Machines:** Windows gaming PC (new Ubuntu in WSL), Dell OptiPlex Tower (Proxmox host `pve`), HP EliteDesk (`goodmedia`)

## Goal

Start over with a clean terminal setup on my PC, with a new SSH key, GitHub working over SSH and a key backup, then let that key into both servers and make sure neither one accepts a password over SSH.

## Background

- An **SSH key pair** has a **private key** that stays on my PC and a **public key** that I give to servers and GitHub. A server lets me in if I can prove I hold the private key that matches a public key in its `~/.ssh/authorized_keys`.
- The key has a **passphrase**, so a stolen copy of the private key file isn't enough on its own.
- **keychain** remembers the unlocked key so I only type the passphrase once per session. Lesson 18 covers it.
- SSH settings can go in a small file in `/etc/ssh/sshd_config.d/`. The first value the server reads for a setting wins, so the order matters.
- Proxmox's **web page** login is separate from SSH. Turning off SSH passwords doesn't change how I log in on port 8006.

## What I Did

- Installed a fresh Ubuntu in WSL on the gaming PC (it needed a Windows restart), then made a new key with a passphrase.

```bash
ssh-keygen -t ed25519 -C "joel-wsl"
cat ~/.ssh/id_ed25519.pub      # the public half, safe to copy
```

- Added the public key to GitHub, then tested it, cloned the `homelab` repo, and told Git who I am (name, and GitHub's no-reply email).

```bash
ssh -T git@github.com
git clone git@github.com:Jlora1/homelab.git
git config --global user.name "Jlora1"
git config --global user.email "<my GitHub no-reply address>"
```

- Installed **keychain** and added one line to `~/.bashrc` so it loads the key when a terminal opens.
- Copied the key files to a backup folder on a drive I plugged in, so a reinstall doesn't lock me out again. <!-- TODO: confirm which drive this was and where the stick and the passphrase note are kept -->
- Put the new public key on the Tower with `ssh-copy-id` (one last password login), then confirmed I could log in with the key.
- Locked down SSH on the Tower with a drop-in file, checked it, and reloaded the service **while the first window stayed open**:

```bash
# on the Tower, as root
printf 'PasswordAuthentication no\nPermitRootLogin prohibit-password\n' > /etc/ssh/sshd_config.d/10-hardening.conf
sshd -t                                   # syntax check, prints nothing when fine
sshd -T | grep -E "^(passwordauthentication|permitrootlogin)"   # the settings the server will really use
systemctl reload ssh
```

- Tested from a **second** window: a normal key login worked, and a login with keys switched off was refused.

```bash
ssh root@192.168.1.178
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password root@192.168.1.178
```

- Went to the EliteDesk with a keyboard and monitor and added the new public key as a new line in `~/.ssh/authorized_keys` with `nano`, keeping the old key's line.
- Tested key login from the PC, and ran the "password only" test against the EliteDesk too.
- Added `Host` entries to `~/.ssh/config` so `ssh goodmedia` and `ssh pve` work.

Results worth noting:
- On the Tower, `sshd -T` showed `passwordauthentication no`. It showed `permitrootlogin without-password`, which is the older name for `prohibit-password`, so that is expected.
- The password-only test ended with **Permission denied (publickey)** on both servers, and neither asked for a password.
- `ssh goodmedia` and `ssh pve` both log in from the PC, and `exit` closes them cleanly.

## What Broke

- **I no longer had my old key.** The old WSL install and its private key were gone, so I had to make a new key and let it into every machine. The EliteDesk's `authorized_keys` still held the old key (comment `wsl-to-goodmedia`), and password logins were off, so the only way to add the new key was at its keyboard and monitor.
- **I pasted sample output as commands.** Lines such as `PermitRootLogin ...` that were meant to show what to expect got run as commands and answered `command not found`. Nothing was harmed, but it's easy to mistake for a real error.
- **I typed `cat` without a file name.** It sat waiting for input until I pressed **Ctrl+C**. The command needed `cat ~/.ssh/id_ed25519.pub`.
- **Some tests ran on the wrong machine.** A few commands went into a window that was still logged into a server, so the test was the server connecting to itself. That still tested the same SSH service, but I had to check which prompt I was on (`goodefella@...` is my PC, `root@pve` and `lzmula@goodmedia` are the servers).
- **My Git email had a leading space** the first time, which I fixed and checked again.

## How I Fixed It

- Made a new key and let it into GitHub, the Tower and the EliteDesk, and kept the old key's line on the EliteDesk until the new one was proven.
- Kept the first window open during the SSH change. If the second-window test had failed, I could have removed the drop-in file and reloaded from the open window.
- Checked the file and the live settings (`sshd -t`, `sshd -T`) before and after reloading.
- Read the prompt before running each command.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A key backup, plus the passphrase written down somewhere separate, is what keeps a reinstall from locking me out.
- Never change SSH settings with only one window open. Test the change from a second window first.
- `sshd -T` shows what the server will really use, which matters when several files set the same option.
- Turning off SSH passwords makes a lost key a real problem, so the key has to be backed up before it's needed.
- Check the prompt (`user@host`) before running a command, so I know which machine it affects.
- Public keys are safe to share. Private keys and passphrases never get pasted anywhere.

## Not Done Yet

- Confirm the backup drive and where the stick is kept, and write the passphrase down separately from it.
- Test a key login from outside the home network, over Tailscale.
- On the Tower: check that SATA is still **AHCI**, turn on **Intel Virtualization Technology**, set **AC Recovery** to **Power On**, and reserve `192.168.1.178` in the router.
- Install the 23 waiting updates on the EliteDesk.
- Update the lessons that say my old WSL was set up a different way.

## Next

Build a first practice VM on the Tower, back it up to `backup1`, and restore it to prove the backup works ([lesson 20](20-drive-health-and-backup-storage.md) set up the storage).
