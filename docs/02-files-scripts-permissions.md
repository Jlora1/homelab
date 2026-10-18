# Lesson 02: Files, Scripts, and Permissions

**Date:** 2026-10-16
**Machine:** Ubuntu (WSL) on Windows

## Goal

Get comfortable moving around and managing files in the terminal, edit files with nano, write a first bash script, and understand Linux file permissions.

## What I Did

- Practiced the core file commands: `mkdir` (make a folder), `cp` (copy), `mv` (move or rename), `rm` (remove), and `ls -l` (long listing with details).
- Learned to edit files in the terminal with `nano`.
- Wrote my first bash script and ran it, then moved it into a better place with `mv`. The script is saved in this repo as [`scripts/sysinfo.sh`](../scripts/sysinfo.sh). It prints a greeting, the date, uptime, disk space, and memory.
- Learned to read permissions in `ls -l` output (the `rwx` letters) and used `chmod +x` to make the script runnable.

```bash
ls -l                 # show permissions, owner, size, date
chmod +x sysinfo.sh   # make the script executable
./sysinfo.sh          # run it
```

## What Broke

Nothing major broke that I recorded. I'll note errors here as they happen.

## What I Learned

- `ls -l` shows three sets of permissions: for the **owner**, the **group**, and **others**. Each set can have `r` (read), `w` (write), and `x` (execute).
- A new script isn't executable by default. `chmod +x` adds the execute permission so I can run it with `./`.
- `rm` deletes permanently with no trash can, so I check the path before running it.
- A script starts with `#!/bin/bash` so the system knows which program should run it.

## Next

Sudo and users: how privileges work, why `sudo` exists, and how to create and manage user accounts and groups.
