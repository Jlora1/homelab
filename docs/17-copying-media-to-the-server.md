# Lesson 17: Copying My Own Media to the Server (scp) and Seeing It in Jellyfin

**Date:** 2026-11-01
**Machine:** Windows PC (WSL) copying to the HP EliteDesk 800 G3 Mini (server `goodmedia`)

## Goal

Move a video file from my PC to the server over SSH, make Jellyfin pick it up, play it, and check how the server handles a file the browser can't play directly.

## Background

- `scp` copies files over SSH, so it uses the same key and passphrase as logging in. Nothing new has to be opened on the firewall.
- The syntax is `scp <source> <user>@<server>:<destination>`. The part after the `:` is a path **on the server**.
- Files on my Windows drive appear in WSL under `/mnt/c/Users/<windows-account>/...`.
- Jellyfin only runs as a read-only viewer of `/srv/media` (the container mounts it with `:ro`), so the files have to be placed on the server by me, not by Jellyfin.

## What I Did

- Made a test text file and copied it to the server to prove `scp` works, then read it back and deleted it.
- Created a folder for the movie on the server and copied a real video into it.
- Removed an overlapping folder from the Jellyfin library settings and scanned the library.
- Fixed the file name and extension, rescanned, and played the movie.
- Read Jellyfin's Playback Info and the container log to see how it was being played.

```bash
# Text-file test (on WSL), then read it back from the server
echo "scp test" > ~/scp-test.txt
scp -i ~/.ssh/id_ed25519_goodmedia ~/scp-test.txt <server-user>@<server-ip>:/home/<server-user>/scp-test.txt
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip> "ls -l ~/scp-test.txt; cat ~/scp-test.txt"

# One folder per movie on the server, then copy the video into it
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip> "mkdir -p '/srv/media/movies/Movie Name (2008)'"
scp -i ~/.ssh/id_ed25519_goodmedia /mnt/c/Users/<windows-account>/Downloads/video.ogg "<server-user>@<server-ip>:/srv/media/movies/Movie Name (2008)/"

# Rename to a Jellyfin-friendly name and remove the executable bit
ssh -i ~/.ssh/id_ed25519_goodmedia <server-user>@<server-ip> "mv '/srv/media/movies/Movie Name (2008)/video.ogg' '/srv/media/movies/Movie Name (2008)/Movie Name (2008).ogv' && chmod 644 '/srv/media/movies/Movie Name (2008)/Movie Name (2008).ogv'"
```

Results worth noting:
- A 159 MB file copied in about a second at roughly 100 MB/s on the home network.
- The copy kept the file's ownership as the server user (uid 1000), the same user Jellyfin runs as, so Jellyfin can read it.
- Copying from a Windows drive marked the file executable (`-rwxrwxr-x`). It's harmless, but `chmod 644` tidies it.
- Jellyfin showed the movie under "Recently Added" with a poster after the rescan, and playback started.
- Playback Info said **Transcoding**, with these reasons: the container, the video codec (Theora) and the audio codec (Vorbis) aren't supported by the browser, and the video's bitrate exceeded the limit.
- The "bitrate exceeds the limit" reason came from the player's Quality setting (420 kbps), not the server. Setting Quality higher raised the target to 4.3 Mbps, and the transcode ran at about 28x real time with 0 dropped frames.
- The container log showed `-init_hw_device vaapi ... qsv` and `-codec:v h264_qsv`, so the H.264 encode used Intel Quick Sync. The Theora decode ran in software, which is expected because this chip has no hardware Theora decoder.
- The log also showed `IOException ... Read-only file system` when Jellyfin tried to save `folder.jpg` next to the movie. That's expected with a read-only mount, and Jellyfin saved the poster in its own `/config/metadata` folder instead.

## What Broke

- **Placeholders typed literally.** I typed `<file>`, `<your-windows-name>` and similar text exactly as shown. Angle brackets mean "replace this with the real thing".
- **First test file never turned up.** My first `scp` printed `100%`, but the file was not in my home folder or in `/tmp`, and `find / -name 'scp-test*'` on the server found nothing. I never found out where the first copy went, so I redid the test with the full destination path (`<user>@<ip>:/home/<user>/scp-test.txt`) and it worked. Lesson: always spell out the full destination, then verify on the server.
- **`Permission denied (publickey)` after three passphrase prompts.** I mistyped the key passphrase. Nothing shows on screen while typing a passphrase, so typos are easy. Typing slowly fixed it.
- **`scp: ... is not a regular file`.** The `.ogg` "file" in my Downloads folder was actually a folder (the zip had been extracted into a folder with the same name), so `scp` refused it. `ls -l` showed the `total` line and the real file inside it. Check with `ls -l` before copying.
- **Jellyfin ignored the movie.** I copied it as `.ogg`, and Jellyfin treats `.ogg` as an **audio** extension, so a Movies library skipped it. Renaming it to `.ogv` (video in the Ogg container) made it appear.
- **Overlapping library folders.** The Movies library had both `/media/movies` and a subfolder inside it. The first already covers the second, so I removed the subfolder entry to avoid double scanning.
- **Pasted a screenshot instead of the command output.** The screenshots didn't show whether the copy had finished, so I had to ask for the text output. Paste terminal output as text.

## How I Fixed It

- Redid the test with the full destination path and verified the file on the server with `ls -l` and `cat`.
- Used `ls -l` to find the real file inside the `.ogg` folder, and copied that.
- Renamed the file to `Movie Name (Year).ogv`, so the extension and the folder-per-movie name both match what Jellyfin expects, then rescanned the library.
- Raised the player's Quality setting to remove the bitrate cap.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- `scp` uses my SSH key, so I can copy files without opening any new ports. The path after the `:` is on the server.
- Always verify a copy on the destination machine instead of trusting the progress bar alone.
- A "file" that `scp` calls "not a regular file" is probably a folder.
- Jellyfin decides what a file is by its extension, and it likes one folder per movie named `Name (Year)`.
- "Transcoding" means the server converts the video for the player. Playback Info shows why, and the container log shows whether it used the Intel chip (`h264_qsv`).
- A quality limit in the player can force a lower bitrate even when the server could do more.
- A read-only mount protects my media from Jellyfin, and the "read-only file system" errors in the log are the price of that.

## Next

A bigger media drive for the library, with a mount and permissions that match what Jellyfin expects.
