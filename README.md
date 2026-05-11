# Wazuh SIEM & XDR Home Lab

A fully documented home lab deploying **Wazuh** as a SIEM/XDR platform to practice real-world SOC workflows: log ingestion, File Integrity Monitoring, custom detection rules, attack simulation, and incident response.

Built and tested at **ENSIAS, Rabat** (2025).

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VirtualBox                           │
│                                                             │
│  ┌──────────────────────┐    ┌───────────────────────────┐  │
│  │   Ubuntu Server 22   │    │      Windows 10           │  │
│  │   Wazuh Manager      │◄───│      Wazuh Agent          │  │
│  │   Wazuh Indexer      │    │   (endpoint monitoring)   │  │
│  │   Wazuh Dashboard    │    └───────────────────────────┘  │
│  │   (192.168.56.10)    │                                   │
│  └──────────┬───────────┘    ┌───────────────────────────┐  │
│             │                │      Ubuntu 22.04         │  │
│             └───────────────►│      Wazuh Agent          │  │
│                              │   (Linux endpoint)        │  │
│                              └───────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Components:**
- **Wazuh Manager** (Ubuntu Server 22.04) — central SIEM engine, receives and correlates all agent events
- **Wazuh Indexer** — OpenSearch-based data storage and search
- **Wazuh Dashboard** — web interface for alert visualization and threat hunting
- **Windows 10 Agent** — endpoint monitored for FIM, Windows event logs, registry changes
- **Ubuntu Agent** — endpoint monitored for syslog, auth.log, SSH events, FIM

---

## What This Lab Demonstrates

| Capability | Description |
|---|---|
| Log ingestion | Collecting events from Linux (syslog, auth.log) and Windows (Event Viewer) |
| File Integrity Monitoring (FIM) | Real-time detection of file creation, modification, deletion |
| Custom detection rules | Rules for SSH brute-force, privilege escalation, reverse shells |
| Attack simulation | Hydra SSH brute-force, Nmap scans, unauthorized file changes |
| Alert triage | Working with the Wazuh dashboard — filters, threat hunting, MITRE ATT&CK mapping |
| Incident response | Documenting alerts, building timelines, writing response reports |
| Active Response | Automatic IP blocking on SSH brute-force (firewall-drop) |

---

## Repository Structure

```
wazuh-siem-lab/
├── configs/
│   ├── manager/
│   │   └── ossec.conf              # Wazuh Manager main config
│   ├── agents/
│   │   ├── linux/
│   │   │   └── ossec.conf          # Linux agent config (FIM, log sources)
│   │   └── windows/
│   │       └── ossec.conf          # Windows agent config (FIM, registry)
├── rules/
│   ├── local_rules.xml             # All custom detection rules
│   └── README.md                   # Rule explanations and MITRE mapping
├── docs/
│   ├── 01_setup.md                 # Step-by-step installation guide
│   ├── 02_fim_configuration.md     # FIM setup and testing
│   ├── 03_attack_simulations.md    # Attack playbooks (SSH brute-force, Nmap, FIM)
│   ├── 04_alert_triage.md          # How to triage alerts in the dashboard
│   └── 05_incident_report.md       # Sample incident report
├── scripts/
│   ├── simulate_brute_force.sh     # SSH brute-force simulation script
│   └── simulate_fim_changes.sh     # FIM trigger simulation script
└── README.md
```

---

## Quick Start

### Prerequisites

- VirtualBox ≥ 6.1
- At least 8 GB RAM (Wazuh server needs ~4 GB)
- Ubuntu Server 22.04 ISO
- Windows 10 ISO (for the agent VM)

### 1 — Install Wazuh (All-in-one)

On the Ubuntu Server VM:

```bash
curl -sO https://packages.wazuh.com/4.10/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

Note the admin credentials printed at the end. Access the dashboard at `https://<server-ip>`.

### 2 — Apply manager configuration

