# Linux Automation Scripts

Bash/Shell automation scripts for Linux system administration — RHEL/CentOS focused.

## Scripts

| Script | Description |
|---|---|
| `system_health.sh` | System health check — CPU, memory, disk, services with alerting |
| `build_rpm.sh` | Automated RPM build, validation, and signing pipeline |
| `validate_kickstart.sh` | Kickstart configuration file validator |

## Usage

```bash
# System health check
chmod +x system_health.sh
./system_health.sh --alert-email admin@example.com

# Build RPM
./build_rpm.sh mypackage.spec --sign

# Validate Kickstart
./validate_kickstart.sh ks.cfg
```

## Stack

`Bash` `Shell` `RHEL` `CentOS` `RPM` `Kickstart` `systemd`
