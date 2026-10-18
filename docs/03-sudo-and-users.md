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
sudo lets me run a command with administrator privileges by using my own password. On Ubuntu, this works because my account belongs to the sudo group.
id shows information about my account, including my user ID (UID), primary group ID (GID), and all groups I am a member of.

usermod -aG adds a user to a group without removing their existing group memberships. The -a option is important because leaving it out can overwrite the user's current groups.

Sudo permissions follow a pattern of who can run what, where, and as whom. The rule %sudo ALL=(ALL:ALL) ALL gives members of the sudo group permission to run any command as any user.

The /etc/sudoers file controls sudo permissions and should be edited with visudo, which checks for syntax errors before saving. Additional custom rules can be stored in /etc/sudoers.d/.

If I see "No such file or directory," the path or filename is incorrect. If I see "Permission denied," the path exists but I do not have the required access rights.

My Ubuntu system uses sudo-rs, which is a Rust-based implementation of sudo. Even though the software is different, the commands I use day to day are the same.

The principle of least privilege means giving users only the permissions they need. For example, allowing someone to restart a specific service instead of giving them full administrative access.

## Next

Install Ubuntu Server on the HP EliteDesk and connect to it over SSH.
