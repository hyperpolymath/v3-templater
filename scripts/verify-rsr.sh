#!/usr/bin/env bash
# RSR Compliance Verification Script
# Checks v3-templater against Rhodium Standard Repository framework

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0
WARN=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARN++))
}

check_file() {
    if [ -f "$1" ]; then
        check_pass "$2"
        return 0
    else
        check_fail "$2 (missing: $1)"
        return 1
    fi
}

echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RSR Compliance Verification - v3-templater${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""

# Category 1: Type Safety
echo -e "${BLUE}[1/13] Type Safety${NC}"
if [ -f "tsconfig.json" ] && grep -q '"strict": true' tsconfig.json; then
    check_pass "TypeScript strict mode enabled"
else
    check_fail "TypeScript strict mode not enabled"
fi

# Category 2: Memory Safety
echo -e "\n${BLUE}[2/13] Memory Safety${NC}"
check_pass "Garbage collected (JavaScript/TypeScript)"

# Category 3: Offline-first
echo -e "\n${BLUE}[3/13] Offline-first${NC}"
if ! grep -r "fetch\|axios\|http.get" src/ 2>/dev/null | grep -v "test\|mock" > /dev/null; then
    check_pass "No network calls in core code"
else
    check_warn "Network calls detected (may not be offline-first)"
fi

# Category 4: Documentation
echo -e "\n${BLUE}[4/13] Documentation${NC}"
check_file "README.md" "README.md exists"
check_file "CONTRIBUTING.md" "CONTRIBUTING.md exists"
check_file "CHANGELOG.md" "CHANGELOG.md exists"
check_file "docs/API.md" "API documentation exists"

# Category 5: License
echo -e "\n${BLUE}[5/13] License${NC}"
check_file "LICENSE" "MIT License exists"
check_file "LICENSE-PALIMPSEST.txt" "Palimpsest v0.8 dual license exists"

# Category 6: Security
echo -e "\n${BLUE}[6/13] Security${NC}"
check_file "SECURITY.md" "SECURITY.md exists"
check_file ".well-known/security.txt" "RFC 9116 security.txt exists"

# Category 7: Code of Conduct
echo -e "\n${BLUE}[7/13] Code of Conduct${NC}"
check_file "CODE_OF_CONDUCT.md" "CODE_OF_CONDUCT.md exists"

# Category 8: Maintainers & TPCF
echo -e "\n${BLUE}[8/13] Maintainers & TPCF${NC}"
check_file "MAINTAINERS.md" "MAINTAINERS.md exists"
if grep -q "Perimeter 3" MAINTAINERS.md 2>/dev/null; then
    check_pass "TPCF Perimeter 3 (Community Sandbox) declared"
else
    check_fail "TPCF perimeter not declared"
fi

# Category 9: .well-known/ directory
echo -e "\n${BLUE}[9/13] .well-known/ Directory${NC}"
check_file ".well-known/security.txt" "security.txt (RFC 9116)"
check_file ".well-known/ai.txt" "ai.txt (AI training policy)"
check_file ".well-known/humans.txt" "humans.txt (attribution)"

# Category 10: Build System
echo -e "\n${BLUE}[10/13] Build System${NC}"
check_file "package.json" "package.json exists"
check_file "justfile" "justfile exists"
if [ -f "flake.nix" ]; then
    check_pass "flake.nix exists (Nix reproducible builds)"
else
    check_warn "flake.nix missing (Gold level requirement)"
fi

# Category 11: CI/CD
echo -e "\n${BLUE}[11/13] CI/CD${NC}"
if [ -f ".github/workflows/ci.yml" ]; then
    check_pass "GitHub Actions CI/CD configured"
elif [ -f ".gitlab-ci.yml" ]; then
    check_pass "GitLab CI/CD configured"
else
    check_fail "No CI/CD configuration found"
fi

# Category 12: Tests
echo -e "\n${BLUE}[12/13] Tests${NC}"
if [ -d "src/__tests__" ] || [ -d "test" ] || [ -d "tests" ]; then
    check_pass "Test directory exists"
else
    check_fail "No test directory found"
fi

if [ -f "jest.config.js" ]; then
    check_pass "Jest configured"
fi

# Category 13: Dependencies
echo -e "\n${BLUE}[13/13] Dependencies${NC}"
if command -v npm &> /dev/null; then
    PROD_DEPS=$(npm ls --prod --depth=0 2>/dev/null | grep -c "─" || echo "0")
    if [ "$PROD_DEPS" -le 3 ]; then
        check_pass "Minimal dependencies ($PROD_DEPS production deps)"
    else
        check_warn "Many dependencies ($PROD_DEPS production deps)"
    fi
else
    check_warn "npm not available, cannot check dependencies"
fi

# Summary
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "✅ Passed:  ${GREEN}$PASS${NC}"
echo -e "❌ Failed:  ${RED}$FAIL${NC}"
echo -e "⚠️  Warnings: ${YELLOW}$WARN${NC}"
echo ""

# Determine compliance level
TOTAL=$((PASS + FAIL))
PERCENTAGE=$((PASS * 100 / TOTAL))

echo -e "Compliance Rate: ${GREEN}${PERCENTAGE}%${NC}"
echo ""

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    echo -e "🏆 ${GREEN}RSR Compliance Level: GOLD${NC} ✨"
    echo "   All requirements met!"
    exit 0
elif [ "$PERCENTAGE" -ge 85 ] && [ "$FAIL" -le 2 ]; then
    echo -e "🥈 ${GREEN}RSR Compliance Level: SILVER${NC} ⭐"
    echo "   Most requirements met, minor improvements needed"
    exit 0
elif [ "$PERCENTAGE" -ge 70 ]; then
    echo -e "🥉 ${YELLOW}RSR Compliance Level: BRONZE${NC} 📋"
    echo "   Basic requirements met, improvements recommended"
    exit 0
else
    echo -e "❌ ${RED}RSR Compliance Level: BELOW BRONZE${NC}"
    echo "   Significant improvements needed"
    exit 1
fi
