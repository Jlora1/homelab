# Lesson 01: Git, SSH Keys, and GitHub

**Date:** 2026-10-15
**Machine:** Ubuntu (WSL) on Windows

## Goal

Install Git, set up SSH key authentication with GitHub, and push my first repository so my learning is saved and visible online.

## What I Did

```bash
# Install Git
sudo apt update && sudo apt install -y git

# Tell Git who I am
git config --global user.name "jlora1"
git config --global user.email "<my email>"

# Create an SSH key pair and show the PUBLIC key
ssh-keygen -t ed25519 -C "<my email>"
cat ~/.ssh/id_ed25519.pub

# (Public key added to my GitHub account under Settings > SSH keys)
# Test that GitHub accepts the key
ssh -T git@github.com

# Connect my local folder to a GitHub repo and push
cd ~/linux-journal
git remote add origin git@github.com:Jlora1/linux-journal.git
git add -A
git commit -m "Initial commit"
git branch -M main
git push -u origin main

# Check the result
git status
git log --oneline
```

## What Broke

- I typed `git -A && git commit`, but `-A` belongs to `git add`, not `git` itself. The correct command is `git add -A`.
- I mistyped `git log --online`. The flag is `--oneline`.

Both were typos. I retyped the correct commands right away.

## What I Learned

- An SSH key is a pair: a **private** key that never leaves my machine and a **public** key I give to GitHub. Only the `.pub` file gets shared.
- `ssh -T git@github.com` is a quick way to confirm the key works before trying to push.
- The basic Git flow is `add` (stage), `commit` (save a snapshot), `push` (send it to GitHub).
- `git push -u origin main` sets the default upstream, so later pushes are just `git push`.

## Next

Files, scripts, and permissions (Lesson 02).
