#!/bin/bash
# simulate_fim_changes.sh
# Simulates file modification events to trigger Wazuh FIM rules (550, 553, 100004).
# Run this ON the Linux agent VM (not the manager).
#
# Usage: sudo bash simulate_fim_changes.sh
#
# WARNING: Run only in your own isolated lab environment.
# This script reverts all changes it makes.

echo "[*] Wazuh Lab — FIM Simulation"
echo "[*] This script creates, modifies, and deletes files in monitored paths."
echo "[!] Run as root or with sudo. All changes will be reverted."
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run as root: sudo bash simulate_fim_changes.sh"
    exit 1
fi

TIMESTAMP=$(date +%s)

# -----------------------------------------------
# Test 1: Create new file in /etc (FIM realtime)
# -----------------------------------------------
echo "[1/4] Creating new file in /etc → expects FIM rule 554 (file added)"
echo "# lab-test-$TIMESTAMP" > /etc/lab_test_$TIMESTAMP.conf
sleep 3

# -----------------------------------------------
# Test 2: Modify the new file
# -----------------------------------------------
echo "[2/4] Modifying file → expects FIM rule 550 (checksum changed)"
echo "# modified" >> /etc/lab_test_$TIMESTAMP.conf
sleep 3

# -----------------------------------------------
# Test 3: Modify /etc/passwd (triggers rule 100004)
# -----------------------------------------------
echo "[3/4] Adding comment to /etc/passwd → expects rule 100004 (critical file)"
echo "# lab-test-comment-$TIMESTAMP" >> /etc/passwd
sleep 3

# Revert /etc/passwd immediately
sed -i "/# lab-test-comment-$TIMESTAMP/d" /etc/passwd
echo "       → /etc/passwd reverted"

# -----------------------------------------------
# Test 4: Delete the test file
# -----------------------------------------------
echo "[4/4] Deleting test file → expects FIM rule 553 (file deleted)"
rm -f /etc/lab_test_$TIMESTAMP.conf
sleep 2

echo ""
echo "[*] Simulation complete. Expected alerts:"
echo "    - Rule 554: New file created (/etc/lab_test_$TIMESTAMP.conf)"
echo "    - Rule 550: File modified"
echo "    - Rule 100004: Critical file modified (/etc/passwd)"
echo "    - Rule 553: File deleted"
echo ""
echo "[*] Check Wazuh Dashboard → File Integrity Monitoring"
echo "    Filter: agent.name:linux-agent AND rule.groups:syscheck"
