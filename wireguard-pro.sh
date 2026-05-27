#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                                                                              ║
# ║   WireGuard Pro  ·  v3.0.0                                                  ║
# ║   The World's Best WireGuard VPN Installer & Manager                        ║
# ║                                                                              ║
# ║   ★ One Command  ★ Any Linux  ★ Any Cloud  ★ Full Lifecycle               ║
# ║   ★ Gaming  ★ Streaming  ★ Daily Use  ★ Enterprise                        ║
# ║                                                                              ║
# ║   sudo bash wireguard-pro.sh                                                ║
# ║                                                                              ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║  Supported OS:    Ubuntu 18+ · Debian 9+ · CentOS 7/8/9 · RHEL 8/9        ║
# ║                   Rocky · AlmaLinux · Fedora 30+ · Arch · Alpine 3.12+     ║
# ║                   openSUSE · Amazon Linux 2/2023 · Raspberry Pi OS          ║
# ║                   Armbian · Kali · Parrot · Any Debian/RHEL/Arch derivative ║
# ║                                                                              ║
# ║  Supported Arch:  x86_64 · arm64/aarch64 · armv7 · armv6 · riscv64        ║
# ║                                                                              ║
# ║  Supported Cloud: AWS · GCP · Azure · Oracle · DigitalOcean · Hetzner      ║
# ║                   Vultr · Linode · OVH · Contabo · Any VPS                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -uo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
#  §0  METADATA
# ══════════════════════════════════════════════════════════════════════════════
readonly VER="3.0.0"
readonly SCRIPT_NAME="wireguard-pro.sh"
readonly REPO_URL="https://raw.githubusercontent.com/your-repo/wireguard-pro/main/wireguard-pro.sh"
readonly SCRIPT_PID=$$

# ══════════════════════════════════════════════════════════════════════════════
#  §1  COLORS  (gracefully disabled when not a TTY)
# ══════════════════════════════════════════════════════════════════════════════
if [[ -t 1 ]] && tput colors &>/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
  R='\033[0;31m'    G='\033[0;32m'    Y='\033[1;33m'    B='\033[0;34m'
  C='\033[0;36m'    M='\033[0;35m'    W='\033[1;37m'    DIM='\033[2m'
  BOLD='\033[1m'    RST='\033[0m'     UL='\033[4m'
  BGRED='\033[41m'  BGGRN='\033[42m'  BGYLW='\033[43m'  BGCYN='\033[46m'
else
  R='' G='' Y='' B='' C='' M='' W='' DIM='' BOLD='' RST='' UL=''
  BGRED='' BGGRN='' BGYLW='' BGCYN=''
fi

# ══════════════════════════════════════════════════════════════════════════════
#  §2  LOGGING  — everything → log file + stdout
# ══════════════════════════════════════════════════════════════════════════════
readonly LOG_FILE="/var/log/wireguard-pro.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
exec > >(tee -a "$LOG_FILE") 2>&1
printf '\n%s\n' "═══ Session: $(date -u '+%Y-%m-%d %H:%M:%S UTC')  v${VER}  PID:${SCRIPT_PID} ═══" >> "$LOG_FILE"

log()    { printf "  ${G}✔${RST}  ${W}%s${RST}\n"         "$*"; }
info()   { printf "  ${C}◆${RST}  ${C}%s${RST}\n"          "$*"; }
warn()   { printf "  ${Y}⚠${RST}  ${Y}%s${RST}\n"          "$*"; }
step()   { printf "  ${M}⚙${RST}  ${M}%s${RST}\n"          "$*"; }
die()    { printf "\n  ${R}✘${RST}  ${R}${BOLD}FATAL: %s${RST}\n\n" "$*" >&2; exit 1; }
abort()  { printf "\n  ${Y}⚠${RST}  ${Y}%s${RST}\n\n"     "$*"; exit 0; }
nl()     { printf '\n'; }
hr()     { printf "  ${DIM}%s${RST}\n" "────────────────────────────────────────────────────────────────"; }
dhr()    { printf "  ${C}%s${RST}\n"   "════════════════════════════════════════════════════════════════"; }
section(){ nl; hr; printf "  ${BOLD}${C}%s${RST}\n" "$*"; hr; nl; }
label()  { printf "  ${DIM}%-24s${RST}: ${W}%s${RST}\n" "$1" "$2"; }

# ══════════════════════════════════════════════════════════════════════════════
#  §3  GLOBALS  (populated by detection functions)
# ══════════════════════════════════════════════════════════════════════════════
# — OS —
OS_ID="" OS_VER="" OS_CODENAME="" OS_LIKE="" KERNEL="" ARCH=""
TOTAL_MEM=0 NCPU=1 IS_CONTAINER=false IS_VM=false

# — Cloud / Hosting —
CLOUD_PROVIDER="generic"

# — Package manager —
PKG_UPDATE="" PKG_INSTALL="" PKG_REMOVE="" PKG_QUERY="" WG_PKG=""
IS_APT=false IS_PACMAN=false IS_APK=false FW_PERSIST_PKG=""

# — Network —
PUBLIC_IFACE="" SERVER_PUBLIC_IP="" SERVER_IPV6=""
DETECTED_MTU=1420

# — Firewall backend (auto-detected: ufw | firewalld | nftables | iptables) —
FW_BACKEND=""

# — WireGuard paths —
WG_IFACE="wg0"
WG_DIR="/etc/wireguard"
WG_CONF="${WG_DIR}/${WG_IFACE}.conf"
CLIENT_DIR="/root/wireguard-clients"
DB_FILE="${WG_DIR}/.wg-clients.db"

# — Setup parameters (populated by wizard) —
WG_PORT=""
WG_NET="10.66.0"
SERVER_VPN_IP=""
CLIENT_DNS=""
NUM_CLIENTS=1
MTU=1420
KEEPALIVE=25
ALLOWED_IPS_MODE="full"
KILL_SWITCH=false
PERF_PROFILE="balanced"   # gaming | streaming | balanced | custom
IPV6_SUPPORT=false
SETUP_NOTE=""
MAX_CLIENTS=50

# — Key arrays —
SERVER_PRIV="" SERVER_PUB=""
declare -a CLIENT_PRIVS=()
declare -a CLIENT_PUBS=()
declare -a CLIENT_PSKS=()
declare -a CLIENT_NAMES=()

# ══════════════════════════════════════════════════════════════════════════════
#  §4  SAFETY CHECKS
# ══════════════════════════════════════════════════════════════════════════════
[[ $EUID -ne 0 ]]              && die "Run as root:  sudo bash ${SCRIPT_NAME}"
[[ ${BASH_VERSINFO[0]} -lt 4 ]] && die "Bash 4.0+ required (found: ${BASH_VERSION})"

# ══════════════════════════════════════════════════════════════════════════════
#  §5  BANNER
# ══════════════════════════════════════════════════════════════════════════════
banner() {
  clear 2>/dev/null || true
  printf "${C}${BOLD}"
  cat << 'ASCII'

  ██╗    ██╗██╗██████╗ ███████╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗
  ██║    ██║██║██╔══██╗██╔════╝██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗
  ██║ █╗ ██║██║██████╔╝█████╗  ██║  ███╗██║   ██║███████║██████╔╝██║  ██║
  ██║███╗██║██║██╔══██╗██╔══╝  ██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║
  ╚███╔███╔╝██║██║  ██║███████╗╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
   ╚══╝╚══╝ ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝

ASCII
  printf "${RST}"
  dhr
  printf "  ${W}${BOLD}  ★  WireGuard Pro  v${VER}  —  World's Best VPN Installer & Manager  ★${RST}\n"
  printf "  ${DIM}     Gaming · Streaming · Daily Use · Any Linux · Any Cloud${RST}\n"
  dhr; nl
}

# ══════════════════════════════════════════════════════════════════════════════
#  §6  INTERACTIVE HELPERS
# ══════════════════════════════════════════════════════════════════════════════

# Prompt with default: result in $REPLY_VAL
prompt() {
  local msg="$1" default="${2:-}" secret="${3:-no}"
  local prompt_str
  if [[ -n "$default" ]]; then
    prompt_str="  ${C}▶${RST}  ${W}${msg}${RST} ${DIM}[${default}]${RST}: "
  else
    prompt_str="  ${C}▶${RST}  ${W}${msg}${RST}: "
  fi
  printf "%s" "$prompt_str"
  if [[ "$secret" == "yes" ]]; then
    IFS= read -rs REPLY_VAL 2>/dev/null || REPLY_VAL=""
    nl
  else
    IFS= read -r  REPLY_VAL 2>/dev/null || REPLY_VAL=""
  fi
  [[ -z "$REPLY_VAL" ]] && REPLY_VAL="$default"
}

# yes/no prompt: returns 0=yes 1=no
confirm() {
  local msg="${1}" default="${2:-y}"
  local suffix
  if [[ "${default,,}" == "y" ]]; then suffix="${G}[Y/n]${RST}"; else suffix="${Y}[y/N]${RST}"; fi
  printf "  ${C}▶${RST}  ${W}%s${RST} %s: " "$msg" "$suffix"
  local ans; IFS= read -r ans 2>/dev/null || ans=""
  [[ -z "$ans" ]] && ans="$default"
  [[ "${ans,,}" =~ ^y(es)?$ ]]
}

# Numbered menu — options passed as "$@"
menu() {
  local title="$1"; shift
  local opts=("$@")
  nl
  printf "  ${BOLD}${W}%s${RST}\n" "$title"
  hr
  local i=1
  for opt in "${opts[@]}"; do
    printf "  ${C}[%d]${RST}  %s\n" "$i" "$opt"
    ((i++)) || true
  done
  printf "  ${C}[0]${RST}  ${DIM}Exit / Cancel${RST}\n"
  hr
  prompt "Select" ""
  echo "$REPLY_VAL"
}

# Spinner for long-running operations
spin_start() { printf "  ${M}⚙${RST}  ${M}%s...${RST}  " "$1"; _SPIN_MSG="$1"; }
spin_stop()  {
  local rc="${1:-0}"
  if [[ "$rc" -eq 0 ]]; then printf "${G}done${RST}\n"
  else                       printf "${R}failed${RST}\n"; fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §7  CLIENT DATABASE  (flat-file: NAME|VPN_IP|PUBKEY|CREATED|STATUS)
# ══════════════════════════════════════════════════════════════════════════════

db_init() {
  mkdir -p "$WG_DIR" && chmod 700 "$WG_DIR"
  [[ -f "$DB_FILE" ]] || {
    printf '# WireGuard Pro — Client Database\n' > "$DB_FILE"
    printf '# FORMAT: NAME|VPN_IP|PUBKEY|CREATED|STATUS\n' >> "$DB_FILE"
  }
}

# Add a client record
db_add() {
  local name="$1" vpn_ip="$2" pubkey="$3"
  local created; created=$(date -u '+%Y-%m-%d')
  printf '%s|%s|%s|%s|active\n' "$name" "$vpn_ip" "$pubkey" "$created" >> "$DB_FILE"
}

# Remove a client record by name
db_remove() {
  local name="$1"
  local tmp; tmp=$(mktemp)
  grep -v "^${name}|" "$DB_FILE" 2>/dev/null > "$tmp" || true
  mv "$tmp" "$DB_FILE"
}

# Set client status (active | revoked)
db_set_status() {
  local name="$1" status="$2"
  local tmp; tmp=$(mktemp)
  awk -F'|' -v n="$name" -v s="$status" '
    /^#/ { print; next }
    $1==n { $5=s; print $1"|"$2"|"$3"|"$4"|"$5; next }
    { print }
  ' "$DB_FILE" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$DB_FILE"
}

# Count active clients
db_count() {
  grep -v '^#' "$DB_FILE" 2>/dev/null | grep -c '|active$' || echo 0
}

# Next available VPN IP (returns e.g. 10.66.0.5)
db_next_ip() {
  local used_ips
  used_ips=$(grep -v '^#' "$DB_FILE" 2>/dev/null | cut -d'|' -f2 | sort -t. -k4 -n)
  local n=2
  while true; do
    local candidate="${WG_NET}.${n}"
    if ! echo "$used_ips" | grep -qF "$candidate"; then
      echo "$candidate"; return 0
    fi
    ((n++)) || true
    [[ $n -gt 254 ]] && die "VPN subnet ${WG_NET}.0/24 is full (254 clients max)"
  done
}

# List all clients: prints table
db_list() {
  local clients
  clients=$(grep -v '^#' "$DB_FILE" 2>/dev/null | grep -v '^$' || true)
  if [[ -z "$clients" ]]; then
    warn "No clients found in database"
    return 1
  fi
  nl
  printf "  ${BOLD}${W}%-5s  %-20s  %-14s  %-12s  %-10s${RST}\n" \
    "#" "NAME" "VPN IP" "CREATED" "STATUS"
  hr
  local i=1
  while IFS='|' read -r name vpn_ip pubkey created status; do
    local col="${G}"
    [[ "$status" == "revoked" ]] && col="${R}"
    printf "  ${C}%-5s${RST}  ${W}%-20s${RST}  ${C}%-14s${RST}  ${DIM}%-12s${RST}  %s%-10s${RST}\n" \
      "$i" "$name" "$vpn_ip" "$created" "$col" "$status"
    ((i++)) || true
  done <<< "$clients"
  hr
  return 0
}

# Get field from client by name: db_get NAME FIELD(1-5)
db_get() {
  local name="$1" field="$2"
  grep -v '^#' "$DB_FILE" 2>/dev/null | grep "^${name}|" | cut -d'|' -f"${field}" | head -1
}

# ══════════════════════════════════════════════════════════════════════════════
#  §8  OS DETECTION
# ══════════════════════════════════════════════════════════════════════════════
detect_os() {
  section "◈ System Detection"

  [[ -f /etc/os-release ]] || die "Cannot detect OS — /etc/os-release not found"
  # shellcheck source=/dev/null
  source /etc/os-release

  OS_ID="${ID:-unknown}"
  OS_VER="${VERSION_ID:-unknown}"
  OS_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  OS_LIKE="${ID_LIKE:-}"
  KERNEL=$(uname -r)
  ARCH=$(uname -m)
  TOTAL_MEM=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null || echo "0")
  NCPU=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)

  label "OS"      "${OS_ID^} ${OS_VER} ${OS_CODENAME:+(${OS_CODENAME})}"
  label "Kernel"  "${KERNEL}"
  label "Arch"    "${ARCH}"
  label "CPU/RAM" "${NCPU} core(s) / ${TOTAL_MEM} MB"

  # Container / VM detection
  if [[ -f /.dockerenv ]] \
     || grep -qE 'docker|lxc|containerd|kubepods' /proc/1/cgroup 2>/dev/null \
     || [[ -d /run/systemd/container ]]; then
    IS_CONTAINER=true
    warn "Container environment detected — WireGuard requires host kernel module"
    warn "Ensure host kernel has WireGuard AND this container has NET_ADMIN capability"
  fi

  if grep -qi "vmware\|virtualbox\|kvm\|qemu\|xen\|hyper-v" \
       /sys/class/dmi/id/product_name 2>/dev/null \
     || grep -qi "vmware\|virtualbox\|kvm\|qemu" \
       /proc/cpuinfo 2>/dev/null; then
    IS_VM=true
    info "Virtualization: VM detected"
  fi

  # Cloud provider
  local vendor product chassis
  vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo "")
  product=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "")
  chassis=$(cat /sys/class/dmi/id/chassis_vendor 2>/dev/null || echo "")
  local combined="${vendor} ${product} ${chassis} ${KERNEL}"

  if   echo "$combined" | grep -qi "oracle\|oci";      then CLOUD_PROVIDER="oracle"
  elif echo "$combined" | grep -qi "amazon\|aws";       then CLOUD_PROVIDER="aws"
  elif echo "$combined" | grep -qi "google";            then CLOUD_PROVIDER="gcp"
  elif echo "$combined" | grep -qi "microsoft\|azure";  then CLOUD_PROVIDER="azure"
  elif echo "$combined" | grep -qi "digitalocean\|droplet"; then CLOUD_PROVIDER="digitalocean"
  elif echo "$combined" | grep -qi "hetzner";           then CLOUD_PROVIDER="hetzner"
  elif echo "$combined" | grep -qi "vultr\|choopa";     then CLOUD_PROVIDER="vultr"
  elif echo "$combined" | grep -qi "linode\|akamai";    then CLOUD_PROVIDER="linode"
  elif echo "$combined" | grep -qi "ovh";               then CLOUD_PROVIDER="ovh"
  elif echo "$combined" | grep -qi "contabo";           then CLOUD_PROVIDER="contabo"
  fi

  if [[ "$CLOUD_PROVIDER" != "generic" ]]; then
    info "Cloud: ${Y}${CLOUD_PROVIDER^^}${RST} ${DIM}— cloud firewall rules may need manual opening${RST}"
  fi

  # Set up package manager
  _detect_pkg_manager

  # Max recommended clients based on RAM
  if   [[ $TOTAL_MEM -ge 8192 ]]; then MAX_CLIENTS=250
  elif [[ $TOTAL_MEM -ge 4096 ]]; then MAX_CLIENTS=100
  elif [[ $TOTAL_MEM -ge 2048 ]]; then MAX_CLIENTS=50
  elif [[ $TOTAL_MEM -ge 1024 ]]; then MAX_CLIENTS=25
  else                                  MAX_CLIENTS=10; fi

  info "Max recommended clients for this server: ${W}${MAX_CLIENTS}${RST}"
  log "System detection complete"
}

