#!/bin/bash
set -e
echo "Verifying Polyglot Environment..."

# Run artifacts if they exist (smoke testing)
# The Dockerfile renames artifacts to smoke-go, smoke-ts.js, smoke-py.py
# and sed is used to replace app- with smoke- if needed, but we use smoke- directly.

if [ -f "./smoke-go" ]; then
    echo "Running Go smoke test..."
    ./smoke-go
elif [ -f "./app-go" ]; then
    echo "Running Go smoke test (app-go)..."
    ./app-go
fi

if [ -f "./smoke-ts.js" ]; then
    echo "Running TS smoke test..."
    node ./smoke-ts.js
elif [ -f "./app-ts.js" ]; then
    echo "Running TS smoke test (app-ts.js)..."
    node ./app-ts.js
fi

if [ -f "./smoke-py.py" ]; then
    echo "Running Python smoke test..."
    python3 ./smoke-py.py
elif [ -f "./app-py.py" ]; then
    echo "Running Python smoke test (app-py.py)..."
    python3 ./app-py.py
fi

echo "Polyglot verification passed"
