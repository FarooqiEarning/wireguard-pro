# Contributing to WireGuard Pro

Thank you for wanting to make WireGuard Pro better for everyone! 🎉

## Ways to Contribute

- **Bug reports** — open an Issue with full details
- **New OS support** — add a `_pkg_xxx` function in §8
- **Performance tuning** — improve sysctl/qdisc settings in §13
- **New features** — see ideas below
- **Documentation** — improve README, add examples
- **Testing** — test on a new distro and report results

## Bug Reports

Please include:
1. Your OS and version (`cat /etc/os-release`)
2. Kernel version (`uname -r`)
3. Cloud provider (AWS, GCP, etc.)
4. The full log: `cat /var/log/wireguard-pro.log`
5. Output of: `sudo wg show` and `sudo iptables -L -n`

## Pull Request Guidelines

1. Fork the repo, create a branch: `git checkout -b feature/my-feature`
2. Keep functions in the correct § section
3. Test on at least Ubuntu LTS and CentOS/Rocky
4. Run `bash -n wireguard-pro.sh` — must show "Syntax OK"
5. Run `shellcheck wireguard-pro.sh` and fix warnings
6. Update version number in `VER="x.x.x"` if needed
7. Describe what you changed and why in the PR

## Feature Ideas

- [ ] Web dashboard for client management
- [ ] Telegram/email notification when client connects
- [ ] Prometheus metrics exporter
- [ ] Multi-interface support (wg0, wg1, wg2...)
- [ ] WireGuard over TCP (for restrictive firewalls)
- [ ] Automatic Let's Encrypt DNS endpoint
- [ ] Per-client bandwidth limiting
- [ ] Client expiry / auto-revoke
- [ ] IPv6-only server support
- [ ] FreeBSD / macOS server support

## Code Style

- Use `printf` not `echo -e` for portability
- Always `local` your variables in functions
- Quote all variable expansions: `"$var"` not `$var`
- Use `|| true` for non-critical commands that might fail
- Comment every § section header

## Testing Checklist

Before submitting a PR, verify:
- [ ] `bash -n wireguard-pro.sh` passes
- [ ] Fresh install works on Ubuntu 22.04
- [ ] Fresh install works on CentOS/Rocky 9
- [ ] Add client works without restarting the service
- [ ] Remove client properly cleans up server config
- [ ] Backup/restore round-trip works
- [ ] `--auto` flag works with zero interaction
- [ ] `--repair` fixes a deliberately broken setup

## Questions?

Open a Discussion or Issue — we're friendly! 😊
