# 05 — Sample Incident Report

**Incident ID:** IR-2025-001  
**Date:** 2025-10-15  
**Analyst:** Abdellahi Ahmed Zerough  
**Severity:** High  
**Status:** Resolved

---

## Executive Summary

An SSH brute-force attack was detected against the Linux endpoint (`linux-agent`, 192.168.56.20) at 21:07 UTC. The attack originated from IP `10.0.0.5` and attempted 23 failed login attempts over approximately 90 seconds. The attacker's IP was automatically blocked by Wazuh's active response module. No successful authentication was recorded.

---

## Timeline

| Time (UTC) | Event | Rule | Level |
|---|---|---|---|
| 21:07:00 | First failed SSH login from 10.0.0.5 | 5760 | 5 |
| 21:07:08 | 5th failed login — brute-force threshold reached | 100001 | 10 |
| 21:07:08 | Active response triggered — IP blocked via iptables | 651 | — |
| 21:07:22 | 8th failed login — built-in brute-force rule fires | 5712 | 10 |
| 21:08:30 | Attack stops (IP blocked, no further attempts) | — | — |

---

## Detection Details

**Alert (Rule 100001):**
```json
{
  "rule": {
    "id": "100001",
    "level": 10,
    "description": "SSH brute-force attempt: 5 failed logins from same IP in 60 seconds",
    "mitre": { "id": ["T1110.001"], "tactic": ["Credential Access"] }
  },
  "agent": { "name": "linux-agent", "ip": "192.168.56.20" },
  "data": {
    "srcip": "10.0.0.5",
    "dstuser": "root"
  },
  "timestamp": "2025-10-15T21:07:08.412Z"
}
```

---

## Affected Assets

| Asset | IP | Role | Impact |
|---|---|---|---|
| linux-agent | 192.168.56.20 | Linux endpoint | Targeted — no compromise |

---

## Attack Analysis

- **Technique:** T1110.001 — Brute Force: Password Guessing
- **Tool:** Hydra (inferred from packet timing and user-agent patterns)
- **Targeted account:** root
- **Passwords tried:** Common wordlist entries (password, 123456, admin, etc.)
- **Success:** No — all authentication attempts failed
- **Attacker IP:** 10.0.0.5 (internal test VM in lab environment)

---

## Response Actions Taken

1. **Automatic (Active Response):** Wazuh `firewall-drop` blocked `10.0.0.5` via iptables for 600 seconds
2. **Manual:** Verified no successful logon in auth.log after the block (`grep "Accepted" /var/log/auth.log`)
3. **Verification:** Confirmed IP block active: `sudo iptables -L INPUT -n | grep 10.0.0.5`

---

## Recommendations

1. **Harden SSH:** Disable password authentication — enforce SSH key-based login only
   ```bash
   # /etc/ssh/sshd_config
   PasswordAuthentication no
   PermitRootLogin no
   ```
2. **Rate limiting:** Install `fail2ban` as a complementary layer with persistent banning
3. **MFA:** Consider enabling TOTP-based MFA for SSH via `pam_google_authenticator`
4. **Alert tuning:** Lower brute-force threshold to 3 attempts if SSH is not used by automated scripts

---

## Lessons Learned

- Active response successfully blocked the attacker before any successful authentication
- Custom rule 100001 (5 attempts / 60s) fired before built-in rule 5712 (8 attempts / 120s), improving detection speed by ~14 seconds in this simulation
- The `root` account being targeted is a reminder that `PermitRootLogin` should be disabled

---

*Report generated for portfolio/lab documentation purposes — all IPs are internal VirtualBox lab addresses.*
