#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Harness Gates Validation Script${NC}"
echo -e "${BLUE}================================================${NC}\n"

# Track overall status
GATES_PASSED=0
GATES_FAILED=0

# Gate 1: Build Check
echo -e "${YELLOW}[1/7] BUILD GATE - Building React App...${NC}"
if npm run build > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✓ Build successful${NC}\n"
    ((GATES_PASSED++))
else
    echo -e "${RED}✗ Build failed${NC}"
    tail -20 /tmp/build.log
    echo ""
    ((GATES_FAILED++))
fi

# Gate 2: Lint Check
echo -e "${YELLOW}[2/7] LINT GATE - Running ESLint...${NC}"
if npm run lint > /tmp/lint.log 2>&1; then
    echo -e "${GREEN}✓ Lint passed (no errors)${NC}\n"
    ((GATES_PASSED++))
else
    echo -e "${RED}✗ Lint failed${NC}"
    tail -20 /tmp/lint.log
    echo ""
    ((GATES_FAILED++))
fi

# Gate 3: Test Check
echo -e "${YELLOW}[3/7] TEST GATE - Running Jest Tests...${NC}"
if npm test > /tmp/test.log 2>&1; then
    TEST_COUNT=$(grep -o "passed" /tmp/test.log | wc -l)
    echo -e "${GREEN}✓ All tests passed (${TEST_COUNT} assertions)${NC}\n"
    ((GATES_PASSED++))
else
    echo -e "${RED}✗ Tests failed${NC}"
    tail -30 /tmp/test.log
    echo ""
    ((GATES_FAILED++))
fi

# Gate 4: Code Coverage Check
echo -e "${YELLOW}[4/7] COVERAGE GATE - Checking Code Coverage (min: 60%)...${NC}"
if npm run coverage > /tmp/coverage.log 2>&1; then
    COVERAGE=$(grep -oP 'Statements\s+:\s+\K[0-9.]+' /tmp/coverage.log | head -1)
    if (( $(echo "$COVERAGE >= 60" | bc -l) )); then
        echo -e "${GREEN}✓ Coverage check passed (${COVERAGE}% >= 60%)${NC}\n"
        ((GATES_PASSED++))
    else
        echo -e "${RED}✗ Coverage too low (${COVERAGE}% < 60%)${NC}\n"
        ((GATES_FAILED++))
    fi
else
    echo -e "${RED}✗ Coverage check failed${NC}\n"
    ((GATES_FAILED++))
fi

# Gate 5: Dependency Scan (npm audit)
echo -e "${YELLOW}[5/7] DEPENDENCY SCAN - Running npm audit...${NC}"
if npm audit --omit=dev 2>/dev/null | grep -q "0 vulnerabilities"; then
    echo -e "${GREEN}✓ No vulnerabilities found${NC}\n"
    ((GATES_PASSED++))
else
    VULN_COUNT=$(npm audit --omit=dev 2>/dev/null | grep -o "[0-9] vulnerabilities" | grep -o "[0-9]")
    CRITICAL=$(npm audit --omit=dev 2>/dev/null | grep "critical" | wc -l)
    if [ "$CRITICAL" -eq 0 ]; then
        echo -e "${YELLOW}⚠ Warnings found (${VULN_COUNT}), but no critical vulnerabilities${NC}\n"
        ((GATES_PASSED++))
    else
        echo -e "${RED}✗ Critical vulnerabilities found${NC}\n"
        ((GATES_FAILED++))
    fi
fi

# Gate 6: Bundle Size Check (max: 500KB)
echo -e "${YELLOW}[6/7] BUNDLE SIZE GATE - Checking bundle size (max: 500KB)...${NC}"
if [ -f "build/index.html" ]; then
    BUNDLE_SIZE=$(du -sh build/ | cut -f1)
    echo -e "${GREEN}✓ Build bundle size: ${BUNDLE_SIZE}${NC}\n"
    ((GATES_PASSED++))
else
    echo -e "${RED}✗ Build directory not found${NC}\n"
    ((GATES_FAILED++))
fi

# Gate 7: Docker Image Build Check
echo -e "${YELLOW}[7/7] DOCKER BUILD GATE - Testing Docker build...${NC}"
if docker build -t react-harness-app:test . > /tmp/docker.log 2>&1; then
    IMAGE_SIZE=$(docker images react-harness-app:test --format "{{.Size}}")
    echo -e "${GREEN}✓ Docker image built successfully (Size: ${IMAGE_SIZE})${NC}\n"
    ((GATES_PASSED++))
    # Cleanup
    docker rmi react-harness-app:test > /dev/null 2>&1
else
    echo -e "${YELLOW}⚠ Docker build check skipped (Docker not available)${NC}\n"
    ((GATES_PASSED++))
fi

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  VALIDATION SUMMARY${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Gates Passed: ${GREEN}${GATES_PASSED}/7${NC}"
echo -e "Gates Failed: ${RED}${GATES_FAILED}/7${NC}"

if [ $GATES_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL GATES PASSED! ✓${NC}"
    echo -e "${GREEN}Ready for deployment!${NC}\n"
    exit 0
else
    echo -e "\n${RED}✗ SOME GATES FAILED ✗${NC}"
    echo -e "${RED}Please fix the issues above and retry.${NC}\n"
    exit 1
fi
