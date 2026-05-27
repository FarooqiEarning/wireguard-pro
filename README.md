# WireGuard Pro — World's Best VPN Installer & Manager

<p align="center">
  <img src="https://img.shields.io/badge/version-3.1.0-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/bash-4.0%2B-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/WireGuard-ready-purple?style=for-the-badge" />
</p>

<p align="center">
  <strong>One command. Any Linux. Any Cloud. Full lifecycle management.</strong><br>
  Gaming · Streaming · Daily Use · Enterprise
</p>

---

## ⚡ One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/FarooqiEarning/wireguard-pro/main/wireguard-pro.sh -o wireguard-pro.sh && sudo bash wireguard-pro.sh
```

Or with wget:
```bash
wget -qO wireguard-pro.sh https://raw.githubusercontent.com/FarooqiEarning/wireguard-pro/main/wireguard-pro.sh && sudo bash wireguard-pro.sh
```

---

## ✨ Features

### 🚀 Smart Installation
- **3 modes**: Quick (5 questions) · Advanced (full control) · Auto (zero interaction)
- **Auto-detects**: OS, cloud provider, public IP, network interface, optimal MTU
- **Auto-repair engine**: fixes port conflicts, stale interfaces, iptables errors automatically
- **4 fallback methods** to start WireGuard if the first attempt fails

### 🎮 Performance Profiles
| Profile | Best For | MTU | Keepalive | QDisc | Extra |
|---------|----------|-----|-----------|-------|-------|
| **Gaming** | FPS, MMO, low-latency | 1280 | 15s | CAKE/fq_codel | busy_poll, CPU perf mode |
| **Streaming** | 4K/8K video, large transfers | 1420 | 25s | fq | TCP pacing |
| **Balanced** | Daily use, mixed workloads | Auto | 25s | fq_codel | All-round optimized |

All profiles enable:
- **BBR** congestion control (Google's algorithm, dramatically reduces latency)
- **fq_codel / CAKE** AQM (eliminates bufferbloat — the #1 cause of gaming lag)
- **RPS/RFS** multi-core packet steering
- **IRQ affinity** via irqbalance
- Large UDP/TCP buffers for WireGuard's UDP transport
- NIC queue tuning (GRO/GSO/TSO)

### 🛡️ Security
- **PresharedKey** for every peer (post-quantum resistant layer)
- **Kill switch** option (blocks all traffic if VPN drops)
- **DNS leak prevention** built into kill-switch mode
- AppArmor & SELinux handled automatically
- All configs chmod 600, directory chmod 700
- Keys never exposed in logs or terminal output

### 🔧 Full Lifecycle Management
After installation, re-run the script to get the management menu:

```
[1]  Add Client              Generate new VPN config + QR code
[2]  Remove Client           Permanently delete a client
[3]  Revoke / Re-enable      Disable a client without deleting
[4]  List Clients            Show all clients + status
[5]  Show Config / QR Code   Display config & QR for mobile
[6]  Status Dashboard        Live peers, traffic, system stats
[7]  Repair & Restart        Fix common issues, re-apply rules
[8]  Backup Configs          Save all configs to archive
[9]  Restore Backup          Restore from a previous backup
[10] Update Script           Check for and apply updates
[11] Uninstall WireGuard     Remove everything (backup first)
```

### 🌍 Universal Compatibility

**Operating Systems:**
| Family | Distros |
|--------|---------|
| Debian/Ubuntu | Ubuntu 18.04+, Debian 9+, Raspberry Pi OS, Kali, Parrot, Pop!_OS, Linux Mint, Zorin, Elementary |
| RHEL/CentOS | CentOS 7/8/9, RHEL 8/9, Rocky Linux, AlmaLinux, Oracle Linux, Amazon Linux 2/2023 |
| Fedora | Fedora 30+, Nobara, Ultramarine |
| Arch | Arch Linux, Manjaro, EndeavourOS, Garuda, CachyOS |
| Alpine | Alpine 3.12+ |
| openSUSE | openSUSE Leap, Tumbleweed, SLES |
| ARM | Raspberry Pi OS, Armbian, any ARM distro |

**Architectures:** `x86_64` · `arm64/aarch64` · `armv7` · `armv6` · `riscv64`

**Cloud Providers** (auto-detected, firewall guidance provided):
`AWS` · `GCP` · `Azure` · `Oracle Cloud` · `DigitalOcean` · `Hetzner` · `Vultr` · `Linode` · `OVH` · `Contabo`

**Firewall Backends** (auto-detected):
`ufw` · `firewalld` · `nftables` · `iptables`

---

## 📋 Requirements

- Linux server (VPS, bare metal, or VM)
- Root / sudo access
- Internet connectivity
- Bash 4.0+
- Kernel 5.6+ recommended (WireGuard built-in); older kernels use DKMS automatically

---

## 🎯 Usage

### Interactive (recommended)
```bash
sudo bash wireguard-pro.sh
```

### Fully Automatic (zero questions)
```bash
sudo bash wireguard-pro.sh --auto
```

### Direct Commands
```bash
sudo bash wireguard-pro.sh --status       # Status dashboard
sudo bash wireguard-pro.sh --add-client   # Add a new client
sudo bash wireguard-pro.sh --backup       # Backup configs
sudo bash wireguard-pro.sh --repair       # Fix & restart WireGuard
sudo bash wireguard-pro.sh --uninstall    # Remove everything
sudo bash wireguard-pro.sh --help         # Show help
```

---

## 📱 Adding a Client (Example)

```
◈ Add New Client
  ▶  Client name: iPhone
  ▶  DNS: 1.1.1.1, 1.0.0.1
  ▶  Routing: Full tunnel
  ▶  Kill switch: No

  ✔  Keys generated for iPhone
  ✔  Client config: /root/wireguard-clients/iPhone.conf
  ✔  Peer hot-added to running WireGuard (no restart needed)

  [QR Code displayed here — scan with WireGuard app]

  Transfer to device:
    scp root@SERVER:/root/wireguard-clients/iPhone.conf ./iPhone.conf
