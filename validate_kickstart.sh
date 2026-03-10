#!/bin/bash
# validate_kickstart.sh - Validates Kickstart configuration files
# Usage: ./validate_kickstart.sh <ks_file>

set -euo pipefail

KS_FILE=${1:-""}
ERRORS=0

[ -z "$KS_FILE" ] && { echo "Usage: $0 <kickstart_file>"; exit 1; }
[ ! -f "$KS_FILE" ] && { echo "File not found: $KS_FILE"; exit 1; }

check() {
    if grep -q "$2" "$KS_FILE"; then
        echo "  [OK] $1"
    else
        echo "  [MISSING] $1: $2"
        ((ERRORS++))
    fi
}

echo "=== Validating Kickstart: $KS_FILE ==="

# Required sections
check "install/url method" "^url\|^install"
check "root password" "^rootpw"
check "timezone" "^timezone"
check "bootloader" "^bootloader"
check "partition setup" "^part\|^autopart"
check "packages section" "^%packages"
check "post section" "^%post"

# Security checks
echo ""
echo "Security checks:"
grep -q "^firewall" "$KS_FILE" && echo "  [OK] Firewall configured" || echo "  [WARN] No firewall config"
grep -q "^selinux" "$KS_FILE" && echo "  [OK] SELinux configured" || echo "  [WARN] No SELinux config"
grep -q "^sshpwauth" "$KS_FILE" && echo "  [OK] SSH password auth set" || echo "  [INFO] No SSH password auth setting"

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "Validation PASSED"
    exit 0
else
    echo "Validation FAILED: $ERRORS missing required sections"
    exit 1
fi
