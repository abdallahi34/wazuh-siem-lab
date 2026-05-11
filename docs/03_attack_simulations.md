# 03 — Attack Simulation Playbooks

All simulations run in the isolated VirtualBox lab. Never run these against systems you don't own.

---

## Simulation 1 — SSH Brute-Force (MITRE T1110.001)

**Goal:** Trigger rules 100001 and 5712 on the Linux agent.

**Tool:** Hydra (run from your host or an attacker VM)

```bash
# Install Hydra
sudo apt-get install -y hydra

# Create a small password list
echo -e "password\n123456\nadmin\nwelcome\nroot\ntest123\nletmein\nqwerty" > passwords.txt

# Launch brute-force against the Linux agent
# -l: username, -P: password list, -t: threads
sudo hydra -l root -P passwords.txt ssh://192.168.56.20 -t 4 -V
```

**Expected alerts in Wazuh dashboard:**
- Rule 5760 fires on each failure (level 5)
- Rule 100001 fires after 5 failures from same IP (level 10)
- Rule 5712 fires after 8 failures (level 10)
- Active response **firewall-drop** blocks the attacker IP for 600s

**Dashboard query:** `rule.id:100001 AND agent.name:linux-agent`

---

## Simulation 2 — Unauthorized sudo (MITRE T1548.003)

**Goal:** Trigger rule 100002 on the Linux agent.

```bash
# SSH into linux-agent as a non-root, non-sudo user
ssh testuser@192.168.56.20

# Try to run a privileged command
sudo cat /etc/shadow
# Expected output: testuser is not in the sudoers file. This incident will be reported.
```

**Expected alert:** Rule 100002, level 12 (critical)

**Dashboard query:** `rule.id:100002`

---

## Simulation 3 — Nmap Port Scan (MITRE T1595, T1046)

**Goal:** Trigger rule 100003.

```bash
# SYN scan (requires root)
sudo nmap -sS 192.168.56.20

# More aggressive scan
sudo nmap -A -T4 192.168.56.20
```

**Expected alert:** Rule 100003, level 8

---

## Simulation 4 — Unauthorized File Modification (MITRE T1565.001)

**Goal:** Trigger rule 100004 (critical file) and built-in FIM rules.

```bash
# SSH into linux-agent as root or sudo user
ssh root@192.168.56.20

# Modify a critical file (reversible change)
echo "# test modification" >> /etc/passwd

# Restore
sed -i '/# test modification/d' /etc/passwd
```

**Expected alerts:**
- Rule 550 (Integrity checksum changed) — level 7
- Rule 100004 (critical file modified) — level 10

**Dashboard:** Go to **File Integrity Monitoring** → filter by `path:/etc/passwd`

---

## Simulation 5 — New User Creation (MITRE T1136.001)

**Goal:** Trigger rule 100005.

```bash
# On linux-agent
sudo useradd -m testmalware

# Clean up
sudo userdel -r testmalware
```

**Expected alert:** Rule 100005, level 8

---

## Simulation 6 — Windows RDP Brute-Force (MITRE T1110.001)

**Goal:** Trigger rule 100007 on the Windows agent.

**Prerequisite:** Enable RDP on Windows 10 (Settings → Remote Desktop → Enable)

```bash
# From Kali or attacker VM
sudo hydra -l Administrator -P passwords.txt rdp://192.168.56.30 -t 2 -V
```

**Expected alert:** Rule 100007, level 10

---

## Reading the Results

After each simulation:

1. Open Wazuh Dashboard → **Threat Hunting**
2. Set time range to "Last 15 minutes"
3. Filter: `rule.id:<rule-id>` or `agent.name:<agent-name>`
4. Click an alert to see the full event JSON, including:
   - `rule.mitre.id` — MITRE technique
   - `data.srcip` — attacker IP
   - `agent.name` — affected endpoint
   - `rule.description` — human-readable alert

5. Document in an incident report (see `docs/05_incident_report.md`)
