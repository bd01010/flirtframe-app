#!/usr/bin/env bash

echo "🔍 Monitoring Iterative Builds..."
echo "================================"

# Function to check build status
check_build() {
    local workflow=$1
    local version=$2
    
    STATUS=$(curl -s "https://api.github.com/repos/bd01010/flirtframe-app/actions/workflows/$workflow/runs?per_page=1" | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
if data.get('workflow_runs'):
    run = data['workflow_runs'][0]
    status = run['status']
    conclusion = run['conclusion'] or 'running'
    print(f'{status}|{conclusion}')
else:
    print('no-runs|none')
" 2>/dev/null || echo "error|error")
    
    IFS='|' read -r status conclusion <<< "$STATUS"
    
    if [ "$conclusion" = "success" ]; then
        echo "✅ v$version: SUCCESS"
    elif [ "$conclusion" = "failure" ]; then
        echo "❌ v$version: FAILED"
    elif [ "$status" = "in_progress" ] || [ "$status" = "queued" ]; then
        echo "🔄 v$version: RUNNING"
    else
        echo "⏸️  v$version: Not started"
    fi
}

# Check each version
echo ""
check_build "iterative-build-v1.yml" "1 - Base App"
check_build "iterative-build-v2-fixed.yml" "2 - Photo Picker"
check_build "iterative-build-v3.yml" "3 - AI Openers"
check_build "iterative-build-v4.yml" "4 - Real Source"

echo ""
echo "📦 Download successful builds:"
echo "https://github.com/bd01010/flirtframe-app/actions"

# Show next steps
echo ""
echo "🚀 Next Steps:"
echo "1. Wait for v4 to complete"
echo "2. If v4 fails, check logs and fix issues"
echo "3. If v4 succeeds, create v5 with Firebase integration"
echo ""
echo "To trigger v3 manually:"
echo "Go to: https://github.com/bd01010/flirtframe-app/actions/workflows/iterative-build-v3.yml"
echo "Click 'Run workflow'"