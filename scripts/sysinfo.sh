#!/bin/bash
# Shows basic info about this computer

echo "Hello, $USER"
echo "Today is $(date)"
echo "--- Uptime ---"
uptime -p
echo "--- Disk space ---"
df -h /
echo "--- Memory ---"
free -h
