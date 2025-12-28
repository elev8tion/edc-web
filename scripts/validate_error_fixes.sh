#!/bin/bash

# =============================================================================
# Error Fix Validation Script
# =============================================================================
#
# This script validates that all error fixes documented in docs/ERROR_FIX_PLAN.md
# have been properly implemented.
#
# Usage:
#   ./scripts/validate_error_fixes.sh
#
# Exit codes:
#   0 - All fixes validated successfully
#   1 - One or more fixes are incomplete or failing
#
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ERROR FIX VALIDATION                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

VALIDATION_PASSED=true

# =============================================================================
# Validation 1: Check for RenderingContext errors (Error 1)
# =============================================================================
echo -e "${BLUE}[1/4] Validating Error 1 Fix: RenderingContext${NC}"

FILE1="lib/core/services/device_fingerprint_service.dart"

if [ -f "$FILE1" ]; then
  # Check if dart:html is still imported
  if grep -q "import 'dart:html'" "$FILE1"; then
    echo -e "  ${RED}✗ FAIL:${NC} Still using deprecated dart:html"
    echo "         Expected: import 'package:web/web.dart'"
    VALIDATION_PASSED=false
  else
    echo -e "  ${GREEN}✓${NC} No dart:html import found"
  fi

  # Check if RenderingContext cast is still present
  if grep -q "as html.RenderingContext" "$FILE1"; then
    echo -e "  ${RED}✗ FAIL:${NC} RenderingContext cast still present"
    VALIDATION_PASSED=false
  else
    echo -e "  ${GREEN}✓${NC} RenderingContext cast removed/updated"
  fi

  # Check if package:web is imported
  if grep -q "package:web" "$FILE1"; then
    echo -e "  ${GREEN}✓${NC} Using package:web"
  else
    echo -e "  ${YELLOW}⚠${NC} package:web not imported (may be using alternative)"
  fi
else
  echo -e "  ${RED}✗ FAIL:${NC} File not found: $FILE1"
  VALIDATION_PASSED=false
fi

echo ""

# =============================================================================
# Validation 2: Check for hasAppPin method (Error 2)
# =============================================================================
echo -e "${BLUE}[2/4] Validating Error 2 Fix: hasAppPin()${NC}"

FILE2="lib/features/auth/services/secure_storage_service.dart"

if [ -f "$FILE2" ]; then
  # Check if hasAppPin method exists
  if grep -q "Future<bool> hasAppPin" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} hasAppPin() method exists"
  else
    echo -e "  ${RED}✗ FAIL:${NC} hasAppPin() method not found"
    VALIDATION_PASSED=false
  fi

  # Check if _appPinKey constant exists
  if grep -q "_appPinKey" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} _appPinKey constant defined"
  else
    echo -e "  ${RED}✗ FAIL:${NC} _appPinKey constant not defined"
    VALIDATION_PASSED=false
  fi

  # Check if setAppPin method exists
  if grep -q "Future<void> setAppPin" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} setAppPin() method exists"
  else
    echo -e "  ${YELLOW}⚠${NC} setAppPin() method not found (recommended)"
  fi
else
  echo -e "  ${RED}✗ FAIL:${NC} File not found: $FILE2"
  VALIDATION_PASSED=false
fi

echo ""

# =============================================================================
# Validation 3: Check for verifyAppPin method (Error 3)
# =============================================================================
echo -e "${BLUE}[3/4] Validating Error 3 Fix: verifyAppPin()${NC}"

if [ -f "$FILE2" ]; then
  # Check if verifyAppPin method exists
  if grep -q "Future<bool> verifyAppPin" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} verifyAppPin() method exists"
  else
    echo -e "  ${RED}✗ FAIL:${NC} verifyAppPin() method not found"
    VALIDATION_PASSED=false
  fi

  # Check if crypto package is imported (for hashing)
  if grep -q "package:crypto" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} crypto package imported for hashing"
  else
    echo -e "  ${RED}✗ FAIL:${NC} crypto package not imported (needed for PIN hashing)"
    VALIDATION_PASSED=false
  fi

  # Check if sha256 is used
  if grep -q "sha256" "$FILE2"; then
    echo -e "  ${GREEN}✓${NC} SHA-256 hashing used"
  else
    echo -e "  ${YELLOW}⚠${NC} SHA-256 not explicitly found (verify hashing method)"
  fi
else
  echo -e "  ${RED}✗ FAIL:${NC} File not found: $FILE2"
  VALIDATION_PASSED=false
fi

echo ""

# =============================================================================
# Validation 4: Check for reason parameter (Error 4)
# =============================================================================
echo -e "${BLUE}[4/4] Validating Error 4 Fix: reason parameter${NC}"

FILE3="lib/features/auth/services/biometric_service.dart"

if [ -f "$FILE3" ]; then
  # Check if authenticate method has reason parameter
  if grep -A5 "Future<bool> authenticate" "$FILE3" | grep -q "String.*reason"; then
    echo -e "  ${GREEN}✓${NC} authenticate() has reason parameter"
  else
    echo -e "  ${RED}✗ FAIL:${NC} authenticate() missing reason parameter"
    VALIDATION_PASSED=false
  fi
else
  echo -e "  ${RED}✗ FAIL:${NC} File not found: $FILE3"
  VALIDATION_PASSED=false
fi

echo ""

# =============================================================================
# Final Validation: Run Flutter Analyze on Target Files
# =============================================================================
echo -e "${BLUE}[Final] Running Flutter Analyze on target files...${NC}"

ANALYZE_FAILED=false

for file in "$FILE1" "$FILE2" "$FILE3" "lib/screens/app_lock_screen.dart"; do
  if [ -f "$file" ]; then
    # Run analyze on specific file
    RESULT=$(flutter analyze "$file" 2>&1) || true

    if echo "$RESULT" | grep -q "error •"; then
      echo -e "  ${RED}✗${NC} $file has errors"
      if [ "$VERBOSE" = true ]; then
        echo "$RESULT" | grep "error •" | head -3
      fi
      ANALYZE_FAILED=true
    else
      echo -e "  ${GREEN}✓${NC} $file passes analysis"
    fi
  fi
done

if [ "$ANALYZE_FAILED" = true ]; then
  VALIDATION_PASSED=false
fi

echo ""

# =============================================================================
# Summary
# =============================================================================
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  VALIDATION SUMMARY                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$VALIDATION_PASSED" = true ]; then
  echo -e "${GREEN}✓ ALL ERROR FIXES VALIDATED SUCCESSFULLY${NC}"
  echo ""
  echo "Next steps:"
  echo "  1. Run full test suite: flutter test"
  echo "  2. Build for web: flutter build web"
  echo "  3. Test in browser manually"
  exit 0
else
  echo -e "${RED}✗ SOME FIXES ARE INCOMPLETE${NC}"
  echo ""
  echo "Review the failed validations above and ensure all fixes are applied."
  echo "Refer to docs/ERROR_FIX_PLAN.md for implementation details."
  exit 1
fi
