#!/usr/bin/env bash
set -e

echo "🔍 Checking recent build status for FlirtFrame..."
echo ""

# Function to check GitHub CLI
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI not found. Installing..."
        
        # Try to install based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gh
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh
        else
            echo "Please install GitHub CLI manually: https://cli.github.com/"
            exit 1
        fi
    fi
    
    # Check authentication
    if ! gh auth status &> /dev/null; then
        echo "📝 Please authenticate with GitHub:"
        gh auth login
    fi
}

# Function to analyze workflow runs using API
analyze_with_api() {
    echo "📊 Analyzing builds using GitHub API..."
    
    # Get workflow runs
    RUNS=$(curl -s "https://api.github.com/repos/bd01010/flirtframe-app/actions/runs?per_page=10" | \
        python3 -c "
import json, sys
data = json.load(sys.stdin)
for run in data.get('workflow_runs', []):
    print(f\"{run['name']}|{run['status']}|{run['conclusion'] or 'pending'}|{run['id']}\")
")
    
    echo "Recent workflow runs:"
    echo "-------------------"
    echo "$RUNS" | column -t -s '|'
    echo ""
    
    # Find failed runs
    FAILED_RUN=$(echo "$RUNS" | grep "|failure|" | head -1 | cut -d'|' -f4)
    
    if [ -n "$FAILED_RUN" ]; then
        echo "❌ Found failed run: $FAILED_RUN"
        echo "Attempting to get error details..."
        
        # Try to get job details
        JOBS=$(curl -s "https://api.github.com/repos/bd01010/flirtframe-app/actions/runs/$FAILED_RUN/jobs")
        
        echo "$JOBS" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for job in data.get('jobs', []):
    if job['conclusion'] == 'failure':
        print(f\"\\n❌ Failed job: {job['name']}\")
        # The API doesn't provide logs without authentication
        print(\"   (Full logs require GitHub CLI authentication)\")
"
    fi
}

# Main execution
echo "Checking build environment..."

# Try gh CLI first
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "✅ Using GitHub CLI"
    
    # Get recent workflow runs
    echo ""
    echo "Recent workflow runs:"
    gh run list --limit 10
    
    # Get details of most recent failed run
    FAILED_RUN_ID=$(gh run list --limit 20 --json conclusion,databaseId,status | \
        python3 -c "import json,sys; runs=json.load(sys.stdin); failed=[r for r in runs if r['conclusion']=='failure']; print(failed[0]['databaseId'] if failed else '')")
    
    if [ -n "$FAILED_RUN_ID" ]; then
        echo ""
        echo "❌ Analyzing failed run: $FAILED_RUN_ID"
        
        # View the run
        gh run view "$FAILED_RUN_ID"
        
        echo ""
        echo "📋 Error logs:"
        echo "-------------"
        
        # Try to download logs
        TEMP_DIR=$(mktemp -d)
        if gh run download "$FAILED_RUN_ID" --dir "$TEMP_DIR" 2>/dev/null; then
            # Search for error patterns in logs
            find "$TEMP_DIR" -name "*.txt" -o -name "*.log" | while read log_file; do
                echo "Checking: $(basename "$log_file")"
                grep -i -E "error:|failed:|fatal:" "$log_file" | head -10 || true
            done
        else
            echo "Could not download logs. Checking job output..."
            gh run view "$FAILED_RUN_ID" --log-failed
        fi
        
        rm -rf "$TEMP_DIR"
    else
        echo "✅ No recent failures found!"
    fi
else
    echo "⚠️  GitHub CLI not available, using API..."
    analyze_with_api
fi

echo ""
echo "📝 Quick fixes to try:"
echo "1. Ensure Info.plist exists in root directory"
echo "2. Check that all Swift files compile"
echo "3. Verify Assets.xcassets directory exists"
echo "4. Make sure GoogleService-Info.plist is present (or remove Firebase)"
echo ""
echo "🔧 To trigger a new build:"
echo "   git commit --allow-empty -m 'Trigger build' && git push"