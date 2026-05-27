---
name: Bug Report
about: Something isn't working — help us fix it
title: '[BUG] '
labels: bug
assignees: ''
---

## Describe the Bug
<!-- Clear description of what went wrong -->

## To Reproduce
Steps to reproduce:
1. Run `sudo bash wireguard-pro.sh`
2. Choose option ...
3. See error

## Expected Behavior
<!-- What should have happened? -->

## System Info
<!-- Run these commands and paste the output -->

**OS:**
```
cat /etc/os-release
```

**Kernel:**
```
uname -r
```

**WireGuard version:**
```
wg --version
```

**Cloud provider:** (AWS / GCP / Azure / Oracle / DigitalOcean / Hetzner / bare metal / other)

## Log Output
<!-- Paste from: cat /var/log/wireguard-pro.log -->
```

```

## WireGuard Status
<!-- Output of: sudo wg show -->
```

```

## iptables Rules
<!-- Output of: sudo iptables -L -n && sudo iptables -t nat -L -n -->
```

```

## Additional Context
<!-- Any other info that might help -->