```

**Clients are hot-added** — no VPN restart needed, existing connections stay up.

---

## 🌐 Client Apps

| Platform | App | Link |
|----------|-----|------|
| Windows | WireGuard for Windows | [wireguard.com/install](https://www.wireguard.com/install/) |
| macOS | WireGuard for macOS | App Store |
| iOS/iPadOS | WireGuard | App Store |
| Android | WireGuard | Google Play |
| Linux | `wg-quick` (built-in) | `sudo apt install wireguard` |

**Import options:**
1. Scan the QR code in the WireGuard app
2. Import the `.conf` file directly
3. Copy-paste the config contents

---

## ⚙️ What Gets Optimized

The script applies dozens of optimizations automatically:

```
Kernel settings (sysctl):
  net.ipv4.ip_forward = 1               ← Required for VPN routing
  net.core.default_qdisc = fq_codel     ← Eliminates bufferbloat
  net.ipv4.tcp_congestion_control = bbr ← Google BBR (lower latency)
  net.core.rmem_max = 134217728         ← Large buffers for throughput
  net.ipv4.udp_rmem_min = 16384         ← WireGuard UDP buffers
  net.ipv4.tcp_fastopen = 3             ← Faster connection setup
  net.ipv4.tcp_mtu_probing = 1          ← Optimal packet sizing
  [+ 25 more optimizations]

Network interface:
  NIC queue tuning (multi-queue)
  RPS/RFS multi-core steering
  GRO/GSO/TSO enabled
  fq_codel on public interface

Gaming profile extras:
  net.core.busy_poll = 50               ← Sub-millisecond latency
  CPU governor → performance
  CAKE qdisc (if available)
```

---

## 🔒 Security Notes

- WireGuard uses **ChaCha20-Poly1305** encryption (fast + secure)
- Each peer has a unique **PresharedKey** for extra security
- **Kill switch** prevents IP leaks if the VPN connection drops
- Configs are stored with strict permissions (`chmod 600`)
- The script never logs private keys

---

## ☁️ Cloud Firewall — IMPORTANT

After installation, you **must open the UDP port** in your cloud provider's firewall:

| Provider | Where to Open Port |
|----------|-------------------|
| **Oracle Cloud** | Networking → VCN → Security Lists → Ingress Rules |
| **AWS** | EC2 → Security Groups → Inbound Rules |
| **GCP** | VPC Network → Firewall → Create Rule |
| **Azure** | NSG → Inbound Security Rules |
| **DigitalOcean** | Droplet → Networking → Firewalls |
| **Hetzner** | Firewall → Add Inbound Rule |

The script will tell you the exact port to open after installation.

---

## 🐛 Troubleshooting

**VPN connects but no internet:**
```bash
sudo bash wireguard-pro.sh --repair
```

**Check service status:**
```bash
sudo systemctl status wg-quick@wg0
sudo journalctl -xeu wg-quick@wg0 --no-pager -n 50
```

**Check running peers:**
```bash
sudo wg show
```

**Test internet routing:**
```bash
# From server:
ping 8.8.8.8

# Check iptables:
sudo iptables -L FORWARD -n
sudo iptables -t nat -L POSTROUTING -n
```

**Oracle Cloud specific:**
Oracle Cloud has a default DROP rule in its iptables FORWARD chain. The script handles this automatically, but if you still have issues run `--repair`.

---

## 📁 File Locations

| Path | Description |
|------|-------------|
| `/etc/wireguard/wg0.conf` | Server WireGuard config |
| `/etc/wireguard/.wg-clients.db` | Client database |
| `/root/wireguard-clients/` | All client `.conf` and `.qr.txt` files |
| `/etc/sysctl.d/99-wireguard-pro.conf` | Kernel optimizations |
| `/var/log/wireguard-pro.log` | Setup + operation log |
| `/root/wireguard-backups/` | Backup archives |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — PRs welcome!

**Ideas for contributions:**
- More OS support
- WireGuard Dashboard web UI integration
- Prometheus/Grafana metrics export
- Email/Telegram notification on new client
- Multi-interface support (wg0, wg1...)
- Split-tunnel per-app routing

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

## ⭐ Star History

If this script helped you, please give it a ⭐ star — it helps others find it!

---

<p align="center">
  Made with ❤️ for the open-source community<br>
  <strong>WireGuard is a registered trademark of Jason A. Donenfeld</strong>
</p>
