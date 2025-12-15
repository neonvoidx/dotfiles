#!/bin/bash
echo "Testing configure_system tasks..."
getent passwd neonvoid | cut -d: -f7
echo "Current shell: ^"
ls -la /boot/limine/limine.conf 2>&1 | head -2
grep "cmdline:" /boot/limine/limine.conf 2>&1 | head -1
echo "---"
mount | grep /games
