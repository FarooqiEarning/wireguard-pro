# Changelog

All notable changes to WireGuard Pro are documented here.
Format: [Semantic Versioning](https://semver.org)

---

## [3.1.0] - 2026-05-27 — Stability, Routing & Firewall Reliability Update

### Added

* Added `_verify_forward_accept()` helper to validate and repair FORWARD chain policy automatically
* Added `_verify_vpn_ip_routing()` for VPN IP/subnet route verification and self-ping testing
* Added persistent firewall restore system:

  * `/usr/local/sbin/wg-restore-rules.sh`
  * `wg-restore-rules.service`
* Added duplicate-safe policy routing logic
* Added IPv6 forwarding verification and auto-repair
* Added IPv6 TCP MSS clamping support
* Added explicit interface health monitoring in repair workflow
* Added fallback detection for any active non-loopback public interface
* Added optional installation of:

  * `dnsutils`
  * `bind-utils`
  * `bind-tools`
* Added runtime `rp_filter` re-application after WireGuard interface creation
* Added persistent `nf_conntrack` module loading via `/etc/modules-load.d/wireguard.conf`
* Added direct kernel-level INPUT accept rules for VPN UDP port as firewall backend fallback
* Added DNS validation fallback chain:

  * `dig`
  * `nslookup`
  * `nc`
  * `ping`

### Changed

* Version bumped from `3.0.0` → `3.1.0`
* `start_wireguard()` now:

  * Calls policy routing setup after every successful start path
  * Verifies VPN IP routing immediately after startup
* Manual fallback startup path now respects `${MTU}` instead of raw auto-detected MTU
* `fw_apply_nat()` now verifies FORWARD policy after applying rules
* `verify_internet_routing()` now:

  * Verifies IPv6 forwarding state
  * Re-checks FORWARD chain after firewall save/reload
* `run_verification()` now checks:

  * `rp_filter`
  * IPv6 forwarding
  * VPN interface health
  * VPN IP assignment
* `cmd_repair()` now:

  * Re-applies all new routing/firewall fixes
  * Re-validates interface health
  * Re-checks VPN routing state
* `write_server_config()` PostUp/PostDown rules are now fully idempotent
* `fw_open_udp()` now injects direct kernel INPUT rules even when using:

  * `ufw`
  * `firewalld`
* `_setup_policy_routing()` now prevents duplicate `ip rule` entries
* Removed broken IPv6 default-route injection from policy routing logic
* `apply_performance_profile()` now loads conntrack modules before sysctl tuning

### Fixed

#### Fix #1 — FORWARD Chain Policy Reliability

* Fixed cases where `ufw` or `firewalld` silently reverted FORWARD policy to DROP
* FORWARD chain policy is now actively verified and repaired after:

  * firewall reloads
  * NAT application
  * repair operations
  * routing verification

#### Fix #2 — Reverse Path Filtering

* Fixed `rp_filter` settings only being written to disk without immediate application
* `rp_filter=0` for `wg0` is now applied:

  * immediately
  * after interface creation
  * during PostUp
  * during repair

#### Fix #3 — PUBLIC_IFACE Detection Failure

* Fixed silent failures when automatic public interface detection returned empty
* Installer now hard-fails with a descriptive error instead of continuing with invalid routing

#### Fix #4 — MTU Override Ignored

* Fixed manual fallback startup path ignoring selected/profile MTU values
* Gaming profile MTU overrides now apply correctly in all startup paths

#### Fix #5 — Missing INPUT Rules for VPN Port

* Fixed scenarios where frontend firewalls removed UDP accept rules
* Direct `iptables/ip6tables INPUT` rules are now always installed as backup protection

#### Fix #6 — Incomplete IPv6 Forwarding

* Fixed missing IPv6 FORWARD accept rules
* IPv6 forwarding state is now:

  * validated
  * repaired
  * persisted
  * re-applied on startup

#### Fix #7 — nf_conntrack Sysctl Failures

* Fixed conntrack-related sysctl writes failing on fresh systems because modules were not loaded

#### Fix #8 — Firewall Persistence Across Reboots

* Fixed firewall rules disappearing after reboot on systems lacking `netfilter-persistent`
* Added universal systemd-based firewall restoration

#### Fix #9 — Missing Policy Routing

* Fixed policy routing not being applied consistently across startup paths
* Fixed duplicate `ip rule` creation
* Fixed incorrect IPv6 route injection

#### Fix #10 — DNS Validation Failures on Minimal Systems

* Fixed DNS validation failing when `dig` was unavailable
* Validation now gracefully falls back through multiple tools

#### Fix #11 — Non-Idempotent PostUp/PostDown Rules

* Fixed duplicate firewall rule insertion when restarting interfaces multiple times
* PostDown cleanup now safely ignores missing rules

#### Fix #12 — Missing Interface Health Verification

* Fixed lack of interface-state monitoring during repair operations
* Health checks now surface in verification output

#### Fix #13 — UDP Timeout / Conntrack Tuning

* Fixed conntrack timeout tuning silently failing due to unloaded modules

#### Fix #14 — Missing IPv6 MSS Clamping

* Fixed PMTU/MSS issues for IPv6 TCP traffic across WireGuard tunnels

#### Fix #15 — Missing VPN IP Route Validation

* Fixed cases where WireGuard interface existed but VPN subnet route was missing
* VPN IP assignment and route integrity are now actively validated

### Internal

* Improved startup reliability across:

  * systemd
  * wg-quick
  * manual fallback modes
* Improved repair engine coverage and recovery depth
* Expanded verification framework for kernel/network state validation
* Improved firewall backend interoperability
* Improved IPv6 consistency across all routing paths
* Enhanced startup recovery logic for degraded cloud environments

---

## [3.0.0] - 2024-01-01 — Initial Public Release

### Added

* Full installation wizard (Quick / Advanced / Auto modes)
* Gaming performance profile (CAKE/fq_codel, busy_poll, BBR, CPU perf governor)
* Streaming performance profile (large buffers, TCP pacing, fq qdisc)
* Balanced performance profile (fq_codel, BBR, sensible defaults)
* Auto-detection: OS, cloud provider, public IP, network interface, MTU
* Firewall abstraction layer (ufw / firewalld / nftables / iptables)
* Client database with persistent tracking (name, IP, pubkey, status)
* Hot-add clients — no VPN restart needed when adding peers
* Client revoke/re-enable (disable without deleting config)
* QR code generation displayed inline in terminal
* Status dashboard with live peer info and traffic stats
* Auto-repair engine with 4 fallback start methods
* Backup & restore (tar.gz archives)
* Script self-update via GitHub
* Full uninstall with automatic pre-uninstall backup
* AppArmor exception profile (avoids disabling AppArmor entirely)
* SELinux permissive mode for WireGuard
* Cloud-specific guidance (Oracle, AWS, GCP, Azure, DigitalOcean, Hetzner)
* IPv6 support (server detection + client tunnel option)
* Kill switch with DNS leak prevention
* PresharedKey on every peer (post-quantum resistant)
* RPS/RFS multi-core packet steering
* NIC queue tuning (GRO/GSO/TSO, ring buffers)
* fq_codel on both public interface and WireGuard interface
* CPU frequency governor → performance mode
* sysctl optimizations persisted in /etc/sysctl.d/
* IRQ balance via irqbalance
* Command-line flags: --auto, --status, --add-client, --backup, --repair, --uninstall, --update, --help
* GitHub Actions CI (ShellCheck + syntax validation)
* Supports 15+ Linux distros, 10+ cloud providers, 5 architectures

### Supported OS (initial release)

Ubuntu 18.04+, Debian 9+, CentOS 7/8/9, RHEL 8/9, Rocky Linux,
AlmaLinux, Fedora 30+, Arch Linux, Manjaro, Alpine 3.12+,
openSUSE Leap/Tumbleweed, Amazon Linux 2/2023, Raspberry Pi OS, Armbian

## [Unreleased]

* Web dashboard for client management
* Telegram/email notifications
* Multi-interface support
* Per-client bandwidth limits
