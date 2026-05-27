# Changelog

All notable changes to WireGuard Pro are documented here.
Format: [Semantic Versioning](https://semver.org)

## [3.0.0] - 2024-01-01 — Initial Public Release

### Added
- Full installation wizard (Quick / Advanced / Auto modes)
- Gaming performance profile (CAKE/fq_codel, busy_poll, BBR, CPU perf governor)
- Streaming performance profile (large buffers, TCP pacing, fq qdisc)
- Balanced performance profile (fq_codel, BBR, sensible defaults)
- Auto-detection: OS, cloud provider, public IP, network interface, MTU
- Firewall abstraction layer (ufw / firewalld / nftables / iptables)
- Client database with persistent tracking (name, IP, pubkey, status)
- Hot-add clients — no VPN restart needed when adding peers
- Client revoke/re-enable (disable without deleting config)
- QR code generation displayed inline in terminal
- Status dashboard with live peer info and traffic stats
- Auto-repair engine with 4 fallback start methods
- Backup & restore (tar.gz archives)
- Script self-update via GitHub
- Full uninstall with automatic pre-uninstall backup
- AppArmor exception profile (avoids disabling AppArmor entirely)
- SELinux permissive mode for WireGuard
- Cloud-specific guidance (Oracle, AWS, GCP, Azure, DigitalOcean, Hetzner)
- IPv6 support (server detection + client tunnel option)
- Kill switch with DNS leak prevention
- PresharedKey on every peer (post-quantum resistant)
- RPS/RFS multi-core packet steering
- NIC queue tuning (GRO/GSO/TSO, ring buffers)
- fq_codel on both public interface and WireGuard interface
- CPU frequency governor → performance mode
- sysctl optimizations persisted in /etc/sysctl.d/
- IRQ balance via irqbalance
- Command-line flags: --auto, --status, --add-client, --backup, --repair, --uninstall, --update, --help
- GitHub Actions CI (ShellCheck + syntax validation)
- Supports 15+ Linux distros, 10+ cloud providers, 5 architectures

### Supported OS (initial release)
Ubuntu 18.04+, Debian 9+, CentOS 7/8/9, RHEL 8/9, Rocky Linux,
AlmaLinux, Fedora 30+, Arch Linux, Manjaro, Alpine 3.12+,
openSUSE Leap/Tumbleweed, Amazon Linux 2/2023, Raspberry Pi OS, Armbian

## [Unreleased]
- Web dashboard for client management
- Telegram/email notifications
- Multi-interface support
- Per-client bandwidth limits
