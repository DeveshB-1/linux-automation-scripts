#!/bin/bash
# build_rpm.sh - Automates RPM package build and validation
# Usage: ./build_rpm.sh <spec_file> [--sign]

set -euo pipefail

SPEC_FILE=${1:-""}
SIGN=${2:-""}
BUILD_DIR="$HOME/rpmbuild"
LOG="build_$(date +%Y%m%d_%H%M%S).log"

[ -z "$SPEC_FILE" ] && { echo "Usage: $0 <spec_file>"; exit 1; }
[ ! -f "$SPEC_FILE" ] && { echo "Spec file not found: $SPEC_FILE"; exit 1; }

echo "=== RPM Build: $SPEC_FILE ===" | tee "$LOG"

# Ensure build dirs exist
mkdir -p "$BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
cp "$SPEC_FILE" "$BUILD_DIR/SPECS/"

# Install build dependencies
echo "Installing build dependencies..." | tee -a "$LOG"
sudo dnf builddep -y "$SPEC_FILE" 2>&1 | tee -a "$LOG"

# Build RPM
echo "Building RPM..." | tee -a "$LOG"
rpmbuild -ba "$BUILD_DIR/SPECS/$(basename $SPEC_FILE)" 2>&1 | tee -a "$LOG"

# Find built RPM
RPM_FILE=$(find "$BUILD_DIR/RPMS" -name "*.rpm" -newer "$SPEC_FILE" | head -1)

if [ -z "$RPM_FILE" ]; then
    echo "ERROR: RPM build failed - no package found" | tee -a "$LOG"
    exit 1
fi

echo "Built: $RPM_FILE" | tee -a "$LOG"

# Validate RPM
echo "Validating RPM..." | tee -a "$LOG"
rpm -qip "$RPM_FILE" | tee -a "$LOG"
rpm -qlp "$RPM_FILE" | tee -a "$LOG"

# Sign if requested
if [ "$SIGN" == "--sign" ]; then
    echo "Signing RPM..." | tee -a "$LOG"
    rpm --addsign "$RPM_FILE"
fi

# Run rpmlint
if command -v rpmlint &>/dev/null; then
    echo "Running rpmlint..." | tee -a "$LOG"
    rpmlint "$RPM_FILE" 2>&1 | tee -a "$LOG" || true
fi

echo "=== Build complete: $RPM_FILE ===" | tee -a "$LOG"