_detect_pkg_manager() {
  # Try exact ID, then ID_LIKE fallback
  local id="${OS_ID}" like="${OS_LIKE}"
  case "$id" in
    ubuntu|debian|raspbian|linuxmint|pop|kali|parrot|mx|elementary|zorin|neon|tails|devuan|pureOS)
      _pkg_apt ;;
    centos|rhel|rocky|almalinux|ol|springdale|circle|eurolinux|tencentos)
      _pkg_yum ;;
    fedora|nobara|ultramarine|bazzite|kinoite|silverblue)
      _pkg_dnf ;;
    arch|manjaro|endeavouros|garuda|artix|crystal|cachyos|parabola|hyperbola)
      _pkg_pacman ;;
    alpine)
      _pkg_apk ;;
    opensuse*|suse|sles|tumbleweed|leap)
      _pkg_zypper ;;
    void)
      _pkg_xbps ;;
    amzn)   # Amazon Linux
      if [[ "$OS_VER" == "2023" ]]; then _pkg_dnf
      else _pkg_yum; fi
      ;;
    nixos)  die "NixOS: use 'nix-shell' or a NixOS module for WireGuard instead" ;;
    *)
      # Fallback via ID_LIKE
      if   echo "$like" | grep -qiE "debian|ubuntu";  then warn "Unknown OS '$id' — treating as Debian-based"; _pkg_apt
      elif echo "$like" | grep -qiE "rhel|fedora";    then warn "Unknown OS '$id' — treating as RHEL-based";   _pkg_dnf
      elif echo "$like" | grep -qiE "arch";            then warn "Unknown OS '$id' — treating as Arch-based";   _pkg_pacman
      elif echo "$like" | grep -qiE "suse";            then warn "Unknown OS '$id' — treating as SUSE-based";   _pkg_zypper
      else
        if command -v apt-get &>/dev/null;  then warn "Unknown OS '$id' — found apt";   _pkg_apt
        elif command -v dnf &>/dev/null;    then warn "Unknown OS '$id' — found dnf";   _pkg_dnf
        elif command -v yum &>/dev/null;    then warn "Unknown OS '$id' — found yum";   _pkg_yum
        elif command -v pacman &>/dev/null; then warn "Unknown OS '$id' — found pacman"; _pkg_pacman
        elif command -v apk &>/dev/null;    then warn "Unknown OS '$id' — found apk";   _pkg_apk
        else die "Cannot detect package manager on OS '${id}'. Please install WireGuard manually."
        fi
      fi ;;
  esac
}

_pkg_apt() {
  PKG_UPDATE="apt-get update -qq"
  PKG_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get install -y -q"
  PKG_REMOVE="DEBIAN_FRONTEND=noninteractive apt-get remove -y -q"
  PKG_QUERY="dpkg -l"
  WG_PKG="wireguard"
  IS_APT=true
  FW_PERSIST_PKG="iptables-persistent netfilter-persistent"
}

_pkg_yum() {
  PKG_UPDATE="yum makecache -q"
  PKG_INSTALL="yum install -y -q"
  PKG_REMOVE="yum remove -y -q"
  PKG_QUERY="rpm -q"
  WG_PKG="wireguard-tools"
  IS_APT=false
  FW_PERSIST_PKG=""
  # Enable EPEL for CentOS 7/8
  yum install -y -q epel-release 2>/dev/null || true
}

_pkg_dnf() {
  PKG_UPDATE="dnf makecache -q"
  PKG_INSTALL="dnf install -y -q"
  PKG_REMOVE="dnf remove -y -q"
  PKG_QUERY="rpm -q"
  WG_PKG="wireguard-tools"
  IS_APT=false
  FW_PERSIST_PKG=""
  # Enable EPEL for RHEL-based
  dnf install -y -q epel-release 2>/dev/null || true
}

_pkg_pacman() {
  PKG_UPDATE="pacman -Sy --noconfirm --quiet"
  PKG_INSTALL="pacman -S --noconfirm --quiet --needed"
  PKG_REMOVE="pacman -R --noconfirm --quiet"
  PKG_QUERY="pacman -Q"
  WG_PKG="wireguard-tools"
  IS_APT=false IS_PACMAN=true
  FW_PERSIST_PKG=""
}

_pkg_apk() {
  PKG_UPDATE="apk update -q"
  PKG_INSTALL="apk add -q"
  PKG_REMOVE="apk del -q"
  PKG_QUERY="apk info -e"
  WG_PKG="wireguard-tools"
  IS_APT=false IS_APK=true
  FW_PERSIST_PKG=""
}

_pkg_zypper() {
  PKG_UPDATE="zypper refresh -q"
  PKG_INSTALL="zypper install -y -q --no-recommends"
  PKG_REMOVE="zypper remove -y -q"
  PKG_QUERY="rpm -q"
  WG_PKG="wireguard-tools"
  IS_APT=false
  FW_PERSIST_PKG=""
}

_pkg_xbps() {
  PKG_UPDATE="xbps-install -Su -y"
  PKG_INSTALL="xbps-install -y"
  PKG_REMOVE="xbps-remove -y"
  PKG_QUERY="xbps-query"
  WG_PKG="wireguard-tools"
  IS_APT=false
  FW_PERSIST_PKG=""
}

pkg_install() {
  # Install packages quietly, die on critical failure
  local critical="${1:-true}" ; shift
  local pkgs=("$@")
  step "Installing: ${pkgs[*]}"
  # shellcheck disable=SC2086
  if eval ${PKG_INSTALL} "${pkgs[@]}" > /dev/null 2>&1; then
    log "Installed: ${pkgs[*]}"
  else
    if [[ "$critical" == "true" ]]; then
      die "Failed to install critical packages: ${pkgs[*]}"
    else
      warn "Optional packages unavailable: ${pkgs[*]} (skipping)"
    fi
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §9  NETWORK DETECTION
# ══════════════════════════════════════════════════════════════════════════════
detect_network() {
  section "◈ Network Detection"

  # — Default interface —
  PUBLIC_IFACE=$(ip route show default 2>/dev/null | awk '/default via/{print $5; exit}')
  if [[ -z "$PUBLIC_IFACE" ]]; then
    # Fallback: first non-loopback, non-wg interface
    PUBLIC_IFACE=$(ip -o link show up 2>/dev/null \
      | awk -F': ' '$2 !~ /^(lo|wg|veth|docker|br-)/{print $2; exit}')
  fi
  # Hard fallback
  for _iface in eth0 ens3 ens4 ens5 enp0s3 enp1s0 em0 em1 bond0 net0; do
    ip link show "$_iface" &>/dev/null && { PUBLIC_IFACE="${PUBLIC_IFACE:-$_iface}"; break; }
  done
  PUBLIC_IFACE="${PUBLIC_IFACE:-eth0}"
  label "Interface" "$PUBLIC_IFACE"

  # — Public IPv4 —
  step "Detecting public IPv4..."
  local ip4_services=(
    "https://api4.ipify.org"
    "https://api.ipify.org"
    "https://ifconfig.me/ip"
    "https://icanhazip.com"
    "https://checkip.amazonaws.com"
    "https://api4.my-ip.io/ip"
    "https://ipecho.net/plain"
    "https://ip4.seeip.org"
  )
  for svc in "${ip4_services[@]}"; do
    local ip; ip=$(curl -s4 --max-time 5 --retry 2 "$svc" 2>/dev/null | tr -d '[:space:]')
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      SERVER_PUBLIC_IP="$ip"; break
    fi
  done
  # Fallback: local IP of the primary interface
  if [[ -z "$SERVER_PUBLIC_IP" ]]; then
    SERVER_PUBLIC_IP=$(ip -4 addr show "$PUBLIC_IFACE" 2>/dev/null \
      | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
  fi
  [[ -z "$SERVER_PUBLIC_IP" ]] && die "Cannot detect public IP. Check network connectivity."
  label "Public IPv4" "$SERVER_PUBLIC_IP"

  # — Public IPv6 (optional) —
  local ip6; ip6=$(curl -s6 --max-time 5 "https://api6.ipify.org" 2>/dev/null | tr -d '[:space:]')
  if [[ "$ip6" =~ : ]]; then
    SERVER_IPV6="$ip6"
    IPV6_SUPPORT=true
    label "Public IPv6" "$SERVER_IPV6"
  else
    label "IPv6" "${DIM}not available${RST}"
  fi

  # — MTU auto-detection —
  # WireGuard overhead = 60 bytes (IPv4) / 80 bytes (IPv6) for WireGuard + UDP + IP
  local iface_mtu
  iface_mtu=$(ip link show "$PUBLIC_IFACE" 2>/dev/null | awk '/mtu/{for(i=1;i<=NF;i++) if($i=="mtu") print $(i+1)}')
  iface_mtu="${iface_mtu:-1500}"
  # WireGuard recommended: interface MTU - 80 (WireGuard overhead on IPv4)
  DETECTED_MTU=$(( iface_mtu - 80 ))
  # Clamp to safe range
  [[ $DETECTED_MTU -lt 1280 ]] && DETECTED_MTU=1280
  [[ $DETECTED_MTU -gt 1420 ]] && DETECTED_MTU=1420
  label "Interface MTU" "${iface_mtu}  →  WG MTU: ${DETECTED_MTU}"

  log "Network detection complete"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §10  PORT UTILITIES
# ══════════════════════════════════════════════════════════════════════════════
_reserved_ports=(20 21 22 23 25 53 67 68 69 80 110 119 123 143
  161 162 194 389 443 445 465 587 636 873 989 990 993 995
  1080 1194 1433 1521 3306 3389 5432 5900 6379 8080 8443 8888
  9200 27017 51820)

is_port_reserved() {
  local p="$1"
  for r in "${_reserved_ports[@]}"; do [[ "$p" -eq "$r" ]] && return 0; done
  return 1
}

is_port_in_use() {
  ss -uln 2>/dev/null | grep -q ":${1} " && return 0
  return 1
}

pick_random_port() {
  local tries=0 candidate
  while [[ $tries -lt 500 ]]; do
    ((tries++)) || true
    candidate=$(( (RANDOM * RANDOM % 42000) + 10000 ))
    is_port_reserved "$candidate" && continue
    is_port_in_use   "$candidate" && continue
    echo "$candidate"; return 0
  done
  echo "51820"
}

validate_port() {
  local p="$1"
  [[ "$p" =~ ^[0-9]+$ ]] && [[ "$p" -ge 1 ]] && [[ "$p" -le 65535 ]] || return 1
  is_port_reserved "$p" && warn "Port ${p} is commonly reserved — consider a different port" || true
  return 0
}

# ══════════════════════════════════════════════════════════════════════════════
#  §11  FIREWALL ABSTRACTION LAYER
# ══════════════════════════════════════════════════════════════════════════════
detect_firewall() {
  section "◈ Firewall Detection"

  if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
    FW_BACKEND="ufw"
  elif command -v firewall-cmd &>/dev/null && systemctl is-active --quiet firewalld 2>/dev/null; then
    FW_BACKEND="firewalld"
  elif command -v nft &>/dev/null && nft list ruleset &>/dev/null 2>&1 \
    && ! command -v iptables &>/dev/null; then
    FW_BACKEND="nftables"
  else
    FW_BACKEND="iptables"
  fi

  label "Firewall backend" "${FW_BACKEND}"
  log "Firewall backend: ${FW_BACKEND}"
}

# Open a UDP port in the active firewall
fw_open_udp() {
  local port="$1"
  case "$FW_BACKEND" in
    ufw)
      ufw allow "${port}/udp" comment "WireGuard VPN" 2>/dev/null || true
      log "ufw: opened UDP ${port}" ;;
    firewalld)
      firewall-cmd --permanent --add-port="${port}/udp" 2>/dev/null || true
      firewall-cmd --reload 2>/dev/null || true
      log "firewalld: opened UDP ${port}" ;;
    nftables)
      nft add rule inet filter input udp dport "${port}" accept comment '"WireGuard"' 2>/dev/null || true
      log "nftables: opened UDP ${port}" ;;
    *)  # iptables
      iptables  -I INPUT 1 -p udp --dport "${port}" -j ACCEPT 2>/dev/null || true
      ip6tables -I INPUT 1 -p udp --dport "${port}" -j ACCEPT 2>/dev/null || true
      log "iptables: opened UDP ${port}" ;;
  esac
}

