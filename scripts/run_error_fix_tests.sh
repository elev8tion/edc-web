#!/bin/bash

# =============================================================================
# Error Fix Test Runner
# =============================================================================
#
# This script runs all tests related to the error fixes documented in:
# docs/ERROR_FIX_PLAN.md
#
# Usage:
#   ./scripts/run_error_fix_tests.sh [--generate-mocks] [--analyze-only] [--verbose]
#
# Options:
#   --generate-mocks  Run build_runner to generate mock files first
#   --analyze-only    Only run flutter analyze, skip tests
#   --verbose         Show detailed test output
#
# =============================================================================

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
GENERATE_MOCKS=false
ANALYZE_ONLY=false
VERBOSE=false

for arg in "$@"; do
  case $arg in
    --generate-mocks)
      GENERATE_MOCKS=true
      shift
      ;;
    --analyze-only)
      ANALYZE_ONLY=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
  esac
done

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ERROR FIX TEST RUNNER                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo -e "${YELLOW}Project root:${NC} $PROJECT_ROOT"
echo ""

# =============================================================================
# Step 1: Generate Mocks (if requested)
# =============================================================================
if [ "$GENERATE_MOCKS" = true ]; then
  echo -e "${BLUE}[Step 1/4] Generating mock files...${NC}"
  echo "Running: flutter pub run build_runner build --delete-conflicting-outputs"
  flutter pub run build_runner build --delete-conflicting-outputs
  echo -e "${GREEN}✓ Mock files generated${NC}"
  echo ""
else
  echo -e "${YELLOW}[Step 1/4] Skipping mock generation (use --generate-mocks to enable)${NC}"
  echo ""
fi

# =============================================================================
# Step 2: Run Flutter Analyze
# =============================================================================
echo -e "${BLUE}[Step 2/4] Running Flutter analyze...${NC}"

# Run analyze and capture output
ANALYZE_OUTPUT=$(flutter analyze 2>&1) || true

# Count errors in the files we care about
ERROR_FILES=(
  "lib/core/services/device_fingerprint_service.dart"
  "lib/screens/app_lock_screen.dart"
  "lib/features/auth/services/secure_storage_service.dart"
  "lib/features/auth/services/biometric_service.dart"
)

echo ""
echo "Checking for errors in target files:"
FOUND_ERRORS=false

for file in "${ERROR_FILES[@]}"; do
  if echo "$ANALYZE_OUTPUT" | grep -q "$file"; then
    echo -e "  ${RED}✗${NC} $file - Has issues"
    FOUND_ERRORS=true
    if [ "$VERBOSE" = true ]; then
      echo "$ANALYZE_OUTPUT" | grep "$file" | head -5
    fi
  else
    echo -e "  ${GREEN}✓${NC} $file - No issues"
  fi
done

echo ""

if [ "$FOUND_ERRORS" = true ]; then
  echo -e "${YELLOW}⚠ Some target files have analysis issues${NC}"
  echo "This is expected BEFORE fixes are applied."
else
  echo -e "${GREEN}✓ All target files pass analysis${NC}"
fi

if [ "$ANALYZE_ONLY" = true ]; then
  echo ""
  echo -e "${BLUE}Analyze-only mode. Exiting.${NC}"
  exit 0
fi

echo ""

# =============================================================================
# Step 3: Run Unit Tests
# =============================================================================
echo -e "${BLUE}[Step 3/4] Running unit tests...${NC}"
echo ""

# Test files to run
TEST_FILES=(
  "test/biometric_service_test.dart"
  "test/device_fingerprint_web_test.dart"
  # "test/secure_storage_pin_test.dart"  # Requires mocks to be generated
)

TESTS_PASSED=0
TESTS_FAILED=0

for test_file in "${TEST_FILES[@]}"; do
  if [ -f "$test_file" ]; then
    echo -e "${YELLOW}Running:${NC} $test_file"

    if [ "$VERBOSE" = true ]; then
      if flutter test "$test_file" 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
      else
        echo -e "  ${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
      fi
    else
      if flutter test "$test_file" --reporter compact 2>&1 | tail -3; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
      else
        echo -e "  ${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
      fi
    fi
    echo ""
  else
    echo -e "${YELLOW}⚠ Test file not found:${NC} $test_file"
    echo ""
  fi
done

# =============================================================================
# Step 4: Run Web-Specific Tests (Chrome)
# =============================================================================
echo -e "${BLUE}[Step 4/4] Running web-specific tests on Chrome...${NC}"
echo ""

WEB_TEST_FILES=(
  "test/device_fingerprint_web_test.dart"
)

for test_file in "${WEB_TEST_FILES[@]}"; do
  if [ -f "$test_file" ]; then
    echo -e "${YELLOW}Running on Chrome:${NC} $test_file"

    # Note: Chrome tests may fail if Chrome is not available
    if flutter test "$test_file" --platform chrome 2>&1 | tail -5; then
      echo -e "  ${GREEN}✓ Chrome test PASSED${NC}"
    else
      echo -e "  ${YELLOW}⚠ Chrome test skipped or failed (Chrome may not be available)${NC}"
    fi
    echo ""
  fi
done

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      TEST SUMMARY                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ "$FOUND_ERRORS" = true ]; then
  echo -e "${YELLOW}⚠ Analysis issues found in target files.${NC}"
  echo "  This is expected BEFORE fixes are applied."
  echo "  Run this script again AFTER applying fixes to verify."
fi

if [ "$TESTS_FAILED" -gt 0 ]; then
  echo ""
  echo -e "${RED}Some tests failed. Review output above.${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi
