# Lesson 13: Jellyfin Media Server in Docker

**Date:** 2026-10-28
**Machine:** HP EliteDesk 800 G3 Mini (server `goodmedia`), watched from a Windows PC browser

## Goal

Run the Jellyfin media server as a Docker container with its settings and media stored outside the container, and use the CPU's built-in video engine (Intel Quick Sync) for transcoding.

## What I Did

- Confirmed the server has an Intel video device for hardware transcoding.
- Created folders for Jellyfin's settings and cache and for my media, and gave my user ownership.
- Wrote a Docker Compose file ([`configs/jellyfin/docker-compose.yml`](../configs/jellyfin/docker-compose.yml)), checked it, and started the container.
- Finished the Jellyfin setup wizard from my PC, added the media libraries, and turned on Intel QuickSync in the Playback settings.
- Tested the driver from inside the container, added a free test movie, forced a transcode, and checked the logs to see which engine did the work.

```bash
# 1. Is there a video device for transcoding?
ls -l /dev/dri

# 2. Folders for settings, cache, and media, owned by my user (ID 1000)
sudo mkdir -p /srv/jellyfin/config /srv/jellyfin/cache /srv/media/movies /srv/media/shows /srv/media/music
sudo chown -R 1000:1000 /srv/jellyfin /srv/media
ls -ln /srv /srv/media
getent group render            # numeric ID of the render group

# 3. Compose file, check it, start it
mkdir -p ~/jellyfin
nano ~/jellyfin/docker-compose.yml
cd ~/jellyfin
sudo docker compose config
sudo docker compose up -d
sudo docker compose ps

# 4. Is the Intel driver working inside the container?
sudo docker exec jellyfin /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128

# 5. Free test movie (Big Buck Bunny, CC-BY)
sudo apt install unzip
cd /tmp
curl -L -O https://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_720p_h264.mov.zip
unzip big_buck_bunny_720p_h264.mov.zip -d "/srv/media/movies/Big Buck Bunny (2008)"
rm /tmp/big_buck_bunny_720p_h264.mov.zip

# 6. After forcing a transcode: which engine was used?
f=$(ls -t /srv/jellyfin/config/log/FFmpeg.Transcode-*.log | head -1)
grep -m1 -oE -- "-hwaccel [a-z]+|h264_[a-z]+|libx264" "$f" | sort -u
```

How the Compose file is set up:
- `user: "1000:1000"` runs Jellyfin as my user, so it can read and write the folders I created.
- `group_add: "991"` and the `/dev/dri/renderD128` device give it access to the video engine.
- Settings (`/srv/jellyfin/config`) and cache are outside the container, so updating or replacing the container doesn't lose them.
- Media is mounted read-only (`:ro`), so Jellyfin can't change or delete my files.
- `restart: unless-stopped` brings it back after a reboot.

Results worth noting:
- `/dev/dri` had `card1` and `renderD128`. The render device belongs to the `render` group (ID 991 on this machine).
- `docker compose config` printed the file back with no errors, and `ps` showed `Up ... (healthy)` with port 8096 published.
- The driver test loaded the Intel `iHD` driver with no errors. It lists hardware decode and encode for H.264 and HEVC (including 10-bit), and decode for VP9, VC-1, VP8 and MPEG-2. There is no AV1 support, which is normal for a 7th-generation chip.
- Playback Info in the browser showed `Transcoding` (HLS stream). The original was a 720p H.264 file at 5.6 Mbps, and the reason listed was "The video's bitrate exceeds the limit", because I had chosen a very low quality.
- The transcode log showed `-hwaccel vaapi` (hardware decoding) and `h264_qsv` (Quick Sync encoding), not `libx264`. So **the Intel chip did the transcoding, not the CPU.**

## Security Notes

- Docker publishes ports in a way that **bypasses UFW**, so my firewall doesn't filter port 8096. The server is only reachable from my home network, which is acceptable here.
- **I must never forward port 8096 on the router.** Reaching Jellyfin from outside the house would need a VPN or a reverse proxy with HTTPS, which I haven't set up.
- The admin account has its own strong password, separate from the server's.
- Media is read-only inside the container.

## What Broke

- **The test movie download "worked" but was 146 bytes.** The file name in my link was missing `.zip`, so the site returned a short "not found" message that was saved under the movie's name. A file that small can't be a movie. I listed the folder with `curl ... | grep -o 'href="[^"]*"'` to see the real names, then downloaded the right file (398 MB). Always check the size of a download.
- **Two commands pasted together in the terminal.** One `mkdir` ran into the next command's text. Pasting one command at a time avoids that.
- **Docker installed in the wrong place** earlier (see lesson 12). The disk size in the installer output gave it away.
- **`sudo` password rejected** a few times before it was accepted.

## What I Learned

<!-- TODO: rewrite these in my own words. They are a first draft. -->

- A Compose file describes a whole service: image, ports, folders, devices, and restart behavior. It can be saved in Git and rebuilt anywhere.
- Keeping settings and media outside the container means I can update or recreate the container without losing anything.
- Permissions matter: the container runs as a specific user ID, and the folders must belong to that user.
- Hardware transcoding needs the video device passed into the container and the right group added. I can prove it works by testing the driver and reading the transcode log.
- Transcoding converts video on the fly when a device can't play the original or the bandwidth is limited. Direct play uses no transcoding.
- Docker's published ports bypass UFW, so the router is the real boundary. Never forward this port.

## Next

Reserve a fixed IP address for the server in the router, so the Jellyfin address never changes. Then add a bigger media drive and set up its mount and permissions.
