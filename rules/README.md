# Custom Detection Rules — Reference

All rules live in `local_rules.xml` and extend Wazuh's built-in ruleset.
They are loaded **after** default rules to allow proper parent–child chaining.

## Why custom rules?

Wazuh ships with 3,000+ built-in rules. They are a strong foundation, but:

- Default SSH brute-force rule (5712) fires after **8 attempts in 2 min** — too slow for fast automated attacks
- There are no built-in rules for some org-specific patterns (reverse shells, specific critical files)
- Default severities don't always reflect actual risk in context — custom rules let you tune levels

## Rule ID Namespace

Custom IDs start at `100001` to avoid conflicts with Wazuh's built-in range (0–99999).

## Rules Summary

| Rule ID | Trigger | MITRE Tactic | MITRE Technique | Level | Active Response |
|---|---|---|---|---|---|
| 100001 | 5 SSH failures in 60s from same IP | Credential Access | T1110.001 | 10 | firewall-drop (600s) |
| 100002 | Non-sudoer user attempts sudo | Privilege Escalation | T1548.003 | 12 | — |
| 100003 | Nmap / port scan signature in syslog | Reconnaissance | T1595, T1046 | 8 | — |
| 100004 | /etc/passwd, /etc/shadow, /etc/sudoers modified | Impact | T1565.001 | 10 | — |
| 100005 | New user created via useradd/adduser | Persistence | T1136.001 | 8 | — |
| 100006 | Netcat / reverse shell process detected | Execution, C2 | T1059, T1071 | 12 | — |
| 100007 | 5 Windows failed logons in 60s from same IP | Credential Access | T1110.001 | 10 | — |
| 100008 | Windows Event 4720 (new user created) | Persistence | T1136.001 | 8 | — |
| 100009 | Windows Run registry key modified | Persistence | T1547.001 | 10 | — |

## Severity Scale (Wazuh)

| Level | Meaning |
|---|---|
| 0–3 | Informational |
| 4–7 | Low |
| 8–11 | Medium — investigate |
| 12–15 | Critical — immediate action |

## Testing Rules

Use `wazuh-logtest` to verify a rule fires on a simulated log line:

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Then paste a sample log. Example for rule 100001:

```
Oct 15 21:07:00 linux-agent sshd[29205]: Failed password for invalid user admin from 10.0.0.5 port 48928 ssh2
```

Paste it 5 times — rule 100001 should fire on the 5th occurrence.

## Adding New Rules

1. Open `/var/ossec/etc/rules/local_rules.xml`
2. Add your rule inside the `<group>` block
3. Test with `wazuh-logtest`
4. Restart: `sudo systemctl restart wazuh-manager`
5. Verify the rule appears in the dashboard under **Management → Rules**

## References

- [Wazuh Rule Syntax](https://documentation.wazuh.com/current/user-manual/ruleset/ruleset-xml-syntax/rules.html)
- [MITRE ATT&CK](https://attack.mitre.org)
- [Wazuh Built-in Rules](https://github.com/wazuh/wazuh-ruleset)
