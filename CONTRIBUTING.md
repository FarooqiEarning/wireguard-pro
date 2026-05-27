# Contributing to WireGuard Pro

Thank you for helping improve WireGuard Pro for everyone! 🎉

WireGuard Pro aims to be a production-grade, self-healing, high-performance WireGuard deployment toolkit supporting multiple Linux distributions, cloud providers, and advanced networking environments.

We welcome contributions of all kinds — bug fixes, testing, documentation, performance improvements, and new features.

---

# Ways to Contribute

## 🐛 Bug Reports

Open an Issue with:

* Full reproduction steps
* Expected behavior
* Actual behavior
* Logs and verification output

## 🖥️ New OS / Distribution Support

Add:

* `_pkg_<distro>()` package installer
* detection logic
* firewall compatibility if needed

Main package logic lives in:

* **§8 Package Management**
* **§10 OS Detection**

## ⚡ Performance Tuning

Improve:

* sysctl tuning
* qdisc selection
* IRQ balancing
* NIC queue tuning
* conntrack sizing
* multi-core packet steering

Primary sections:

* **§13 Performance Profiles**
* **§14 Kernel & Sysctl Optimization**

## 🔐 Networking & Firewall Improvements

Areas of interest:

* nftables support
* IPv6 routing
* policy routing
* firewall persistence
* multi-interface routing
* cloud networking edge cases

Primary sections:

* **§16 Firewall Layer**
* **§17 NAT & Routing**
* **§18 WireGuard Runtime**

## 📚 Documentation

Help improve:

* README examples
* troubleshooting docs
* cloud-provider guides
* migration docs
* architecture diagrams

## 🧪 Testing

We especially need testing on:

* uncommon distros
* ARM devices
* VPS providers
* IPv6-only environments
* restrictive cloud firewalls

---

# Reporting Bugs

Please include ALL of the following:

## System Information

```bash
cat /etc/os-release
uname -r
```

## Cloud Provider

Examples:

* AWS
* Oracle Cloud
* Azure
* GCP
* Hetzner
* DigitalOcean
* Bare Metal

## Logs

```bash
cat /var/log/wireguard-pro.log
```

## Networking State

```bash
sudo wg show
sudo iptables -L -n
sudo ip rule show
sudo ip route show table all
```

## Verification Output

```bash
sudo wireguard-pro --status
sudo wireguard-pro --repair
```

## Describe

* What happened
* What you expected
* Whether rebooting changes the issue
* Whether the issue is reproducible

---

# Pull Request Guidelines

## 1. Fork & Branch

```bash
git checkout -b feature/my-feature
```

## 2. Keep Functions Organized

All functions belong in the correct numbered section (`§`).

Avoid adding logic in random locations.

## 3. Test Before Submitting

Minimum required:

* Ubuntu 22.04+
* Rocky Linux / CentOS 9

Preferred:

* Debian
* Fedora
* Arch
* Alpine

## 4. Syntax Validation

```bash
bash -n wireguard-pro.sh
```

Must pass cleanly.

## 5. ShellCheck

```bash
shellcheck wireguard-pro.sh
```

Fix warnings whenever possible.

## 6. Verify Repair Logic

Test:

```bash
wireguard-pro --repair
```

The repair system must remain idempotent and safe to run repeatedly.

## 7. Update Version If Needed

If your PR changes:

* features
* architecture
* behavior
* networking logic

Update:

```bash
VER="x.x.x"
```

Also update:

* `CHANGELOG.md`
* migration notes if applicable

## 8. Explain Your Changes

Describe:

* what changed
* why it changed
* edge cases handled
* rollback considerations

---

# Development Principles

WireGuard Pro prioritizes:

* Reliability over cleverness
* Idempotent networking operations
* Cross-distro compatibility
* Self-healing recovery behavior
* Safe fallback paths
* Minimal external dependencies

---

# Code Style

## Shell Standards

* Use `printf` instead of `echo -e`
* Always quote variables:

```bash
"$var"
```

* Use:

```bash
local var
```

inside functions

* Use:

```bash
|| true
```

for non-critical cleanup commands

## Idempotency

Firewall/networking logic MUST be safely repeatable.

Prefer:

```bash
iptables -C ... || iptables -A ...
```

Avoid duplicate rules.

## Error Handling

Critical failures must:

```bash
die "message"
```

Never silently continue after fatal networking failures.

## Logging

Use centralized logging helpers.

All recovery actions should produce logs.

---

# Networking Rules

## Policy Routing

Never:

* override global default routes
* hijack server IPv6 traffic
* assume a single routing table

Always:

* check before adding `ip rule`
* validate routes after applying

## Firewall Changes

All firewall operations must support:

* iptables
* nftables
* ufw
* firewalld

Kernel-level fallback rules are preferred for critical VPN access.

## IPv6

Any new networking feature MUST consider:

* IPv4
* IPv6
* dual-stack environments

---

# Testing Checklist

Before submitting a PR, verify:

## Installation

* [ ] Fresh install works on Ubuntu 22.04+
* [ ] Fresh install works on Rocky/CentOS 9
* [ ] Installer succeeds non-interactively with `--auto`

## WireGuard Runtime

* [ ] Interface starts correctly
* [ ] MTU applies correctly
* [ ] Clients connect successfully
* [ ] Hot-add client works without restart
* [ ] Client revoke/re-enable works

## Routing & Firewall

* [ ] NAT rules persist after reboot
* [ ] FORWARD chain remains ACCEPT
* [ ] Policy routing survives restart
* [ ] IPv6 forwarding works
* [ ] rp_filter values apply correctly

## Repair & Recovery

* [ ] `--repair` fixes broken firewall state
* [ ] `--repair` fixes missing routes
* [ ] `--repair` safely runs multiple times

## Backup & Restore

* [ ] Backup archive restores successfully
* [ ] Restore preserves client database

## Validation

* [ ] `bash -n wireguard-pro.sh` passes
* [ ] `shellcheck` passes or warnings justified

---

# Feature Ideas

## Planned

* [ ] Web dashboard for client management
* [ ] Telegram/email notifications
* [ ] Multi-interface support (`wg0`, `wg1`, `wg2`)
* [ ] Per-client bandwidth limits
* [ ] Client expiry / auto-revoke
* [ ] Prometheus metrics exporter
* [ ] REST API
* [ ] Automatic Let's Encrypt DNS integration
* [ ] IPv6-only server mode
* [ ] Clustered/high-availability WireGuard
* [ ] Smart roaming optimization
* [ ] eBPF/XDP acceleration

## Experimental

* [ ] WireGuard over TCP
* [ ] QUIC tunneling mode
* [ ] Dynamic endpoint failover
* [ ] Multi-path routing
* [ ] FreeBSD support
* [ ] macOS server support

---

# Security Guidelines

Please DO NOT publicly disclose:

* private keys
* preshared keys
* client configs
* internal IP ranges
* production firewall rules

If reporting a security issue:

* open a private security advisory if possible
* avoid posting sensitive configs publicly

---

# Questions?

Open:

* a GitHub Issue
* a Discussion
* or a Pull Request draft

We're friendly and happy to help. 😊