```bash
sudo cp configs/manager/ossec.conf /var/ossec/etc/ossec.conf
sudo systemctl restart wazuh-manager
```

### 3 — Install and configure Linux agent

On the Ubuntu agent VM:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt-get update && sudo apt-get install wazuh-agent

# Configure and enroll
WAZUH_MANAGER="<manager-ip>" sudo /var/ossec/bin/agent-auth -m <manager-ip>
sudo cp configs/agents/linux/ossec.conf /var/ossec/etc/ossec.conf
sudo systemctl enable wazuh-agent && sudo systemctl start wazuh-agent
```

### 4 — Install custom detection rules

```bash
sudo cp rules/local_rules.xml /var/ossec/etc/rules/local_rules.xml
sudo /var/ossec/bin/wazuh-logtest  # verify rules load correctly
sudo systemctl restart wazuh-manager
```

### 5 — Simulate attacks and check alerts

```bash
# SSH brute-force simulation
bash scripts/simulate_brute_force.sh <target-ip>

# FIM simulation
bash scripts/simulate_fim_changes.sh
```

Then open the Wazuh Dashboard → **Threat Hunting** → filter by `rule.id:100001` (custom rules) or `MITRE ATT&CK technique`.

---

## Attack Simulations Covered

### SSH Brute-Force (MITRE T1110.001)
Simulated with Hydra. Wazuh detects via `auth.log` correlation — built-in rule 5712 fires after 8 failed attempts; custom rule 100001 fires faster (5 attempts in 60s) with a higher severity level.

### Nmap Port Scan (MITRE T1595, T1046)
Simulated with Nmap SYN scan. Detected via syslog anomaly + custom rule 100003.

### Unauthorized File Modification (MITRE T1565)
Monitored paths are modified directly. Wazuh FIM triggers rule 550/553 and custom rule 100004 for critical paths.

### Privilege Escalation — Unauthorized sudo (MITRE T1548.003)
Triggerd by a non-sudoer user attempting `sudo`. Custom rule 100002 fires immediately at level 12 (critical).

---

## Custom Rules Summary

See [`rules/local_rules.xml`](rules/local_rules.xml) and [`rules/README.md`](rules/README.md) for full details.

| Rule ID | Description | MITRE | Level |
|---|---|---|---|
| 100001 | SSH brute-force — 5 failures in 60s | T1110.001 | 10 |
| 100002 | Unauthorized sudo attempt | T1548.003 | 12 |
| 100003 | Nmap scan detected via syslog | T1595 | 8 |
| 100004 | Critical file modified (FIM) | T1565 | 10 |
| 100005 | New user account created | T1136.001 | 8 |
| 100006 | Suspicious process started (nc, netcat) | T1059 | 12 |

---

## Key Learnings

Working on this lab gave hands-on experience with:

- Deploying and managing a full SIEM stack from scratch
- Understanding how log sources (syslog, Windows Event Log, auth.log) are ingested and normalized
- Writing detection rules in Wazuh's XML rule format, tuning frequency thresholds, and mapping to MITRE ATT&CK
- The difference between alert noise (false positives from automated scanners) and true positives — and how to tune rules to reduce the former
- Building structured incident reports from SIEM alerts

---

## Resources

- [Wazuh Official Documentation](https://documentation.wazuh.com)
- [Wazuh Detection Rules Repository](https://github.com/wazuh/wazuh-ruleset)
- [InSDN Dataset](https://ieee-dataport.org/open-access/insdn-novel-sdn-intrusion-detection-dataset) (used in companion IDS project)
- [MITRE ATT&CK Framework](https://attack.mitre.org)

---

## Author

**Abdellahi Ahmed Zerough**  
Engineering student in Information Systems Security — ENSIAS, Rabat  
[GitHub](https://github.com/abdallahi34) · [LinkedIn](https://www.linkedin.com/in/abdellahi-ahmed-zerough/)
