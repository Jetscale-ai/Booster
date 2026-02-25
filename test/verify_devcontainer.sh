#!/bin/bash
set -euo pipefail

# Self-test for the booster-dev image when running as a non-root user
# (e.g. the `ubuntu` user used by downstream devcontainers).
# Validates that every tool the polyglot devcontainer promises is on PATH
# and responds to a version/help probe.

FAIL=0

check() {
  local name="$1" cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$name" "$(eval "$cmd" 2>&1 | head -1)"
  else
    printf '  %-12s MISSING\n' "$name"
    FAIL=1
  fi
}

echo "=== Language Toolchains ==="
check "go"       "go version"
check "node"     "node --version"
check "python3"  "python3 --version"

echo "=== Build Tools ==="
check "mage"     "mage -version"
check "poetry"   "poetry --version"
check "uv"       "uv --version"
check "pnpm"     "pnpm --version"
check "tsc"      "tsc --version"

echo "=== Platform Orchestration ==="
check "kind"     "kind version"
check "kubectl"  "kubectl version --client"
check "helm"     "helm version --short"
check "tilt"     "tilt version"

echo "=== Dev Utilities ==="
check "gh"         "gh --version"
check "gh-act"     "gh act --help"
check "starship"   "starship --version"
check "sudo"       "sudo -n true && echo ok"

echo "=== Security & Workflow Tools ==="
check "gitleaks"   "gitleaks version"
check "trivy"      "trivy --version"
check "just"       "just --version"
check "pre-commit" "pre-commit --version"

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "FAIL: one or more tools are not available."
  exit 1
fi

echo ""
echo "All devcontainer tools verified."
