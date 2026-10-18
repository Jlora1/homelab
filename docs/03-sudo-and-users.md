# Lesson 03: sudo and Users

**Date:** 2026-10-18
**Machine:** Ubuntu 26.04.1 LTS (WSL2) on Windows

## Goal

Understand how `sudo` works, how users and groups control who can do what, and how the sudoers rules are structured.

## What I Did

```bash
# Who am I, and what groups am I in?
whoami
id

# Regular user vs. root
ls /root            # Permission denied
sudo ls /root       # works after entering my password
sudo whoami         # prints: root

# Create a practice user and test it
sudo adduser labuser
id labuser
su - labuser
sudo ls /root       # refused: labuser is not in the sudo group
exit

# Give the user sudo, test again, then clean up
sudo usermod -aG sudo labuser
id labuser          # now lists the sudo group
su - labuser
sudo ls /root       # works
exit
sudo deluser --remove-home labuser

# Inspect the sudo rules
sudo -l
sudo --version
sudo ls -l /etc/sudoers /etc/sudoers.d
sudo cat /etc/sudoers
sudo cat /etc/sudoers.d/README
sudo visudo         # opened the editor, made no changes
sudo visudo -c      # syntax check: parsed OK
```

## What Broke

- **`usermod` failed twice.** The first time I typed a backtick instead of `-`, so the shell opened a `>` continuation prompt and I cancelled it with Ctrl+C. The second time I typed `udermod`, which gave "command not found." `id labuser` showed the `sudo` group had never been added. I retyped the command correctly and confirmed with `id`.
- **`cat /etc/sudoers` gave "Permission denied."** The file is `-r--r----- root root`, so a regular user has no access. It works with `sudo`.
- **`/ect/sudoers` gave "No such file or directory."** I mistyped `/etc`. Tab completion avoids this.
- **`sudo cat /etc/sudoers.d` gave "Is a directory."** That's a folder, so I list it with `ls` and read the files inside.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- `sudo` runs one command as root using my own password. On Ubuntu, being in the `sudo` group is what allows it.
- `id` shows my user ID, group ID, and every group I belong to.
- `usermod -aG` **appends** a group. Without `-a`, it would replace all of a user's groups.
- A sudoers rule reads as *who, where = (as whom) what*. The line `%sudo ALL=(ALL:ALL) ALL` means members of the `sudo` group may run any command as any user.
- `/etc/sudoers` should be edited with `visudo`, which checks syntax before saving so a typo can't lock me out. Local rules can go in files under `/etc/sudoers.d/`, and file names containing a `.` or ending in `~` are ignored.
- "No such file or directory" means the path is wrong. "Permission denied" means the path is right but I lack access.
- This Ubuntu uses **sudo-rs**, a Rust rewrite of sudo (version 0.2.13). The everyday commands work the same.
- Least privilege: give a user only the access they need, for example one service restart instead of full sudo.

## Next

Install Ubuntu Server on the HP EliteDesk and connect to it over SSH.