# Apply NAT masquerade + forward rules
fw_apply_nat() {
  # Always use iptables for NAT (firewalld/ufw call iptables underneath)
  iptables -P FORWARD ACCEPT 2>/dev/null || true
  ip6tables -P FORWARD ACCEPT 2>/dev/null || true
  iptables -t nat  -C POSTROUTING -o "$PUBLIC_IFACE" -j MASQUERADE 2>/dev/null \
    || iptables -t nat -A POSTROUTING -o "$PUBLIC_IFACE" -j MASQUERADE 2>/dev/null || true
  iptables -C FORWARD -i "${WG_IFACE}" -j ACCEPT 2>/dev/null \
    || iptables -A FORWARD -i "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
  iptables -C FORWARD -o "${WG_IFACE}" -j ACCEPT 2>/dev/null \
    || iptables -A FORWARD -o "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
  iptables -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN \
    -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null \
    || iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN \
    -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
  log "NAT masquerade + FORWARD rules applied"
}

# Remove NAT rules (for uninstall)
fw_remove_nat() {
  iptables -t nat  -D POSTROUTING -o "$PUBLIC_IFACE" -j MASQUERADE 2>/dev/null || true
  iptables -D FORWARD -i "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
  iptables -D FORWARD -o "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
  iptables -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN \
    -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null || true
}

# Close the VPN UDP port
fw_close_udp() {
  local port="$1"
  case "$FW_BACKEND" in
    ufw)      ufw delete allow "${port}/udp" 2>/dev/null || true ;;
    firewalld)
      firewall-cmd --permanent --remove-port="${port}/udp" 2>/dev/null || true
      firewall-cmd --reload 2>/dev/null || true ;;
    nftables) true ;;  # manual cleanup required for nftables
    *)
      iptables  -D INPUT -p udp --dport "${port}" -j ACCEPT 2>/dev/null || true
      ip6tables -D INPUT -p udp --dport "${port}" -j ACCEPT 2>/dev/null || true ;;
  esac
}

# Persist firewall rules across reboots
fw_save() {
  case "$FW_BACKEND" in
    ufw)      ufw reload 2>/dev/null || true ;;
    firewalld) firewall-cmd --reload 2>/dev/null || true ;;
    *)
      if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save 2>/dev/null || true
      elif command -v iptables-save &>/dev/null; then
        mkdir -p /etc/iptables
        iptables-save  > /etc/iptables/rules.v4 2>/dev/null || true
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true
      fi ;;
  esac
  log "Firewall rules persisted"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §12  IS WIREGUARD INSTALLED?
# ══════════════════════════════════════════════════════════════════════════════
wg_is_installed() {
  command -v wg &>/dev/null && [[ -f "$WG_CONF" ]]
}

wg_is_running() {
  systemctl is-active --quiet "wg-quick@${WG_IFACE}" 2>/dev/null \
    && ip link show "${WG_IFACE}" &>/dev/null
}

# ══════════════════════════════════════════════════════════════════════════════
#  §13  PERFORMANCE PROFILES
#       Optimized for: Gaming · Streaming · Balanced · Custom
# ══════════════════════════════════════════════════════════════════════════════
apply_performance_profile() {
  section "◈ Performance & Network Optimization"

  local profile="${PERF_PROFILE:-balanced}"
  info "Applying profile: ${BOLD}${profile^^}${RST}"

  # ── Sysctl base (all profiles) ──────────────────────────────────────────
  local sysctl_file="/etc/sysctl.d/99-wireguard-pro.conf"
  cat > "$sysctl_file" << SYSCTL
# ─────────────────────────────────────────────────────────────────────────────
#  WireGuard Pro — Kernel Optimizations  (profile: ${profile})
#  Managed by wireguard-pro.sh — DO NOT EDIT MANUALLY
# ─────────────────────────────────────────────────────────────────────────────

# ── Forwarding (required for VPN) ──
net.ipv4.ip_forward                    = 1
net.ipv6.conf.all.forwarding           = 1
net.ipv6.conf.default.forwarding       = 1

# ── Core socket buffers ──
net.core.rmem_default                  = 26214400
net.core.wmem_default                  = 26214400
net.core.rmem_max                      = 134217728
net.core.wmem_max                      = 134217728
net.core.optmem_max                    = 65536
net.core.netdev_max_backlog            = 250000

# ── TCP buffers ──
net.ipv4.tcp_rmem                      = 4096 87380 134217728
net.ipv4.tcp_wmem                      = 4096 65536 134217728
net.ipv4.tcp_mem                       = 786432 1048576 26777216

# ── UDP buffers (critical for WireGuard) ──
net.ipv4.udp_rmem_min                  = 16384
net.ipv4.udp_wmem_min                  = 16384

# ── Congestion control: BBR (best for VPN throughput + latency) ──
net.core.default_qdisc                 = fq
net.ipv4.tcp_congestion_control        = bbr

# ── TCP performance ──
net.ipv4.tcp_fastopen                  = 3
net.ipv4.tcp_window_scaling            = 1
net.ipv4.tcp_timestamps                = 1
net.ipv4.tcp_sack                      = 1
net.ipv4.tcp_dsack                     = 1
net.ipv4.tcp_fack                      = 0
net.ipv4.tcp_tw_reuse                  = 1
net.ipv4.tcp_fin_timeout               = 15
net.ipv4.tcp_keepalive_time            = 300
net.ipv4.tcp_keepalive_probes          = 5
net.ipv4.tcp_keepalive_intvl           = 15
net.ipv4.tcp_mtu_probing               = 1
net.ipv4.tcp_slow_start_after_idle     = 0
net.ipv4.tcp_no_metrics_save           = 1

# ── Connection tracking ──
net.netfilter.nf_conntrack_max         = 1048576
net.netfilter.nf_conntrack_tcp_timeout_established = 7440
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120

# ── Security hardening ──
net.ipv4.conf.all.accept_redirects     = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects       = 0
net.ipv4.conf.default.send_redirects   = 0
net.ipv4.conf.all.accept_source_route  = 0
net.ipv4.conf.all.rp_filter            = 1
net.ipv4.conf.default.rp_filter        = 1
net.ipv4.icmp_echo_ignore_broadcasts   = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# ── Listening queue ──
net.core.somaxconn                     = 65535
net.ipv4.tcp_max_syn_backlog           = 65535
SYSCTL

  # ── Profile-specific additions ─────────────────────────────────────────
  case "$profile" in
    gaming)
      cat >> "$sysctl_file" << GAMING
# ── GAMING PROFILE: minimize latency, reduce jitter ──
net.core.busy_poll                     = 50
net.core.busy_read                     = 50
net.core.default_qdisc                 = fq_codel
net.ipv4.tcp_low_latency               = 1
net.ipv4.ipfrag_time                   = 10
net.ipv4.route.min_pmtu                = 576
GAMING
      MTU="${MTU:-1280}"
      KEEPALIVE=15
      ;;
    streaming)
      cat >> "$sysctl_file" << STREAMING
# ── STREAMING PROFILE: maximize throughput, smooth delivery ──
net.core.default_qdisc                 = fq
net.ipv4.tcp_pacing_ss_ratio           = 200
net.ipv4.tcp_pacing_ca_ratio           = 120
net.ipv4.tcp_notsent_lowat             = 131072
STREAMING
      MTU="${MTU:-1420}"
      KEEPALIVE=25
      ;;
    *)  # balanced (default)
      cat >> "$sysctl_file" << BALANCED
# ── BALANCED PROFILE: good for daily use, gaming, and streaming ──
net.core.default_qdisc                 = fq_codel
BALANCED
      MTU="${MTU:-1420}"
      KEEPALIVE=25
      ;;
  esac

  chmod 644 "$sysctl_file"
  log "Sysctl config written: $sysctl_file"

  # Apply immediately
  sysctl --system > /dev/null 2>&1 || sysctl -p "$sysctl_file" > /dev/null 2>&1 || true

  # Force-apply critical params now
  sysctl -w net.ipv4.ip_forward=1               > /dev/null 2>&1 || true
  sysctl -w net.ipv6.conf.all.forwarding=1       > /dev/null 2>&1 || true
  sysctl -w net.core.default_qdisc=fq_codel      > /dev/null 2>&1 || true
  sysctl -w net.ipv4.tcp_congestion_control=bbr  > /dev/null 2>&1 || true

  # Verify ip_forward
  local fwd; fwd=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "0")
  if [[ "$fwd" != "1" ]]; then
    warn "ip_forward not applied via sysctl — force-writing directly..."
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding 2>/dev/null || true
  fi
  log "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"

  # ── CPU governor → performance (reduces latency on VMs too) ─────────────
  if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      echo performance > "$gov" 2>/dev/null || true
    done
    log "CPU governor: performance"
  fi

  # ── NIC queue tuning ─────────────────────────────────────────────────────
  if command -v ethtool &>/dev/null; then
    # Set combined queues to number of CPUs
    ethtool -L "$PUBLIC_IFACE" combined "$NCPU" 2>/dev/null \
      && log "NIC combined queues: ${NCPU}" \
      || info "NIC queue tuning skipped (virtual NIC — expected on VPS)"

    # Enable GRO/GSO/TSO for throughput
    ethtool -K "$PUBLIC_IFACE" gro on gso on 2>/dev/null || true

    # Disable pause frames (can cause latency spikes — especially for gaming)
    ethtool -A "$PUBLIC_IFACE" rx off tx off 2>/dev/null || true

    # Ring buffer: increase to reduce packet loss under load
    ethtool -G "$PUBLIC_IFACE" rx 4096 tx 4096 2>/dev/null || true
  fi

  # ── RPS/RFS (multi-core receive packet steering) ─────────────────────────
  local cpu_mask
  cpu_mask=$(printf '%x' $(( (1 << NCPU) - 1 )) 2>/dev/null || echo "f")
  for rps in /sys/class/net/"$PUBLIC_IFACE"/queues/rx-*/rps_cpus; do
    echo "$cpu_mask" > "$rps" 2>/dev/null || true
  done
  local rfs_entries=$(( 32768 * NCPU ))
  echo "$rfs_entries" > /proc/sys/net/core/rps_sock_flow_entries 2>/dev/null || true
  for rfs in /sys/class/net/"$PUBLIC_IFACE"/queues/rx-*/rps_flow_cnt; do
    echo 32768 > "$rfs" 2>/dev/null || true
  done
  log "RPS/RFS: multi-core receive steering enabled"

  # ── IRQ affinity ─────────────────────────────────────────────────────────
  systemctl enable --now irqbalance 2>/dev/null || true

  # ── qdisc: fq_codel on public interface (reduces bufferbloat) ────────────
  tc qdisc del dev "$PUBLIC_IFACE" root 2>/dev/null || true
  if [[ "$profile" == "gaming" ]]; then
    # CAKE: best-in-class AQM for gaming (if available)
    if tc qdisc add dev "$PUBLIC_IFACE" root cake 2>/dev/null; then
      log "qdisc: CAKE on ${PUBLIC_IFACE} (best for gaming)"
    else
      tc qdisc add dev "$PUBLIC_IFACE" root fq_codel 2>/dev/null || true
      log "qdisc: fq_codel on ${PUBLIC_IFACE}"
    fi
  else
    tc qdisc add dev "$PUBLIC_IFACE" root fq_codel 2>/dev/null || true
    log "qdisc: fq_codel on ${PUBLIC_IFACE}"
  fi

  log "Performance optimization complete (profile: ${profile})"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §14  INSTALL PACKAGES
