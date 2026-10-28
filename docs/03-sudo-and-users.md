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
sudo lets me temporarily use administrator powers by entering my own password.

On Ubuntu, this works because my account is part of the sudo group.

The id command shows information about my account, including my user number and the groups I belong to.

usermod -aG adds a user to a group without removing any groups they already belong to.

The -a option is important because leaving it out can accidentally remove the user from their existing groups.

Sudo permissions determine who can run commands, which commands they can run, and which user they can act as.

A common rule gives members of the sudo group permission to run any command with administrator privileges.

The /etc/sudoers file controls sudo permissions.

It should be edited with visudo, which checks for mistakes before saving.

Extra permission rules can be stored in /etc/sudoers.d/.

If you see "No such file or directory," the file or path you entered is wrong or doesn't exist.

If you see "Permission denied," the file exists, but you don't have permission to access it.

My Ubuntu system uses sudo-rs, a newer version of sudo written in the Rust programming language.

Even though it's built differently, the commands I use every day stay the same.

The principle of least privilege means giving people only the access they need to do their job.

For example, someone might be allowed to restart a specific service without being given full administrator access.

## Next

Install Ubuntu Server on the HP EliteDesk and connect to it over SSH.
