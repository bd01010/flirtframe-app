#!/usr/bin/env bash

echo "🔍 Diagnosing v5 build issues..."
echo ""

# Get the latest failed v5 run
FAILED_RUN=$(curl -s "https://api.github.com/repos/bd01010/flirtframe-app/actions/runs?per_page=50" | \
    python3 -c "
import json, sys
data = json.load(sys.stdin)
for run in data.get('workflow_runs', []):
    if 'v5' in run['name'] and run['conclusion'] == 'failure':
        print(run['html_url'])
        break
")

echo "Latest v5 failure: $FAILED_RUN"
echo ""
echo "Common issues to check:"
echo "1. Swift syntax errors in Models.swift"
echo "2. Missing dependencies (types referenced but not defined)"
echo "3. iOS version compatibility"
echo "4. File path issues"
echo ""
echo "Next steps:"
echo "1. Check the logs at the URL above"
echo "2. Look for the specific error message"
echo "3. Create v5-diagnostic to test the exact issue"