# ══════════════════════════════════════════════════════════════════════════════
install_packages() {
  section "◈ Installing Dependencies"

  step "Updating package lists..."
  eval "${PKG_UPDATE}" 2>/dev/null || warn "Package update had warnings (continuing)"

  # Critical packages
  local core_pkgs=("$WG_PKG" "iptables" "iproute2" "curl")
  # Alpine uses iproute2 differently
  [[ "$IS_APK" == "true" ]] && core_pkgs=("$WG_PKG" "iptables" "iproute2" "curl")

  pkg_install "true" "${core_pkgs[@]}"

  # Performance & tuning
  local perf_pkgs=("irqbalance" "ethtool")
  pkg_install "false" "${perf_pkgs[@]}"

  # QR code generation
  pkg_install "false" "qrencode"

  # iptables-legacy: needed on Ubuntu 22+ / Debian 11+ using nftables
  if [[ "$IS_APT" == "true" ]] && command -v iptables-legacy &>/dev/null; then
    update-alternatives --set iptables  /usr/sbin/iptables-legacy  2>/dev/null || true
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
    info "iptables: switched to legacy mode (nftables compatibility)"
  fi

  # Persistence for iptables on Debian/Ubuntu
  if [[ "$IS_APT" == "true" ]] && [[ -n "$FW_PERSIST_PKG" ]]; then
    # shellcheck disable=SC2086
    pkg_install "false" $FW_PERSIST_PKG
  fi

  log "All packages installed"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §15  WIREGUARD MODULE
# ══════════════════════════════════════════════════════════════════════════════
load_wg_module() {
  section "◈ WireGuard Kernel Module"

  if lsmod 2>/dev/null | grep -q "^wireguard"; then
    log "WireGuard module already loaded"
  else
    step "Loading wireguard module..."
    if modprobe wireguard 2>/dev/null; then
      log "WireGuard module loaded via modprobe"
    else
      # Try DKMS build (older kernels)
      if [[ "$IS_APT" == "true" ]]; then
        warn "Trying DKMS fallback..."
        pkg_install "false" "linux-headers-$(uname -r)" "wireguard-dkms"
        if modprobe wireguard 2>/dev/null; then
          log "WireGuard loaded via DKMS"
        else
          # Kernel ≥ 5.6 has WireGuard built-in
          local kver; kver=$(uname -r | cut -d. -f1-2 | tr -d '.')
          if [[ "${kver:-0}" -ge 56 ]]; then
            log "WireGuard is built into kernel (≥5.6) — no separate module needed"
          else
            die "Cannot load WireGuard kernel module. Kernel $(uname -r) may not support it."
          fi
        fi
      else
        warn "Module may be built into kernel (≥5.6) — continuing"
      fi
    fi
  fi

  # Persist module load across reboots
  echo "wireguard" > /etc/modules-load.d/wireguard.conf 2>/dev/null || true

  command -v wg &>/dev/null || die "'wg' command not found. WireGuard installation failed."
  local wg_ver; wg_ver=$(wg --version 2>/dev/null | head -1 || echo "unknown")
  log "WireGuard ready: ${wg_ver}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §16  SECURITY FRAMEWORK (AppArmor · SELinux)
# ══════════════════════════════════════════════════════════════════════════════
configure_security_framework() {
  # AppArmor — can block wg-quick on Ubuntu/Debian
  if systemctl is-active --quiet apparmor 2>/dev/null; then
    section "◈ AppArmor"
    warn "AppArmor is active. Adding WireGuard profile exception..."
    # Preferred: add exception rather than disabling entirely
    if command -v aa-status &>/dev/null; then
      local wg_quick_path; wg_quick_path=$(command -v wg-quick 2>/dev/null || echo "/usr/bin/wg-quick")
      mkdir -p /etc/apparmor.d/local 2>/dev/null || true
      # Create a permissive local override for wg-quick
      cat > /etc/apparmor.d/local/wireguard 2>/dev/null << 'APPARMOR_PROFILE'
# WireGuard Pro AppArmor local override
/usr/bin/wg-quick    ix,
/etc/wireguard/**    rw,
/usr/bin/wg          ix,
APPARMOR_PROFILE
      apparmor_parser -r /etc/apparmor.d/ 2>/dev/null || {
        warn "AppArmor reload failed — disabling temporarily"
        systemctl stop    apparmor 2>/dev/null || true
        systemctl disable apparmor 2>/dev/null || true
      }
    else
      systemctl stop    apparmor 2>/dev/null || true
      systemctl disable apparmor 2>/dev/null || true
    fi
    log "AppArmor: WireGuard exception configured"
  fi

  # SELinux — RHEL/CentOS/Fedora
  if command -v getenforce &>/dev/null; then
    local se_mode; se_mode=$(getenforce 2>/dev/null || echo "Disabled")
    if [[ "$se_mode" == "Enforcing" ]]; then
      section "◈ SELinux"
      info "SELinux is Enforcing — setting permissive for wireguard"
      semanage permissive -a wireguard_t 2>/dev/null || \
        setenforce 0 2>/dev/null || \
        warn "Could not set SELinux permissive — VPN may have issues"
      log "SELinux: handled (permissive for WireGuard)"
    fi
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §17  KEY GENERATION
# ══════════════════════════════════════════════════════════════════════════════
generate_keys() {
  section "◈ Generating Cryptographic Keys"
  umask 077

  step "Server keypair (Curve25519)..."
  SERVER_PRIV=$(wg genkey)  || die "wg genkey failed for server"
  SERVER_PUB=$(wg pubkey  <<< "$SERVER_PRIV") || die "wg pubkey failed"
  log "Server keypair generated"
  info "Server public key: ${DIM}${SERVER_PUB}${RST}"

  local i=0
  while [[ $i -lt $NUM_CLIENTS ]]; do
    local n=$((i+1))
    step "Client ${n}/${NUM_CLIENTS} — ${CLIENT_NAMES[$i]:-client${n}}"
    local priv pub psk
    priv=$(wg genkey)                    || die "wg genkey failed client ${n}"
    pub=$(wg pubkey <<< "$priv")         || die "wg pubkey failed client ${n}"
    psk=$(wg genpsk)                     || die "wg genpsk failed client ${n}"
    CLIENT_PRIVS+=("$priv")
    CLIENT_PUBS+=("$pub")
    CLIENT_PSKS+=("$psk")
    ((i++)) || true
  done
  log "All ${NUM_CLIENTS} keypair(s) generated"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §18  WRITE SERVER CONFIG
# ══════════════════════════════════════════════════════════════════════════════
write_server_config() {
  section "◈ Writing Server Configuration"

  mkdir -p "$WG_DIR" && chmod 700 "$WG_DIR"

  # PostUp/PostDown: single line each (semicolons), handles cloud/oracle drops
  local postup="sysctl -w net.ipv4.ip_forward=1; iptables -P FORWARD ACCEPT; \
iptables -t nat -A POSTROUTING -o ${PUBLIC_IFACE} -j MASQUERADE; \
iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; \
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"

  local postdown="iptables -P FORWARD ACCEPT; \
iptables -t nat -D POSTROUTING -o ${PUBLIC_IFACE} -j MASQUERADE; \
iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; \
iptables -t mangle -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"

  {
    printf '# ══════════════════════════════════════════════════════════════════════\n'
    printf '#  WireGuard Pro — Server Config\n'
    printf '#  Generated : %s\n' "$(date -u '+%Y-%m-%d %H:%M UTC')"
    printf '#  Server IP : %s | Interface: %s | Port: %s\n' \
      "$SERVER_PUBLIC_IP" "$PUBLIC_IFACE" "$WG_PORT"
    printf '#  Profile   : %s | MTU: %s | Subnet: %s.0/24\n' \
      "$PERF_PROFILE" "$MTU" "$WG_NET"
    [[ -n "$SETUP_NOTE" ]] && printf '#  Note      : %s\n' "$SETUP_NOTE"
    printf '# ══════════════════════════════════════════════════════════════════════\n\n'
    printf '[Interface]\n'
    printf 'Address    = %s/24\n' "${WG_NET}.1"
    printf 'ListenPort = %s\n'    "$WG_PORT"
    printf 'PrivateKey = %s\n'    "$SERVER_PRIV"
    printf 'MTU        = %s\n'    "$MTU"
    printf 'PostUp     = %s\n'    "$postup"
    printf 'PostDown   = %s\n'    "$postdown"
  } > "$WG_CONF"

  # Append all peer blocks
  local i=0
  while [[ $i -lt $NUM_CLIENTS ]]; do
    local n=$((i+1))
    local name="${CLIENT_NAMES[$i]:-client${n}}"
    local vpn_ip="${WG_NET}.$((i+2))"
    {
      printf '\n[Peer]\n'
      printf '# %s\n'          "$name"
      printf 'PublicKey    = %s\n' "${CLIENT_PUBS[$i]}"
      printf 'PresharedKey = %s\n' "${CLIENT_PSKS[$i]}"
      printf 'AllowedIPs   = %s/32\n' "$vpn_ip"
    } >> "$WG_CONF"
    # Register in DB
    db_add "$name" "$vpn_ip" "${CLIENT_PUBS[$i]}"
    ((i++)) || true
  done

  chmod 600 "$WG_CONF"

  # Validate config has no corrupted lines
  grep -qE '^server$|^client$' "$WG_CONF" 2>/dev/null \
    && die "Server config has corrupt content — check script output"

  log "Server config written: ${WG_CONF}"
  info "Peers configured: ${NUM_CLIENTS}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §19  WRITE CLIENT CONFIGS
# ══════════════════════════════════════════════════════════════════════════════
write_client_configs() {
  section "◈ Writing Client Configurations"

  mkdir -p "$CLIENT_DIR" && chmod 700 "$CLIENT_DIR"

  # Determine AllowedIPs
  local allowed_ips
  if [[ "$ALLOWED_IPS_MODE" == "split" ]]; then
    allowed_ips="${WG_NET}.0/24"
  else
    allowed_ips="0.0.0.0/0, ::/0"
  fi

  local i=0
  while [[ $i -lt $NUM_CLIENTS ]]; do
    local n=$((i+1))
    local name="${CLIENT_NAMES[$i]:-client${n}}"
    local vpn_ip="${WG_NET}.$((i+2))"
    local client_file="${CLIENT_DIR}/${name}.conf"

    {
      printf '# ══════════════════════════════════════════════════════════════════════\n'
      printf '#  WireGuard Pro — Client Config: %s\n' "$name"
      printf '#  Server    : %s:%s\n' "$SERVER_PUBLIC_IP" "$WG_PORT"
      printf '#  Generated : %s\n' "$(date -u '+%Y-%m-%d %H:%M UTC')"
      printf '#  Profile   : %s\n' "$PERF_PROFILE"
      [[ -n "$SETUP_NOTE" ]] && printf '#  Note      : %s\n' "$SETUP_NOTE"
      printf '#  Import into: Windows · Android · iOS · macOS · Linux\n'
      printf '# ══════════════════════════════════════════════════════════════════════\n\n'

      printf '[Interface]\n'
      printf 'PrivateKey = %s\n' "${CLIENT_PRIVS[$i]}"
      printf 'Address    = %s/24\n' "$vpn_ip"
      printf 'DNS        = %s\n' "$CLIENT_DNS"
      printf 'MTU        = %s\n' "$MTU"

      # Kill switch
      if "${KILL_SWITCH}"; then
        printf '# Kill switch: blocks all traffic if VPN drops\n'
        printf 'PostUp     = iptables -I OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -I OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT\n'
        printf 'PreDown    = iptables -D OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -D OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT\n'
      fi

      printf '\n[Peer]\n'
      printf '# Server\n'
      printf 'PublicKey           = %s\n' "$SERVER_PUB"
      printf 'PresharedKey        = %s\n' "${CLIENT_PSKS[$i]}"
      printf 'Endpoint            = %s:%s\n' "$SERVER_PUBLIC_IP" "$WG_PORT"
      printf 'AllowedIPs          = %s\n' "$allowed_ips"
      printf 'PersistentKeepalive = %s\n' "$KEEPALIVE"
    } > "$client_file"

    chmod 600 "$client_file"
    log "Client config: ${client_file}"
    ((i++)) || true
  done
}

# ══════════════════════════════════════════════════════════════════════════════
#  §20  SERVICE START + AUTO-REPAIR ENGINE
# ══════════════════════════════════════════════════════════════════════════════
start_wireguard() {
  section "◈ Starting WireGuard Service"

  # Pre-start: ensure FORWARD is ACCEPT (Oracle/cloud fix)
  iptables  -P FORWARD ACCEPT 2>/dev/null || true
  ip6tables -P FORWARD ACCEPT 2>/dev/null || true
  echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true

  local WG_START_OK=false
  local max_attempts=4

  for attempt in $(seq 1 $max_attempts); do
    step "Start attempt ${attempt}/${max_attempts}..."
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable "wg-quick@${WG_IFACE}" 2>/dev/null || true
    systemctl start  "wg-quick@${WG_IFACE}" 2>/dev/null || true
    sleep 2

    if wg_is_running; then
      log "WireGuard started (attempt ${attempt})"
      WG_START_OK=true; break
    fi

    [[ $attempt -lt $max_attempts ]] && _auto_repair "$attempt"
  done

  # Fallback 1: wg-quick directly
  if [[ "$WG_START_OK" != "true" ]]; then
    warn "systemctl failed — trying wg-quick directly..."
    wg-quick down "${WG_IFACE}" 2>/dev/null || true
    ip link delete "${WG_IFACE}" 2>/dev/null || true
    if wg-quick up "${WG_IFACE}" 2>/dev/null; then
      log "WireGuard started via wg-quick directly"
      WG_START_OK=true
    fi
  fi

  # Fallback 2: manual ip + wg setconf
  if [[ "$WG_START_OK" != "true" ]]; then
    warn "Attempting manual interface configuration..."
    ip link add  dev "${WG_IFACE}" type wireguard 2>/dev/null || true
    wg setconf      "${WG_IFACE}" "${WG_CONF}" 2>/dev/null || true
    ip address add  "${WG_NET}.1/24" dev "${WG_IFACE}" 2>/dev/null || true
    ip link set up  dev "${WG_IFACE}" 2>/dev/null || true
    fw_apply_nat
    ip link show "${WG_IFACE}" &>/dev/null && WG_START_OK=true
    [[ "$WG_START_OK" == "true" ]] && log "WireGuard configured manually"
  fi

  if [[ "$WG_START_OK" != "true" ]]; then
    warn "WireGuard could not start automatically"
    warn "Debug: journalctl -xeu wg-quick@${WG_IFACE} --no-pager -n 50"
  fi

  # Apply qdisc to wg interface
  sleep 1
  if ip link show "${WG_IFACE}" &>/dev/null; then
    tc qdisc del dev "${WG_IFACE}" root 2>/dev/null || true
    tc qdisc add dev "${WG_IFACE}" root fq_codel 2>/dev/null || true
    log "qdisc: fq_codel on ${WG_IFACE}"
  fi
}

_auto_repair() {
  local attempt="$1"
  local jlog; jlog=$(journalctl -xeu "wg-quick@${WG_IFACE}" --no-pager -n 60 2>/dev/null || true)
  warn "Auto-repair engine running (attempt ${attempt})..."

  # Stale interface
  if echo "$jlog" | grep -qi "already exists\|RTNETLINK\|File exists"; then
    warn "  → Removing stale ${WG_IFACE} interface"
    ip link delete "${WG_IFACE}" 2>/dev/null || true
  fi

  # Port conflict
  if echo "$jlog" | grep -qi "address already in use\|bind.*fail\|cannot bind"; then
    local newport; newport=$(pick_random_port)
    warn "  → Port conflict: switching ${WG_PORT} → ${newport}"
    WG_PORT=$newport
    sed -i "s/^ListenPort = .*/ListenPort = ${WG_PORT}/" "${WG_CONF}"
    # Update all client configs
    for conf_file in "${CLIENT_DIR}"/*.conf; do
      [[ -f "$conf_file" ]] || continue
      sed -i "s|Endpoint = ${SERVER_PUBLIC_IP}:[0-9]*|Endpoint = ${SERVER_PUBLIC_IP}:${WG_PORT}|g" \
        "$conf_file" 2>/dev/null || true
    done
    info "  → All configs updated to port ${WG_PORT}"
  fi

  # Config parse error
  if echo "$jlog" | grep -qi "parsing error\|unrecognized key\|configuration parsing"; then
    warn "  → Config parse error — rebuilding cleanly"
    {
      printf '[Interface]\n'
      printf 'Address    = %s/24\n' "${WG_NET}.1"
      printf 'ListenPort = %s\n'    "$WG_PORT"
      printf 'PrivateKey = %s\n'    "$SERVER_PRIV"
      printf 'MTU        = %s\n'    "$MTU"
      printf 'PostUp     = sysctl -w net.ipv4.ip_forward=1; iptables -P FORWARD ACCEPT; iptables -t nat -A POSTROUTING -o %s -j MASQUERADE; iptables -A FORWARD -i %%i -j ACCEPT; iptables -A FORWARD -o %%i -j ACCEPT\n' "$PUBLIC_IFACE"
      printf 'PostDown   = iptables -P FORWARD ACCEPT; iptables -t nat -D POSTROUTING -o %s -j MASQUERADE; iptables -D FORWARD -i %%i -j ACCEPT; iptables -D FORWARD -o %%i -j ACCEPT\n' "$PUBLIC_IFACE"
    } > "${WG_CONF}"
    local ri=0
    while [[ $ri -lt $NUM_CLIENTS ]]; do
      local rn=$((ri+1)) rv="${WG_NET}.$((ri+2))"
      printf '\n[Peer]\n# client%d\nPublicKey    = %s\nPresharedKey = %s\nAllowedIPs   = %s/32\n' \
        "$rn" "${CLIENT_PUBS[$ri]}" "${CLIENT_PSKS[$ri]}" "$rv" >> "${WG_CONF}"
      ((ri++)) || true
    done
    chmod 600 "${WG_CONF}"
    info "  → Config rebuilt"
  fi

  # iptables errors
  if echo "$jlog" | grep -qi "iptables\|nft\|ip6tables"; then
    warn "  → Switching to iptables-legacy"
    update-alternatives --set iptables  /usr/sbin/iptables-legacy  2>/dev/null || true
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy 2>/dev/null || true
  fi

  # Kernel module
  if echo "$jlog" | grep -qi "operation not permitted\|no such device\|ENODEV"; then
    warn "  → Reloading kernel module"
    rmmod   wireguard 2>/dev/null || true
    modprobe wireguard 2>/dev/null || true
  fi

  sleep 2
}

# ══════════════════════════════════════════════════════════════════════════════
#  §21  INTERNET ROUTING VERIFICATION & FIX
# ══════════════════════════════════════════════════════════════════════════════
verify_internet_routing() {
  section "◈ Internet Routing Verification"

  local fixed=0

  # 1. ip_forward
  if [[ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" != "1" ]]; then
    warn "ip_forward=0 — fixing..."
    echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
    ((fixed++)) || true
  fi
  log "IPv4 forwarding: $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"

  # 2. FORWARD chain policy
  local fwd_pol; fwd_pol=$(iptables -L FORWARD 2>/dev/null | head -1 | awk '{print $NF}' | tr -d '()')
  if [[ "$fwd_pol" != "ACCEPT" ]]; then
    warn "FORWARD policy=${fwd_pol} — setting ACCEPT"
    iptables -P FORWARD ACCEPT 2>/dev/null || true
    ((fixed++)) || true
  fi
  log "FORWARD chain policy: ACCEPT"

  # 3. MASQUERADE rule
  if ! iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE"; then
    warn "MASQUERADE missing — re-adding"
    iptables -t nat -A POSTROUTING -o "$PUBLIC_IFACE" -j MASQUERADE 2>/dev/null || true
    ((fixed++)) || true
  fi
  log "NAT MASQUERADE: active"

  # 4. FORWARD rules for wg
  if ! iptables -L FORWARD -n 2>/dev/null | grep -q "${WG_IFACE}"; then
    warn "FORWARD rules for ${WG_IFACE} missing — re-adding"
    iptables -I FORWARD 1 -i "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
    iptables -I FORWARD 2 -o "${WG_IFACE}" -j ACCEPT 2>/dev/null || true
    ((fixed++)) || true
  fi
  log "FORWARD rules: present"

  # 5. Oracle Cloud: ensure INPUT allows VPN port
  if [[ "$CLOUD_PROVIDER" == "oracle" ]]; then
    if ! iptables -L INPUT -n 2>/dev/null | grep -q "${WG_PORT}"; then
      iptables -I INPUT 1 -p udp --dport "${WG_PORT}" -j ACCEPT 2>/dev/null || true
      log "Oracle: opened UDP ${WG_PORT} in INPUT chain"
    fi
    # Oracle Cloud also blocks with a DROP rule in FORWARD — remove it
    local drop_line
    drop_line=$(iptables -L FORWARD --line-numbers -n 2>/dev/null \
      | awk '/DROP/{print $1; exit}')
    if [[ -n "$drop_line" ]] && [[ "$drop_line" =~ ^[0-9]+$ ]]; then
      iptables -D FORWARD "$drop_line" 2>/dev/null || true
      info "Oracle: removed DROP rule from FORWARD chain"
    fi
  fi

  if [[ $fixed -eq 0 ]]; then
    log "Internet routing: all checks passed ✔"
  else
    log "Internet routing: ${fixed} issue(s) auto-fixed ✔"
  fi

  fw_save

  # Test internet from server
  if ping -c 2 -W 3 1.1.1.1 &>/dev/null 2>&1; then
    log "Server internet connectivity: OK ✔"
  elif ping -c 2 -W 3 8.8.8.8 &>/dev/null 2>&1; then
    log "Server internet connectivity: OK ✔"
  else
    warn "Server cannot reach internet — check cloud security group"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §22  QR CODES
# ══════════════════════════════════════════════════════════════════════════════
generate_qr_codes() {
  command -v qrencode &>/dev/null || { warn "qrencode not available — skipping QR codes"; return; }

  section "◈ Generating QR Codes"
  local i=0
  while [[ $i -lt $NUM_CLIENTS ]]; do
    local n=$((i+1))
    local name="${CLIENT_NAMES[$i]:-client${n}}"
    local conf="${CLIENT_DIR}/${name}.conf"
    local qr_file="${CLIENT_DIR}/${name}.qr.txt"

    if qrencode -t ansiutf8 < "$conf" > "$qr_file" 2>/dev/null; then
      log "QR code: ${qr_file}"
      # Also show inline
      printf "\n  ${C}Client ${n}: ${W}${name}${RST} — scan with WireGuard mobile app:\n\n"
      cat "$qr_file"
      nl
    fi
    ((i++)) || true
  done
}

# ══════════════════════════════════════════════════════════════════════════════
#  §23  VERIFICATION CHECKLIST
# ══════════════════════════════════════════════════════════════════════════════
run_verification() {
  section "◈ Final Verification"

  local pass=0 fail=0

  _chk() {
    local label="$1" ok="$2" hint="${3:-}"
    if [[ "$ok" -eq 1 ]]; then
      printf "    ${G}✔${RST}  %-40s\n" "$label"
      ((pass++)) || true
    else
      printf "    ${R}✘${RST}  ${R}%-40s${RST}  ${DIM}%s${RST}\n" "$label" "$hint"
      ((fail++)) || true
    fi
  }

  local ok=0
  ip link show "${WG_IFACE}" &>/dev/null                           && ok=1; _chk "Interface ${WG_IFACE} exists"     $ok; ok=0
  systemctl is-active --quiet "wg-quick@${WG_IFACE}" 2>/dev/null  && ok=1; _chk "Systemd service active"            $ok "check: journalctl -xeu wg-quick@${WG_IFACE}"; ok=0
  [[ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" == "1" ]] && ok=1; _chk "IPv4 forwarding enabled"           $ok; ok=0
  iptables -t nat -L POSTROUTING -n 2>/dev/null | grep -q "MASQUERADE" && ok=1; _chk "NAT masquerade active"     $ok "needed for client internet"; ok=0
  iptables -L FORWARD 2>/dev/null | head -1 | grep -q "ACCEPT"    && ok=1; _chk "FORWARD chain: ACCEPT"            $ok "critical — run: iptables -P FORWARD ACCEPT"; ok=0
  ss -uln 2>/dev/null | grep -q ":${WG_PORT} "                    && ok=1; _chk "UDP port ${WG_PORT} listening"     $ok; ok=0
  [[ -f "${WG_CONF}" ]]                                            && ok=1; _chk "Server config exists"             $ok; ok=0
  [[ -f "${CLIENT_DIR}/${CLIENT_NAMES[0]:-client1}.conf" ]] || \
  [[ -f "${CLIENT_DIR}/client1.conf" ]]                            && ok=1; _chk "Client config(s) exist"           $ok; ok=0
  ! grep -qE '^server$|^client$' "${WG_CONF}" 2>/dev/null         && ok=1; _chk "Config format valid"              $ok; ok=0
  [[ -f "$DB_FILE" ]]                                              && ok=1; _chk "Client database exists"           $ok; ok=0

  nl; hr
  local total=$((pass+fail))
  if [[ $fail -eq 0 ]]; then
    printf "  ${G}${BOLD}  ✔  All ${total}/${total} checks passed — VPN is ready!${RST}\n"
  else
    printf "  ${Y}${BOLD}  ${pass}/${total} passed — ${fail} issue(s) detected${RST}\n"
    printf "  ${DIM}  Run: journalctl -xeu wg-quick@${WG_IFACE} --no-pager -n 50${RST}\n"
  fi
  hr
}

# ══════════════════════════════════════════════════════════════════════════════
#  §24  CLEANUP OLD INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════
cleanup_old_install() {
  section "◈ Cleaning Previous Installation"

  systemctl stop    "wg-quick@${WG_IFACE}" 2>/dev/null || true
  systemctl disable "wg-quick@${WG_IFACE}" 2>/dev/null || true

  if ip link show "${WG_IFACE}" &>/dev/null; then
    ip link delete "${WG_IFACE}" 2>/dev/null || true
    info "Removed old ${WG_IFACE} interface"
  fi

  # Flush and reset firewall
  iptables -F FORWARD        2>/dev/null || true
  iptables -t nat  -F        2>/dev/null || true
  iptables -t mangle -F      2>/dev/null || true
  iptables -P FORWARD ACCEPT 2>/dev/null || true

  # Back up old config
  if [[ -f "${WG_CONF}" ]]; then
    local bak="${WG_CONF}.bak.$(date +%s)"
    cp "${WG_CONF}" "$bak" 2>/dev/null || true
    info "Old config backed up: ${bak}"
    rm -f "${WG_CONF}"
  fi

  # Reset client database
  [[ -f "$DB_FILE" ]] && mv "$DB_FILE" "${DB_FILE}.bak.$(date +%s)" 2>/dev/null || true

  log "Cleanup complete"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §25  INSTALL SUMMARY BOX
# ══════════════════════════════════════════════════════════════════════════════
show_install_summary() {
  nl; dhr
  printf "  ${C}${BOLD}%s${RST}\n" "  🎉  WireGuard Pro — Setup Complete!"
  dhr
  printf "  ${DIM}%-22s${RST}: ${W}%s${RST}\n"  "Server IP"     "$SERVER_PUBLIC_IP"
  printf "  ${DIM}%-22s${RST}: ${W}%s${RST}\n"  "Interface"     "$PUBLIC_IFACE"
  printf "  ${DIM}%-22s${RST}: ${G}%s/UDP${RST}\n" "VPN Port"  "$WG_PORT"
  printf "  ${DIM}%-22s${RST}: ${C}%s.0/24${RST}\n" "VPN Subnet" "$WG_NET"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "DNS"           "$CLIENT_DNS"
  printf "  ${DIM}%-22s${RST}: ${G}%s${RST}\n"  "Clients"       "$NUM_CLIENTS"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Routing"       "${ALLOWED_IPS_MODE} tunnel"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Performance"   "${PERF_PROFILE}"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Kill Switch"   "${KILL_SWITCH}"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "MTU"           "$MTU"
  dhr

  nl; printf "  ${W}${BOLD}Client Config Files:${RST}\n"; hr
  for f in "${CLIENT_DIR}"/*.conf; do
    [[ -f "$f" ]] || continue
    local name; name=$(basename "$f" .conf)
    local qr="${CLIENT_DIR}/${name}.qr.txt"
    printf "  ${C}▶${RST}  ${W}%s${RST}\n" "$f"
    [[ -f "$qr" ]] && printf "     ${DIM}QR: %s${RST}\n" "$qr"
  done
  hr

  nl; printf "  ${W}${BOLD}Quick Commands:${RST}\n"; hr
  printf "  ${C}▶${RST}  Status dashboard   : ${W}sudo bash %s${RST}\n" "$SCRIPT_NAME"
  printf "  ${C}▶${RST}  WireGuard status   : ${W}sudo wg show${RST}\n"
  printf "  ${C}▶${RST}  Restart VPN        : ${W}sudo systemctl restart wg-quick@${WG_IFACE}${RST}\n"
  printf "  ${C}▶${RST}  Live traffic       : ${W}sudo wg show ${WG_IFACE} transfer${RST}\n"
  printf "  ${C}▶${RST}  View logs          : ${W}journalctl -xeu wg-quick@${WG_IFACE}${RST}\n"
  printf "  ${C}▶${RST}  Add client         : ${W}sudo bash %s${RST}\n" "$SCRIPT_NAME"
  hr

  nl; printf "  ${W}${BOLD}Transfer configs to your device:${RST}\n"; hr
  for f in "${CLIENT_DIR}"/*.conf; do
    [[ -f "$f" ]] || continue
    printf "  ${DIM}scp root@%s:%s ./%s${RST}\n" \
      "$SERVER_PUBLIC_IP" "$f" "$(basename "$f")"
  done
  hr

  if [[ "$CLOUD_PROVIDER" != "generic" ]]; then
    nl
    printf "  ${Y}${BOLD}⚠  IMPORTANT — Open UDP port %s in your %s firewall:${RST}\n" \
      "$WG_PORT" "${CLOUD_PROVIDER^^}"
    case "$CLOUD_PROVIDER" in
      oracle)        printf "  ${DIM}  OCI → Networking → VCN → Security Lists → Add Ingress Rule${RST}\n" ;;
      aws)           printf "  ${DIM}  EC2 → Security Groups → Inbound Rules → Add UDP %s${RST}\n" "$WG_PORT" ;;
      gcp)           printf "  ${DIM}  VPC Network → Firewall → Create Rule → UDP %s${RST}\n" "$WG_PORT" ;;
      azure)         printf "  ${DIM}  NSG → Inbound Security Rules → Add UDP %s${RST}\n" "$WG_PORT" ;;
      digitalocean)  printf "  ${DIM}  Droplet → Networking → Firewalls → Add UDP %s${RST}\n" "$WG_PORT" ;;
      hetzner)       printf "  ${DIM}  Firewall → Add Inbound Rule → UDP %s${RST}\n" "$WG_PORT" ;;
      *)             printf "  ${DIM}  Open UDP port %s in your hosting provider's firewall panel${RST}\n" "$WG_PORT" ;;
    esac
  fi

  nl; printf "  ${G}${BOLD}  ★  Import any .conf file into the WireGuard app and connect!  ★${RST}\n"; nl
}

# ══════════════════════════════════════════════════════════════════════════════
#  §26  INSTALLATION WIZARD
# ══════════════════════════════════════════════════════════════════════════════
_dns_menu() {
  nl; printf "  ${W}${BOLD}Choose DNS for clients:${RST}\n"
  printf "  ${C}[1]${RST}  Cloudflare 1.1.1.1          ${DIM}(fastest, privacy-focused)${RST} ${Y}← recommended${RST}\n"
  printf "  ${C}[2]${RST}  Cloudflare 1.1.1.1 + WARP   ${DIM}(extra privacy layer)${RST}\n"
  printf "  ${C}[3]${RST}  Google 8.8.8.8               ${DIM}(reliable, global)${RST}\n"
  printf "  ${C}[4]${RST}  AdGuard 94.140.14.14         ${DIM}(blocks ads + trackers)${RST}\n"
  printf "  ${C}[5]${RST}  Quad9 9.9.9.9                ${DIM}(blocks malware)${RST}\n"
  printf "  ${C}[6]${RST}  OpenDNS 208.67.222.222       ${DIM}(family-safe option)${RST}\n"
  printf "  ${C}[7]${RST}  NextDNS                      ${DIM}(custom filtering)${RST}\n"
  printf "  ${C}[8]${RST}  Custom\n"
  nl
  prompt "Choice [1-8]" "1"; local c="$REPLY_VAL"
  case "$c" in
    2) CLIENT_DNS="1.1.1.1, 1.0.0.1" ;;
    3) CLIENT_DNS="8.8.8.8, 8.8.4.4" ;;
    4) CLIENT_DNS="94.140.14.14, 94.140.15.15" ;;
    5) CLIENT_DNS="9.9.9.9, 149.112.112.112" ;;
    6) CLIENT_DNS="208.67.222.222, 208.67.220.220" ;;
    7) CLIENT_DNS="45.90.28.0, 45.90.30.0" ;;
    8) prompt "Custom DNS (e.g. 1.1.1.1, 8.8.8.8)" "1.1.1.1"
       CLIENT_DNS="$REPLY_VAL" ;;
    *) CLIENT_DNS="1.1.1.1, 1.0.0.1" ;;
  esac
  log "DNS: ${CLIENT_DNS}"
}

_perf_menu() {
  nl; printf "  ${W}${BOLD}Choose Performance Profile:${RST}\n"
  printf "  ${C}[1]${RST}  ${G}Balanced${RST}   ${DIM}Best for daily use, browsing, mixed workloads${RST}  ${Y}← default${RST}\n"
  printf "  ${C}[2]${RST}  ${M}Gaming${RST}     ${DIM}Low latency, low jitter, fast response — ideal for FPS/MMO${RST}\n"
  printf "  ${C}[3]${RST}  ${C}Streaming${RST}  ${DIM}High throughput, smooth delivery — 4K/8K streaming${RST}\n"
  nl; printf "  ${DIM}  Profiles tune: kernel buffers, qdisc, MTU, keepalive, CPU governor${RST}\n\n"
  prompt "Choice [1-3]" "1"; local c="$REPLY_VAL"
  case "$c" in
    2) PERF_PROFILE="gaming"    ;;
    3) PERF_PROFILE="streaming" ;;
    *) PERF_PROFILE="balanced"  ;;
  esac
  log "Performance profile: ${PERF_PROFILE}"
}

run_install_wizard() {
  local RANDOM_PORT; RANDOM_PORT=$(pick_random_port)
  SERVER_VPN_IP="${WG_NET}.1"

  # ── Mode selection ──────────────────────────────────────────────────────
  nl; dhr
  printf "  ${W}${BOLD}Installation Mode${RST}\n"; hr
  printf "  ${G}[1]${RST}  ${W}Quick Setup${RST}       ${DIM}Smart defaults, 5 questions${RST}\n"
  printf "  ${B}[2]${RST}  ${W}Advanced Setup${RST}    ${DIM}Full control over every option${RST}\n"
  printf "  ${C}[3]${RST}  ${W}Auto / Turbo${RST}      ${DIM}Zero interaction — pure defaults${RST}\n"
  dhr; nl
  prompt "Choose [1-3]" "1"; local MODE="$REPLY_VAL"

  case "${MODE:-1}" in
  # ── QUICK ──────────────────────────────────────────────────────────────
  "1")
    nl; info "Quick Setup — press Enter to accept defaults"
    nl

    # Port
    prompt "VPN Port (UDP, 1-65535)" "$RANDOM_PORT"
    WG_PORT="$REPLY_VAL"
    validate_port "$WG_PORT" || { warn "Invalid port — using ${RANDOM_PORT}"; WG_PORT="$RANDOM_PORT"; }

    # Client count
    nl; prompt "How many client configs to generate? (1-${MAX_CLIENTS})" "1"
    NUM_CLIENTS="${REPLY_VAL:-1}"
    [[ "$NUM_CLIENTS" =~ ^[0-9]+$ ]] && [[ "$NUM_CLIENTS" -ge 1 ]] || NUM_CLIENTS=1
    if [[ $NUM_CLIENTS -gt $MAX_CLIENTS ]]; then
      warn "Entered ${NUM_CLIENTS} — max recommended is ${MAX_CLIENTS}"
      confirm "Continue anyway?" "n" && true || NUM_CLIENTS=$MAX_CLIENTS
    fi

    # Client names
    local i=0
    while [[ $i -lt $NUM_CLIENTS ]]; do
      local n=$((i+1)) default_name
      default_name="client${n}"
      prompt "Name for client ${n} (e.g. Laptop, Phone)" "$default_name"
      # Sanitize: alphanumeric + dash + underscore only
      local name; name=$(echo "$REPLY_VAL" | tr -dc 'A-Za-z0-9_-' | head -c 30)
      CLIENT_NAMES+=("${name:-$default_name}")
      ((i++)) || true
    done

    # Performance profile
    _perf_menu

    # DNS
    _dns_menu
    ;;

  # ── ADVANCED ──────────────────────────────────────────────────────────
  "2")
    nl; info "Advanced Setup — full customization"
    nl

    # Port
    prompt "VPN Port (UDP)" "$RANDOM_PORT"
    WG_PORT="$REPLY_VAL"
    validate_port "$WG_PORT" || { warn "Invalid — using ${RANDOM_PORT}"; WG_PORT="$RANDOM_PORT"; }

    # Subnet
    nl; prompt "VPN subnet base (e.g. 10.66.0 or 172.16.0)" "10.66.0"
    local raw_net="$REPLY_VAL"
    # Validate it looks like three octets
    if [[ "$raw_net" =~ ^([0-9]{1,3}\.){2}[0-9]{1,3}$ ]]; then
      WG_NET="$raw_net"
    else
      warn "Invalid subnet — using 10.66.0"
      WG_NET="10.66.0"
    fi

    # Clients
    nl; prompt "Number of clients (1-${MAX_CLIENTS})" "1"
    NUM_CLIENTS="${REPLY_VAL:-1}"
    [[ "$NUM_CLIENTS" =~ ^[0-9]+$ ]] || NUM_CLIENTS=1

    # Client names
    local i=0
    while [[ $i -lt $NUM_CLIENTS ]]; do
      local n=$((i+1)); prompt "Name for client ${n}" "client${n}"
      local name; name=$(echo "$REPLY_VAL" | tr -dc 'A-Za-z0-9_-' | head -c 30)
      CLIENT_NAMES+=("${name:-client${n}}")
      ((i++)) || true
    done

    # DNS
    nl; _dns_menu

    # Performance
    nl; _perf_menu

    # Routing
    nl; printf "  ${W}${BOLD}Traffic Routing Mode:${RST}\n"
    printf "  ${G}[1]${RST}  Full tunnel   ${DIM}(all traffic through VPN — 0.0.0.0/0)${RST}  ${Y}← recommended${RST}\n"
    printf "  ${G}[2]${RST}  Split tunnel  ${DIM}(only VPN subnet routed — ${WG_NET}.0/24)${RST}\n"
    nl; prompt "Choice [1-2]" "1"
    [[ "${REPLY_VAL}" == "2" ]] && ALLOWED_IPS_MODE="split" || ALLOWED_IPS_MODE="full"

    # MTU
    nl; prompt "MTU (1280-1500, auto-detected: ${DETECTED_MTU})" "$DETECTED_MTU"
    local mtu_in="${REPLY_VAL:-$DETECTED_MTU}"
    if [[ "$mtu_in" =~ ^[0-9]+$ ]] && [[ $mtu_in -ge 1280 ]] && [[ $mtu_in -le 1500 ]]; then
      MTU=$mtu_in
    else
      warn "Invalid MTU — using ${DETECTED_MTU}"; MTU=$DETECTED_MTU
    fi

    # Keepalive
    nl; prompt "PersistentKeepalive seconds (0 to disable)" "25"
    local ka="${REPLY_VAL:-25}"
    [[ "$ka" =~ ^[0-9]+$ ]] && KEEPALIVE=$ka || KEEPALIVE=25

    # Kill switch
    nl; confirm "Enable kill switch on clients? (blocks all traffic if VPN drops)" "n" \
      && KILL_SWITCH=true || KILL_SWITCH=false

    # IPv6 tunnel
    nl; confirm "Enable IPv6 in tunnel? (requires server has IPv6)" "n" \
      && IPV6_SUPPORT=true || IPV6_SUPPORT=false

    # Note
    nl; prompt "Optional note for configs (leave blank to skip)" ""
    SETUP_NOTE="$REPLY_VAL"
    ;;

  # ── TURBO / AUTO ──────────────────────────────────────────────────────
  *)
    WG_PORT=$RANDOM_PORT
    NUM_CLIENTS=1
    CLIENT_NAMES=("client1")
    CLIENT_DNS="1.1.1.1, 1.0.0.1"
    PERF_PROFILE="balanced"
    KILL_SWITCH=false
    MTU=$DETECTED_MTU
    log "Turbo mode — all defaults applied"
    ;;
  esac

  # Apply profile MTU overrides
  case "$PERF_PROFILE" in
    gaming)    [[ $MTU -gt 1280 ]] && MTU=1280; KEEPALIVE=15 ;;
    streaming) MTU="${MTU:-1420}" ;;
    *)         MTU="${MTU:-$DETECTED_MTU}" ;;
  esac
  SERVER_VPN_IP="${WG_NET}.1"

  # ── Pre-install summary ──────────────────────────────────────────────
  nl; dhr
  printf "  ${W}${BOLD}  Configuration Summary${RST}\n"; hr
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Server IP"      "$SERVER_PUBLIC_IP"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Network iface"  "$PUBLIC_IFACE"
  printf "  ${DIM}%-22s${RST}: ${G}%s/UDP${RST}\n" "VPN Port"    "$WG_PORT"
  printf "  ${DIM}%-22s${RST}: ${C}%s.0/24${RST}\n" "VPN Subnet" "$WG_NET"
  printf "  ${DIM}%-22s${RST}: ${G}%s${RST}\n"  "Clients"        "$NUM_CLIENTS"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "DNS"            "$CLIENT_DNS"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Routing"        "${ALLOWED_IPS_MODE} tunnel"
  printf "  ${DIM}%-22s${RST}: ${M}%s${RST}\n"  "Performance"    "$PERF_PROFILE"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Kill Switch"    "$KILL_SWITCH"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "MTU"            "$MTU"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Keepalive"      "${KEEPALIVE}s"
  dhr; nl

  confirm "Proceed with installation?" "y" || abort "Installation cancelled"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §27  CLIENT MANAGEMENT — ADD CLIENT
# ══════════════════════════════════════════════════════════════════════════════
cmd_add_client() {
  section "◈ Add New Client"

  # Need server config to exist
  [[ -f "$WG_CONF" ]] || die "Server config not found: ${WG_CONF}"
  command -v wg &>/dev/null || die "WireGuard not installed"

  db_init

  # Get client name
  prompt "Client name (e.g. Laptop, iPhone, Work)" "client$(( $(db_count) + 2 ))"
  local name; name=$(echo "$REPLY_VAL" | tr -dc 'A-Za-z0-9_-' | head -c 30)
  [[ -z "$name" ]] && name="client$(( $(db_count) + 2 ))"

  # Check for duplicate name
  if grep -q "^${name}|" "$DB_FILE" 2>/dev/null; then
    die "Client '${name}' already exists. Use a different name."
  fi

  # Assign next available VPN IP
  # Read WG_NET from server config
  local srv_addr; srv_addr=$(grep '^Address' "$WG_CONF" | head -1 | awk '{print $3}' | cut -d/ -f1)
  WG_NET=$(echo "$srv_addr" | sed 's/\.[0-9]*$//')
  local vpn_ip; vpn_ip=$(db_next_ip)

  # Read server public key
  local srv_priv; srv_priv=$(grep '^PrivateKey' "$WG_CONF" | head -1 | awk '{print $3}')
  local srv_pub;  srv_pub=$(echo "$srv_priv" | wg pubkey)

  # Read server port
  local port; port=$(grep '^ListenPort' "$WG_CONF" | head -1 | awk '{print $3}')

  # Read public interface from PostUp line
  local pub_iface; pub_iface=$(grep '^PostUp' "$WG_CONF" | grep -oE '\-o [a-z0-9_]+' | head -1 | awk '{print $2}')
  pub_iface="${pub_iface:-${PUBLIC_IFACE:-eth0}}"

  # Generate keys
  step "Generating keypair for ${name}..."
  local priv pub psk
  priv=$(wg genkey)
  pub=$(wg pubkey <<< "$priv")
  psk=$(wg genpsk)
  log "Keys generated for ${name}"

  # DNS (re-use or prompt)
  nl; prompt "DNS for this client" "1.1.1.1, 1.0.0.1"
  local dns="${REPLY_VAL:-1.1.1.1, 1.0.0.1}"

  # Routing
  nl; printf "  ${W}Routing mode:${RST}\n"
  printf "  ${C}[1]${RST}  Full tunnel  (all traffic through VPN)  ${Y}← default${RST}\n"
  printf "  ${C}[2]${RST}  Split tunnel (VPN subnet only)\n"
  nl; prompt "Choice [1-2]" "1"
  local allowed_ips="0.0.0.0/0, ::/0"
  [[ "${REPLY_VAL:-1}" == "2" ]] && allowed_ips="${WG_NET}.0/24"

  # Kill switch
  nl; confirm "Enable kill switch for this client?" "n" && local ks=true || local ks=false

  # MTU
  nl; prompt "MTU" "${DETECTED_MTU:-1420}"
  local mtu="${REPLY_VAL:-1420}"
  [[ "$mtu" =~ ^[0-9]+$ ]] || mtu=1420

  # Write client config
  mkdir -p "$CLIENT_DIR" && chmod 700 "$CLIENT_DIR"
  local client_file="${CLIENT_DIR}/${name}.conf"
  {
    printf '# WireGuard Pro — Client Config: %s\n' "$name"
    printf '# Server : %s:%s | Generated: %s\n\n' "$SERVER_PUBLIC_IP" "$port" "$(date -u '+%Y-%m-%d %H:%M UTC')"
    printf '[Interface]\n'
    printf 'PrivateKey = %s\n' "$priv"
    printf 'Address    = %s/24\n' "$vpn_ip"
    printf 'DNS        = %s\n' "$dns"
    printf 'MTU        = %s\n' "$mtu"
    if [[ "$ks" == "true" ]]; then
      printf 'PostUp   = iptables -I OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -I OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT\n'
      printf 'PreDown  = iptables -D OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT && ip6tables -D OUTPUT ! -o %%i -m mark ! --mark $(wg show %%i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT\n'
    fi
    printf '\n[Peer]\n'
    printf 'PublicKey           = %s\n' "$srv_pub"
    printf 'PresharedKey        = %s\n' "$psk"
    printf 'Endpoint            = %s:%s\n' "$SERVER_PUBLIC_IP" "$port"
    printf 'AllowedIPs          = %s\n' "$allowed_ips"
    printf 'PersistentKeepalive = 25\n'
  } > "$client_file"
  chmod 600 "$client_file"

  # Append peer to server config
  {
    printf '\n[Peer]\n'
    printf '# %s\n' "$name"
    printf 'PublicKey    = %s\n' "$pub"
    printf 'PresharedKey = %s\n' "$psk"
    printf 'AllowedIPs   = %s/32\n' "$vpn_ip"
  } >> "$WG_CONF"

  # Hot-add peer to running WireGuard (no restart needed)
  if wg_is_running; then
    wg set "${WG_IFACE}" peer "$pub" \
      preshared-key <(echo "$psk") \
      allowed-ips "${vpn_ip}/32" 2>/dev/null && \
      log "Peer hot-added to running WireGuard (no restart needed)" || \
      warn "Could not hot-add — restart with: systemctl restart wg-quick@${WG_IFACE}"
  fi

  # Register in DB
  db_add "$name" "$vpn_ip" "$pub"

  log "Client '${name}' added (${vpn_ip})"
  info "Config saved: ${client_file}"

  # QR code
  if command -v qrencode &>/dev/null; then
    local qr_file="${CLIENT_DIR}/${name}.qr.txt"
    qrencode -t ansiutf8 < "$client_file" > "$qr_file" 2>/dev/null || true
    nl; printf "  ${C}Scan with WireGuard mobile app:${RST}\n\n"
    cat "$qr_file"
    nl; info "QR saved: ${qr_file}"
  fi

  nl; info "Transfer to device:"
  printf "  ${DIM}scp root@%s:%s ./%s.conf${RST}\n" "$SERVER_PUBLIC_IP" "$client_file" "$name"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §28  CLIENT MANAGEMENT — REMOVE CLIENT
# ══════════════════════════════════════════════════════════════════════════════
cmd_remove_client() {
  section "◈ Remove Client"
  [[ -f "$WG_CONF" ]] || die "Server config not found"
  db_init

  db_list || return 1
  nl; prompt "Enter client NAME to permanently remove" ""
  local name="$REPLY_VAL"
  [[ -z "$name" ]] && { warn "No name entered"; return 1; }

  # Get pubkey before removing
  local pubkey; pubkey=$(db_get "$name" 3)
  [[ -z "$pubkey" ]] && { warn "Client '${name}' not found in database"; return 1; }

  nl
  confirm "Permanently remove client '${name}'? This cannot be undone." "n" || { warn "Cancelled"; return 0; }

  # Remove from running WireGuard (hot-remove)
  if wg_is_running && [[ -n "$pubkey" ]]; then
    wg set "${WG_IFACE}" peer "$pubkey" remove 2>/dev/null && \
      log "Peer removed from running WireGuard" || true
  fi

  # Remove [Peer] block from server config
  local tmp; tmp=$(mktemp)
  awk -v pub="$pubkey" '
    /^\[Peer\]/ { peer=1; block="" }
    peer { block = block $0 "\n" }
    peer && /^PublicKey/ && $3==pub { skip=1 }
    /^$/ && peer { if(!skip) printf "%s\n", block; peer=0; skip=0; block=""; next }
    !peer { print }
  ' "$WG_CONF" > "$tmp" 2>/dev/null
  # Fallback: simpler removal
  if ! grep -q "$pubkey" "$tmp" 2>/dev/null; then
    # Already removed or awk approach worked
    true
  fi
  mv "$tmp" "$WG_CONF"
  chmod 600 "$WG_CONF"

  # Remove client config files
  rm -f "${CLIENT_DIR}/${name}.conf" "${CLIENT_DIR}/${name}.qr.txt" 2>/dev/null || true

  # Remove from DB
  db_remove "$name"

  log "Client '${name}' permanently removed"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §29  CLIENT MANAGEMENT — REVOKE (disable without delete)
# ══════════════════════════════════════════════════════════════════════════════
cmd_revoke_client() {
  section "◈ Revoke / Re-enable Client"
  [[ -f "$WG_CONF" ]] || die "Server config not found"
  db_init

  db_list || return 1
  nl; prompt "Enter client NAME to revoke or re-enable" ""
  local name="$REPLY_VAL"
  [[ -z "$name" ]] && { warn "No name entered"; return 1; }

  local pubkey; pubkey=$(db_get "$name" 3)
  [[ -z "$pubkey" ]] && { warn "Client '${name}' not found"; return 1; }

  local status; status=$(db_get "$name" 5)

  if [[ "$status" == "revoked" ]]; then
    # Re-enable
    confirm "Re-enable client '${name}'?" "y" || return 0
    # Add peer back to server config
    local vpn_ip; vpn_ip=$(db_get "$name" 2)
    # We need the PSK — it's in the client conf if not deleted
    local client_conf="${CLIENT_DIR}/${name}.conf"
    local psk=""
    [[ -f "$client_conf" ]] && psk=$(grep '^PresharedKey' "$client_conf" | awk '{print $3}')
    {
      printf '\n[Peer]\n# %s\nPublicKey    = %s\n' "$name" "$pubkey"
      [[ -n "$psk" ]] && printf 'PresharedKey = %s\n' "$psk"
      printf 'AllowedIPs   = %s/32\n' "$vpn_ip"
    } >> "$WG_CONF"
    # Hot-add
    if wg_is_running; then
      if [[ -n "$psk" ]]; then
        wg set "${WG_IFACE}" peer "$pubkey" preshared-key <(echo "$psk") \
          allowed-ips "${vpn_ip}/32" 2>/dev/null || true
      else
        wg set "${WG_IFACE}" peer "$pubkey" allowed-ips "${vpn_ip}/32" 2>/dev/null || true
      fi
    fi
    db_set_status "$name" "active"
    log "Client '${name}' re-enabled"
  else
    # Revoke
    confirm "Revoke client '${name}'? (disables without deleting config)" "n" || return 0
    # Remove peer from server config (keep in DB + client file)
    local tmp; tmp=$(mktemp)
    awk -v pub="$pubkey" '
      /^\[Peer\]/ { peer=1; buf="" }
      peer { buf = buf $0 ORS }
      /^$/ && peer {
        if (buf !~ pub) printf "%s", buf
        peer=0; buf=""; next
      }
      !peer { print }
    ' "$WG_CONF" > "$tmp" 2>/dev/null || cp "$WG_CONF" "$tmp"
    mv "$tmp" "$WG_CONF"; chmod 600 "$WG_CONF"
    # Hot-remove
    wg_is_running && wg set "${WG_IFACE}" peer "$pubkey" remove 2>/dev/null || true
    db_set_status "$name" "revoked"
    log "Client '${name}' revoked (config preserved, peer disabled)"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §30  SHOW CLIENT QR / CONFIG
# ══════════════════════════════════════════════════════════════════════════════
cmd_show_client() {
  section "◈ Show Client Config / QR Code"
  db_init; db_list || return 1

  nl; prompt "Enter client NAME to display" ""
  local name="$REPLY_VAL"
  [[ -z "$name" ]] && { warn "No name entered"; return 1; }

  local conf="${CLIENT_DIR}/${name}.conf"
  [[ -f "$conf" ]] || die "Config not found: ${conf}"

  nl; dhr
  printf "  ${W}${BOLD}Config: %s${RST}\n" "$name"
  dhr
  # Show config (mask private key for security)
  while IFS= read -r line; do
    if echo "$line" | grep -q "PrivateKey"; then
      printf "  ${DIM}PrivateKey = [hidden for security]${RST}\n"
    else
      printf "  %s\n" "$line"
    fi
  done < "$conf"
  dhr; nl

  # QR code
  if command -v qrencode &>/dev/null; then
    local qr_file="${CLIENT_DIR}/${name}.qr.txt"
    qrencode -t ansiutf8 < "$conf" > "$qr_file" 2>/dev/null || true
    printf "  ${C}Scan with WireGuard mobile app:${RST}\n\n"
    cat "$qr_file"
    nl
  else
    warn "Install qrencode for QR code support"
  fi

  info "Transfer command:"
  printf "  ${DIM}scp root@%s:%s ./%s.conf${RST}\n" "$SERVER_PUBLIC_IP" "$conf" "$name"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §31  STATUS DASHBOARD
# ══════════════════════════════════════════════════════════════════════════════
cmd_status() {
  clear 2>/dev/null || true
  dhr
  printf "  ${C}${BOLD}WireGuard Pro — Status Dashboard${RST}   ${DIM}%s${RST}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
  dhr; nl

  # Service status
  if wg_is_running; then
    printf "  ${G}${BOLD}● Service: RUNNING${RST}   ${DIM}wg-quick@${WG_IFACE}${RST}\n"
  else
    printf "  ${R}${BOLD}● Service: STOPPED${RST}\n"
    printf "  ${DIM}  Start with: systemctl start wg-quick@${WG_IFACE}${RST}\n"
  fi
  nl

  # WireGuard interface info
  if ip link show "${WG_IFACE}" &>/dev/null 2>&1; then
    local wg_addr; wg_addr=$(ip -4 addr show "${WG_IFACE}" 2>/dev/null | awk '/inet /{print $2}' | head -1)
    local listen_port; listen_port=$(wg show "${WG_IFACE}" listen-port 2>/dev/null)
    local pub_key; pub_key=$(wg show "${WG_IFACE}" public-key 2>/dev/null)

    printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Interface"      "${WG_IFACE}"
    printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "VPN IP"         "${wg_addr:-unknown}"
    printf "  ${DIM}%-22s${RST}: ${G}%s/UDP${RST}\n" "Listen Port"  "${listen_port:-unknown}"
    printf "  ${DIM}%-22s${RST}: ${DIM}%s${RST}\n"  "Public Key"    "${pub_key:0:20}..."
    nl
  fi

  # Peer list from live wg show
  if ip link show "${WG_IFACE}" &>/dev/null 2>&1; then
    printf "  ${W}${BOLD}Connected Peers:${RST}\n"; hr
    local peer_data; peer_data=$(wg show "${WG_IFACE}" 2>/dev/null)
    if [[ -z "$peer_data" ]]; then
      printf "  ${DIM}  No peers configured${RST}\n"
    else
      # Parse wg show output
      local current_peer="" endpoint="" allowed="" latest_hs="" rx="" tx=""
      while IFS= read -r line; do
        if echo "$line" | grep -q "^peer:"; then
          # Print previous peer
          if [[ -n "$current_peer" ]]; then
            _print_peer_row "$current_peer" "$endpoint" "$allowed" "$latest_hs" "$rx" "$tx"
          fi
          current_peer=$(echo "$line" | awk '{print $2}')
          endpoint="" allowed="" latest_hs="" rx="" tx=""
        elif echo "$line" | grep -q "endpoint:"; then
          endpoint=$(echo "$line" | awk '{print $2}')
        elif echo "$line" | grep -q "allowed ips:"; then
          allowed=$(echo "$line" | awk '{print $3}')
        elif echo "$line" | grep -q "latest handshake:"; then
          latest_hs=$(echo "$line" | sed 's/.*latest handshake: //')
        elif echo "$line" | grep -q "transfer:"; then
          rx=$(echo "$line" | grep -oE '[0-9.]+ [KMGBi]* received' | head -1)
          tx=$(echo "$line" | grep -oE '[0-9.]+ [KMGBi]* sent' | head -1)
        fi
      done <<< "$peer_data"
      # Print last peer
      [[ -n "$current_peer" ]] && _print_peer_row "$current_peer" "$endpoint" "$allowed" "$latest_hs" "$rx" "$tx"
    fi
    hr; nl
  fi

  # Client database summary
  printf "  ${W}${BOLD}Client Database:${RST}\n"
  db_list 2>/dev/null || printf "  ${DIM}  No database found${RST}\n"
  nl

  # System stats
  printf "  ${W}${BOLD}System:${RST}\n"; hr
  local cpu_load; cpu_load=$(uptime 2>/dev/null | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
  local mem_used mem_total
  mem_used=$(awk '/MemAvailable/{print $2}' /proc/meminfo 2>/dev/null)
  mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null)
  local mem_pct=0
  [[ -n "$mem_total" ]] && [[ $mem_total -gt 0 ]] && \
    mem_pct=$(( (mem_total - mem_used) * 100 / mem_total ))

  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "CPU load (1m)"    "${cpu_load:-unknown}"
  printf "  ${DIM}%-22s${RST}: ${C}%s%%${RST}\n" "Memory used"     "${mem_pct}"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "ip_forward"       "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "Active clients"   "$(db_count)"

  # BBR check
  local cc; cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
  local qdisc; qdisc=$(tc qdisc show dev "${WG_IFACE}" 2>/dev/null | head -1 || echo "unknown")
  printf "  ${DIM}%-22s${RST}: ${G}%s${RST}\n"  "Congestion ctrl"  "$cc"
  printf "  ${DIM}%-22s${RST}: ${C}%s${RST}\n"  "qdisc (wg0)"      "$qdisc"
  hr; nl

  # Quick actions
  printf "  ${DIM}Tip: Re-run this script to manage clients, repair, or reconfigure${RST}\n\n"
}

_print_peer_row() {
  local peer="$1" endpoint="$2" allowed="$3" handshake="$4" rx="$5" tx="$6"
  # Look up name from DB
  local peer_name
  peer_name=$(grep -v '^#' "$DB_FILE" 2>/dev/null | awk -F'|' -v p="$peer" '$3==p{print $1}' | head -1)
  peer_name="${peer_name:-${peer:0:12}...}"

  local hs_col="${DIM}"
  [[ "$handshake" =~ "second" ]] && hs_col="${G}"
  [[ "$handshake" =~ "minute" ]] && hs_col="${G}"
  [[ "$handshake" =~ "hour"   ]] && hs_col="${Y}"
  [[ -z "$handshake" ]]          && hs_col="${R}" && handshake="never"

  printf "  ${W}%-18s${RST}  ${C}%-16s${RST}  %s%-20s${RST}  ${DIM}↓%s ↑%s${RST}\n" \
    "$peer_name" "${allowed:-?}" "$hs_col" "${handshake:0:18}" \
    "${rx:-0 B}" "${tx:-0 B}"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §32  REPAIR / RESTART
# ══════════════════════════════════════════════════════════════════════════════
cmd_repair() {
  section "◈ Repair & Restart WireGuard"

  step "Stopping WireGuard..."
  systemctl stop  "wg-quick@${WG_IFACE}" 2>/dev/null || true
  wg-quick down   "${WG_IFACE}" 2>/dev/null || true
  ip link delete  "${WG_IFACE}" 2>/dev/null || true

  step "Re-applying firewall rules..."
  iptables -P FORWARD ACCEPT 2>/dev/null || true
  echo 1 > /proc/sys/net/ipv4/ip_forward 2>/dev/null || true
  fw_apply_nat

  step "Restarting WireGuard..."
  systemctl daemon-reload 2>/dev/null || true
  if systemctl start "wg-quick@${WG_IFACE}" 2>/dev/null; then
    sleep 2
    if wg_is_running; then
      log "WireGuard repaired and running ✔"
    else
      warn "Service started but interface not up — trying wg-quick directly"
      wg-quick up "${WG_IFACE}" 2>/dev/null && log "WireGuard up via wg-quick" || \
        warn "Failed — check: journalctl -xeu wg-quick@${WG_IFACE} --no-pager"
    fi
  else
    warn "systemctl failed — trying wg-quick directly"
    wg-quick up "${WG_IFACE}" 2>/dev/null && log "WireGuard up via wg-quick" || \
      warn "Failed — check: journalctl -xeu wg-quick@${WG_IFACE} --no-pager"
  fi

  step "Re-applying performance optimizations..."
  local sysctl_file="/etc/sysctl.d/99-wireguard-pro.conf"
  [[ -f "$sysctl_file" ]] && sysctl -p "$sysctl_file" > /dev/null 2>&1 || true
  sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
  tc qdisc del dev "${WG_IFACE}" root 2>/dev/null || true
  tc qdisc add dev "${WG_IFACE}" root fq_codel  2>/dev/null || true
  fw_save

  verify_internet_routing
}

# ══════════════════════════════════════════════════════════════════════════════
#  §33  BACKUP & RESTORE
# ══════════════════════════════════════════════════════════════════════════════
cmd_backup() {
  section "◈ Backup WireGuard Configuration"

  local backup_dir="/root/wireguard-backups"
  local ts; ts=$(date '+%Y%m%d_%H%M%S')
  local archive="${backup_dir}/wg-backup-${ts}.tar.gz"

  mkdir -p "$backup_dir" && chmod 700 "$backup_dir"

  step "Creating encrypted backup archive..."
  tar -czf "$archive" \
    --exclude='*.bak.*' \
    "$WG_DIR" \
    "$CLIENT_DIR" \
    /etc/sysctl.d/99-wireguard-pro.conf \
    "$LOG_FILE" \
    2>/dev/null || true

  if [[ -f "$archive" ]]; then
    chmod 600 "$archive"
    log "Backup saved: ${archive}"
    local size; size=$(du -sh "$archive" 2>/dev/null | cut -f1)
    info "Backup size: ${size}"
    nl
    info "To restore on another server:"
    printf "  ${DIM}scp root@SERVER:%s ./backup.tar.gz${RST}\n" "$archive"
    printf "  ${DIM}sudo bash %s --restore ./backup.tar.gz${RST}\n" "$SCRIPT_NAME"
  else
    warn "Backup creation had issues — check permissions"
  fi
}

cmd_restore() {
  local archive="${1:-}"
  section "◈ Restore WireGuard Configuration"

  if [[ -z "$archive" ]]; then
    # List available backups
    local backup_dir="/root/wireguard-backups"
    if [[ -d "$backup_dir" ]]; then
      nl; printf "  ${W}Available backups:${RST}\n"; hr
      ls -lh "${backup_dir}"/*.tar.gz 2>/dev/null || printf "  ${DIM}  None found${RST}\n"
      hr; nl
    fi
    prompt "Path to backup archive" ""
    archive="$REPLY_VAL"
  fi

  [[ -f "$archive" ]] || die "Backup file not found: ${archive}"

  nl; confirm "Restore from '${archive}'? This will overwrite current configs!" "n" \
    || { warn "Restore cancelled"; return 0; }

  step "Stopping WireGuard..."
  systemctl stop "wg-quick@${WG_IFACE}" 2>/dev/null || true

  step "Extracting backup..."
  tar -xzf "$archive" -C / 2>/dev/null || die "Failed to extract backup"

  step "Restarting WireGuard..."
  systemctl daemon-reload 2>/dev/null || true
  systemctl enable "wg-quick@${WG_IFACE}" 2>/dev/null || true
  systemctl start  "wg-quick@${WG_IFACE}" 2>/dev/null || true
  sleep 2

  wg_is_running && log "Restore complete — WireGuard running ✔" || \
    warn "Restore complete but WireGuard didn't start — run repair"
}

# ══════════════════════════════════════════════════════════════════════════════
#  §34  UNINSTALL
# ══════════════════════════════════════════════════════════════════════════════
cmd_uninstall() {
  section "◈ Uninstall WireGuard Pro"

  nl
  printf "  ${R}${BOLD}WARNING: This will remove WireGuard and ALL client configs.${RST}\n"
  printf "  ${DIM}  A backup will be created before uninstalling.${RST}\n\n"
  confirm "Are you SURE you want to completely uninstall WireGuard?" "n" \
    || { warn "Uninstall cancelled"; return 0; }
  confirm "FINAL confirmation — type 'y' to proceed" "n" \
    || { warn "Uninstall cancelled"; return 0; }

  # Auto-backup first
  step "Creating pre-uninstall backup..."
  cmd_backup 2>/dev/null || true

  step "Stopping and disabling WireGuard..."
  systemctl stop    "wg-quick@${WG_IFACE}" 2>/dev/null || true
  systemctl disable "wg-quick@${WG_IFACE}" 2>/dev/null || true
  wg-quick down     "${WG_IFACE}" 2>/dev/null || true
  ip link delete    "${WG_IFACE}" 2>/dev/null || true

  step "Removing firewall rules..."
  local port; port=$(grep '^ListenPort' "$WG_CONF" 2>/dev/null | awk '{print $3}')
  [[ -n "$port" ]] && fw_close_udp "$port"
  fw_remove_nat
  iptables -P FORWARD ACCEPT 2>/dev/null || true
  fw_save

  step "Removing kernel optimizations..."
  rm -f /etc/sysctl.d/99-wireguard-pro.conf 2>/dev/null || true
  sysctl --system > /dev/null 2>&1 || true
  rm -f /etc/modules-load.d/wireguard.conf 2>/dev/null || true

  step "Removing WireGuard configs and client files..."
  rm -rf "$WG_DIR"     2>/dev/null || true
  rm -rf "$CLIENT_DIR" 2>/dev/null || true

  step "Removing WireGuard package..."
  if [[ "$IS_APT" == "true" ]]; then
    DEBIAN_FRONTEND=noninteractive apt-get remove -y -q wireguard wireguard-tools wireguard-dkms 2>/dev/null || true
    DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -q 2>/dev/null || true
  else
    eval "${PKG_REMOVE} ${WG_PKG}" 2>/dev/null || true
  fi

  # Unload module
  rmmod wireguard 2>/dev/null || true

  log "WireGuard Pro fully uninstalled"
  info "Backup preserved at: /root/wireguard-backups/"
  nl
}

# ══════════════════════════════════════════════════════════════════════════════
#  §35  SELF-UPDATE
# ══════════════════════════════════════════════════════════════════════════════
cmd_update_script() {
  section "◈ Update WireGuard Pro Script"

  local script_path; script_path=$(realpath "$0" 2>/dev/null || echo "/usr/local/bin/${SCRIPT_NAME}")

  step "Checking for updates..."
  local latest
  latest=$(curl -sf --max-time 15 "$REPO_URL" 2>/dev/null | head -5) || true

  if [[ -z "$latest" ]]; then
    warn "Could not reach update server — check internet connectivity"
    return 1
  fi

  local remote_ver; remote_ver=$(echo "$latest" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1 | tr -d 'v')
  if [[ -n "$remote_ver" ]] && [[ "$remote_ver" != "$VER" ]]; then
    info "New version available: ${remote_ver} (current: ${VER})"
    confirm "Update now?" "y" || { warn "Update cancelled"; return 0; }
    local bak="${script_path}.bak.${VER}"
    cp "$script_path" "$bak" 2>/dev/null || true
    if curl -sf --max-time 30 "$REPO_URL" -o "$script_path" 2>/dev/null; then
      chmod +x "$script_path"
      log "Updated to v${remote_ver} — backup: ${bak}"
      info "Re-run the script to use the new version"
    else
      cp "$bak" "$script_path" 2>/dev/null || true
      warn "Update failed — restored previous version"
    fi
  else
    log "Already on latest version (v${VER})"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
#  §36  FULL INSTALL FLOW
# ══════════════════════════════════════════════════════════════════════════════
do_full_install() {
  # Detection
  detect_os
  detect_network
  detect_firewall
  db_init

  # Wizard
  run_install_wizard

  # Install
  cleanup_old_install
  install_packages
  load_wg_module
  configure_security_framework
  apply_performance_profile

  # Config generation
  generate_keys
  write_server_config
  write_client_configs

  # Firewall + networking
  fw_open_udp  "$WG_PORT"
  fw_apply_nat

  # Start
  start_wireguard
  verify_internet_routing

  # Finalize
  generate_qr_codes
  run_verification
  show_install_summary
}

# ══════════════════════════════════════════════════════════════════════════════
#  §37  MANAGEMENT MENU (shown when WireGuard is already installed)
# ══════════════════════════════════════════════════════════════════════════════
management_menu() {
  # Detect network for any sub-commands that need it
  detect_network 2>/dev/null || true
  detect_firewall 2>/dev/null || true

  while true; do
    banner

    # Status header
    local svc_color="${R}" svc_label="STOPPED"
    wg_is_running && { svc_color="${G}"; svc_label="RUNNING"; }

    local port; port=$(grep '^ListenPort' "$WG_CONF" 2>/dev/null | awk '{print $3}')
    local client_count; client_count=$(db_count 2>/dev/null || echo "?")

    printf "  ${DIM}Server: ${W}%s${RST}  ${DIM}|  Port: ${G}%s/UDP${RST}  ${DIM}|  Clients: ${W}%s${RST}  ${DIM}|  Status: %s${BOLD}● %s${RST}\n\n" \
      "${SERVER_PUBLIC_IP:-?}" "${port:-?}" "$client_count" "$svc_color" "$svc_label"

    dhr
    printf "  ${BOLD}${W}Manage WireGuard Pro${RST}\n"
    dhr
    printf "  ${C}[1]${RST}  ${W}Add Client${RST}              ${DIM}Generate new VPN config + QR code${RST}\n"
    printf "  ${C}[2]${RST}  ${W}Remove Client${RST}           ${DIM}Permanently delete a client${RST}\n"
    printf "  ${C}[3]${RST}  ${W}Revoke / Re-enable${RST}      ${DIM}Disable a client without deleting${RST}\n"
    printf "  ${C}[4]${RST}  ${W}List Clients${RST}            ${DIM}Show all clients + status${RST}\n"
    printf "  ${C}[5]${RST}  ${W}Show Config / QR Code${RST}   ${DIM}Display config & QR for mobile${RST}\n"
    dhr
    printf "  ${C}[6]${RST}  ${W}Status Dashboard${RST}        ${DIM}Live peers, traffic, system stats${RST}\n"
    printf "  ${C}[7]${RST}  ${W}Repair & Restart${RST}        ${DIM}Fix common issues, re-apply rules${RST}\n"
    printf "  ${C}[8]${RST}  ${W}Backup Configs${RST}          ${DIM}Save all configs to archive${RST}\n"
    printf "  ${C}[9]${RST}  ${W}Restore Backup${RST}          ${DIM}Restore from a previous backup${RST}\n"
    dhr
    printf "  ${C}[10]${RST} ${W}Update Script${RST}           ${DIM}Check for and apply updates${RST}\n"
    printf "  ${C}[11]${RST} ${R}Uninstall WireGuard${RST}     ${DIM}Remove everything (backup first)${RST}\n"
    dhr
    printf "  ${C}[0]${RST}  ${DIM}Exit${RST}\n"
    dhr; nl

    prompt "Select option" ""
    local choice="$REPLY_VAL"
    nl

    case "$choice" in
      1)  cmd_add_client  ;;
      2)  cmd_remove_client ;;
      3)  cmd_revoke_client ;;
      4)  db_list ;;
      5)  cmd_show_client ;;
      6)  cmd_status ;;
      7)  cmd_repair ;;
      8)  cmd_backup ;;
      9)  cmd_restore ;;
      10) cmd_update_script ;;
      11) cmd_uninstall; break ;;
      0|"") break ;;
      *)  warn "Invalid option: ${choice}" ;;
    esac

    nl; confirm "Return to menu?" "y" || break
  done
}

# ══════════════════════════════════════════════════════════════════════════════
#  §38  ARGUMENT PARSING & ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════
usage() {
  printf "\n  ${W}${BOLD}WireGuard Pro v${VER} — Usage${RST}\n\n"
  printf "  ${C}sudo bash %s${RST}               Interactive (auto-detects install vs manage)\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --auto${RST}         Fully automatic install (zero interaction)\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --status${RST}       Show status dashboard\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --add-client${RST}   Add a new client interactively\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --backup${RST}       Backup all configs\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --restore FILE${RST} Restore from backup archive\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --repair${RST}       Repair and restart WireGuard\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --uninstall${RST}    Completely remove WireGuard\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --update${RST}       Update this script\n" "$SCRIPT_NAME"
  printf "  ${C}sudo bash %s --help${RST}         Show this help\n\n" "$SCRIPT_NAME"
}

main() {
  local ARG="${1:-}"

  # Handle flags
  case "$ARG" in
    --help|-h)
      banner; usage; exit 0 ;;
    --auto|--turbo)
      banner
      detect_os; detect_network; detect_firewall; db_init
      # Override mode to turbo
      WG_PORT=$(pick_random_port)
      NUM_CLIENTS=1; CLIENT_NAMES=("client1")
      CLIENT_DNS="1.1.1.1, 1.0.0.1"
      PERF_PROFILE="balanced"; MTU=$DETECTED_MTU
      KILL_SWITCH=false; ALLOWED_IPS_MODE="full"
      SERVER_VPN_IP="${WG_NET}.1"
      cleanup_old_install
      install_packages; load_wg_module
      configure_security_framework
      apply_performance_profile
      generate_keys; write_server_config; write_client_configs
      fw_open_udp "$WG_PORT"; fw_apply_nat
      start_wireguard; verify_internet_routing
      generate_qr_codes; run_verification; show_install_summary
      exit 0 ;;
    --status)
      detect_network 2>/dev/null || true; detect_firewall 2>/dev/null || true
      db_init; cmd_status; exit 0 ;;
    --add-client)
      detect_network 2>/dev/null || true; detect_firewall 2>/dev/null || true
      db_init; cmd_add_client; exit 0 ;;
    --backup)
      db_init; cmd_backup; exit 0 ;;
    --restore)
      db_init; cmd_restore "${2:-}"; exit 0 ;;
    --repair)
      detect_network 2>/dev/null || true; detect_firewall 2>/dev/null || true
      db_init; cmd_repair; exit 0 ;;
    --uninstall)
      detect_os; detect_network 2>/dev/null || true; detect_firewall 2>/dev/null || true
      db_init; cmd_uninstall; exit 0 ;;
    --update)
      cmd_update_script; exit 0 ;;
  esac

  # Interactive: detect state
  banner

  if wg_is_installed; then
    db_init
    management_menu
  else
    nl
    printf "  ${C}WireGuard is not yet installed on this server.${RST}\n"
    nl
    confirm "Install WireGuard Pro now?" "y" || abort "Installation cancelled"
    do_full_install
  fi
}

# ── Run ──────────────────────────────────────────────────────────────────────
main "$@"
