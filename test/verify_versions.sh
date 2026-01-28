#!/bin/bash
set -e

# Expected Versions (Update these when bumping Dockerfile ARGs)
EXPECTED_GO_MAJOR="1"
EXPECTED_GO_MINOR="25"
EXPECTED_NODE_MAJOR="20"
EXPECTED_PYTHON_MAJOR="3"

echo "Auditing toolchain versions..."

# --- GO CHECK ---
if command -v go >/dev/null 2>&1; then
  GO_FULL=$(go version | awk '{print $3}') # e.g., go1.25.4
  GO_VER=${GO_FULL#go}
  IFS='.' read -r G_MAJ G_MIN G_PAT <<< "$GO_VER"

  if [[ "$G_MAJ" == "$EXPECTED_GO_MAJOR" && "$G_MIN" == "$EXPECTED_GO_MINOR" ]]; then
    echo "Go: $GO_VER (matches ${EXPECTED_GO_MAJOR}.${EXPECTED_GO_MINOR})"
  else
    echo "Go: found $GO_VER, expected ${EXPECTED_GO_MAJOR}.${EXPECTED_GO_MINOR}"
    exit 1
  fi
else
  echo "Go not found (skip)"
fi

# --- NODE CHECK ---
if command -v node >/dev/null 2>&1; then
  NODE_FULL=$(node --version) # e.g., v20.10.0
  NODE_VER=${NODE_FULL#v}
  IFS='.' read -r N_MAJ N_MIN N_PAT <<< "$NODE_VER"

  if [[ "$N_MAJ" == "$EXPECTED_NODE_MAJOR" ]]; then
    echo "Node: $NODE_VER (matches ${EXPECTED_NODE_MAJOR})"
  else
    echo "Node: found $NODE_VER, expected major ${EXPECTED_NODE_MAJOR}"
    exit 1
  fi
else
  echo "Node not found (skip)"
fi

# --- PYTHON CHECK ---
if command -v python3 >/dev/null 2>&1; then
  PY_FULL=$(python3 --version | awk '{print $2}') # e.g., 3.12.1
  IFS='.' read -r P_MAJ P_MIN P_PAT <<< "$PY_FULL"

  if [[ "$P_MAJ" == "$EXPECTED_PYTHON_MAJOR" ]]; then
    echo "Python: $PY_FULL (matches ${EXPECTED_PYTHON_MAJOR})"
  else
    echo "Python: found $PY_FULL, expected major ${EXPECTED_PYTHON_MAJOR}"
    exit 1
  fi
else
  echo "Python not found (skip)"
fi

echo "Specification audit passed."
