# Lesson 18: ssh-agent, keychain and an SSH Shortcut

**Date:** 2026-11-01
**Machine:** Windows PC (WSL), connecting to the server `goodmedia` over Tailscale

## Goal

Stop retyping my key passphrase for every `ssh` and `scp` command, change the passphrase, and replace the long login command with `ssh goodmedia`.

## Background

- My SSH key is protected by a passphrase (lesson 05). That is good protection, but with no helper, every `ssh` and `scp` asks for it again.
- `ssh-agent` is a small program that holds the unlocked key in memory for my session, so `ssh` and `scp` can ask it for the key instead of asking me.
- `keychain` is a helper that starts one agent and shares it between all my WSL terminal windows, so I type the passphrase once each time WSL starts.
- `~/.ssh/config` on the machine I connect **from** can store a short name for a server, with its address, user and key.

## What I Did

- Changed the key's passphrase, because I had typed a secret into a chat window by mistake (see What Broke).
- Started an agent in one terminal and loaded the key, and tested that `ssh` no longer asked.
- Installed `keychain` and added one line to `~/.bashrc` so every new WSL window shares one agent.
- Created `~/.ssh/config` with an entry for the server, using its Tailscale address so the shortcut works from home and away.

```bash
# Change the passphrase on the private key (type passphrases only at the terminal prompt)
ssh-keygen -p -f ~/.ssh/id_ed25519_goodmedia

# One-terminal version: start an agent and load the key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_goodmedia
ssh <server-user>@<server-tailscale-ip> "echo agent works"

# Every-terminal version: keychain (run the echo line only once)
sudo apt install -y keychain
echo 'eval "$(keychain --eval --quiet id_ed25519_goodmedia)"' >> ~/.bashrc

# The shortcut (on WSL, the machine I connect from)
cat >> ~/.ssh/config <<'EOF'

Host goodmedia
    HostName <server-tailscale-ip>
    User <server-user>
    IdentityFile ~/.ssh/id_ed25519_goodmedia
EOF
chmod 600 ~/.ssh/config
ssh goodmedia "echo shortcut works"
```

Results worth noting:
- `ssh-add` printed `Identity added`, and the next `ssh` ran without asking for a passphrase.
- The `ssh` command worked without the `-i` flag, because it asks the agent for the key.
- In a new WSL window, `keychain` asked for the passphrase once, and after that `ssh` worked with no prompt.
- `ssh goodmedia` ran twice with no prompts and no flags.
- `~/.ssh/config` did not exist yet on WSL, so I checked with `cat` first before adding to it. Appending with `>>` is safer than overwriting if the file already holds other settings (like GitHub).

## What Broke

- **I typed a secret into a chat window.** Anything that leaves the terminal, such as a chat, a screenshot or a commit, should be treated as exposed. I changed the passphrase afterwards with `ssh-keygen -p`.
- **Ran `ssh-keygen -p` twice by accident.** The first run changed the passphrase. The second asked for the old passphrase, and I gave it nothing, so it did nothing. Read the prompt before pressing Enter.
- **A screenshot of the Windows Game Bar instead of the terminal.** I'd pressed `Win+G` by accident. Closing it with Esc fixed it. To capture a window, use `Win+Shift+S`, or paste the terminal text.
- **The shortcut from lesson 05 never worked.** The file was created on the server instead of WSL, so `ssh goodmedia` tried my WSL username. The config file belongs on the machine I connect *from*, and it needs the `User` line.

## How I Fixed It

- Created the config on WSL (the client), with `HostName`, `User` and `IdentityFile`, and set it to mode 600.
- Used the Tailscale address as `HostName` so the same shortcut works wherever I am.
- Loaded the key once per WSL start with `keychain`, instead of once per command.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A passphrase protects the key file on disk. An agent holds the unlocked key in memory so I only unlock it once. Anyone who can use my open terminal session could use the loaded key, so I close sessions, or run `ssh-add -D` to unload it, when I'm done.
- `ssh-keygen -p` changes a key's passphrase without changing the key, so nothing on the server has to change.
- If I forget the passphrase the key is useless, and since password login is off I'd need a keyboard and monitor on the server to add a new key.
- `~/.ssh/config` lives on the machine I connect from, and a `Host` entry can hold the address, user and key.
- Use `>>` to add to a file and `>` only when I mean to replace it, and look at the file first.
- Passwords and passphrases only go into the terminal prompt that asks for them.

## Next

The media drive: check the EliteDesk's drive slots, then add and mount it for the media library.
