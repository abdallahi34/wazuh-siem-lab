#!/bin/bash
# simulate_brute_force.sh
# Simulates an SSH brute-force attack using Hydra to trigger Wazuh rules 100001 and 5712.
#
# Usage: bash simulate_brute_force.sh <target-ip> [username]
# Example: bash simulate_brute_force.sh 192.168.56.20 root
#
# WARNING: Run only in your own isolated lab environment.

TARGET_IP="${1:-192.168.56.20}"
USERNAME="${2:-root}"
WORDLIST="/tmp/lab_passwords.txt"

echo "[*] Wazuh Lab — SSH Brute-Force Simulation"
echo "[*] Target: $TARGET_IP | User: $USERNAME"
echo "[!] This should only be run in an isolated lab environment."
echo ""

# Check Hydra is installed
if ! command -v hydra &>/dev/null; then
    echo "[!] Hydra not found. Install with: sudo apt-get install -y hydra"
    exit 1
fi

# Create a small, obviously-wrong password list
cat > "$WORDLIST" << EOF
wrongpassword1
wrongpassword2
wrongpassword3
wrongpassword4
wrongpassword5
wrongpassword6
wrongpassword7
wrongpassword8
wrongpassword9
wrongpassword10
EOF

echo "[*] Password list created at $WORDLIST (10 wrong passwords)"
echo "[*] Starting Hydra — expect Wazuh rule 100001 to fire after 5 attempts..."
echo ""

# Run Hydra — 2 threads, verbose output
hydra -l "$USERNAME" -P "$WORDLIST" "ssh://$TARGET_IP" -t 2 -V -e nsr

echo ""
echo "[*] Simulation complete."
echo "[*] Check Wazuh Dashboard → Threat Hunting → filter: rule.id:100001"
echo "[*] The attacker IP should be blocked by active response for 600 seconds."

# Cleanup
rm -f "$WORDLIST"
