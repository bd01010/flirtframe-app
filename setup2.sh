#!/usr/bin/env bash
set -e

echo "🧹 Cleaning up old MCP entries..."
for name in github openai filesystem huggingface puppeteer sequential-thinking memory apify sqlite firebase firebase-community; do
  claude mcp remove "$name" --scope local 2>/dev/null || true
done

echo "⏳ Loading .env variables..."
[ -f .env ] && { set -a; source .env; set +a; } || { echo "❌ .env missing"; exit 1; }

echo "✅ .env loaded successfully"

echo "📌 Registering MCP servers..."

# GitHub MCP (working setup)
claude mcp add github \
  npx @modelcontextprotocol/server-github \
  -e GITHUB_PERSONAL_ACCESS_TOKEN="$GH_TOKEN"
echo "→ GitHub MCP added"

# OpenAI via PyroPrompts MCP server
claude mcp add openai \
  npx @pyroprompts/any-chat-completions-mcp \
  -e AI_CHAT_KEY="$OPENAI_API_KEY" \
  -e AI_CHAT_NAME=OpenAI \
  -e AI_CHAT_MODEL=gpt-4o \
  -e AI_CHAT_BASE_URL=https://api.openai.com/v1
echo "→ OpenAI MCP added"

# Filesystem local server
claude mcp add filesystem \
  npx @modelcontextprotocol/server-filesystem /
echo "→ Filesystem MCP added"

# Hugging Face — using official HTTP endpoint
claude mcp add huggingface \
  -t http https://huggingface.co/mcp \
  -H "Authorization: Bearer $HUGGINGFACE_HUB_TOKEN"
echo "→ Hugging Face MCP added via HTTP"

# Puppeteer for browser-based automation
claude mcp add puppeteer \
  npx @modelcontextprotocol/server-puppeteer
echo "→ Puppeteer MCP added"

# Sequential thinking
claude mcp add sequential-thinking \
  npx @modelcontextprotocol/server-sequential-thinking
echo "→ Sequential Thinking MCP added"

# Memory/knowledge graph
claude mcp add memory \
  npx @modelcontextprotocol/server-memory
echo "→ Memory MCP added"

# Apify
claude mcp add apify \
  npx @apify/actors-mcp-server \
  -e APIFY_TOKEN="$APIFY_TOKEN"
echo "→ Apify MCP added"

# SQLite Database
SQLITE_DB="$(pwd)/data/grubhub_scraper.db"
mkdir -p ./data
claude mcp add sqlite \
  npx @modelcontextprotocol/server-sqlite \
  "$SQLITE_DB"
echo "→ SQLite MCP added with database: $SQLITE_DB"

# Firebase MCP (Official - recommended)
claude mcp add firebase \
  npx firebase-tools@latest experimental:mcp
echo "→ Firebase MCP (official) added"

# Optional: Firebase MCP (Community version with service account)
# Uncomment if you prefer direct service account authentication
# FIREBASE_SERVICE_ACCOUNT="$(pwd)/j111-c1573-firebase-adminsdk-fbsvc-340987efef.json"
# FIREBASE_STORAGE_BUCKET="j111-c1573.firebasestorage.app"
# claude mcp add firebase-community \
#   npx @gannonh/firebase-mcp \
#   -e SERVICE_ACCOUNT_KEY_PATH="$FIREBASE_SERVICE_ACCOUNT" \
#   -e FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET"
# echo "→ Firebase MCP (community) added with service account"

echo -e "\n🎉 Setup complete! Launch Claude to verify connections."
echo "📁 SQLite database location: $SQLITE_DB"
echo ""
echo "⚠️  Firebase Notes:"
echo "   - Official Firebase MCP requires: firebase login"
echo "   - Community version uses service account at: ./j111-c1573-firebase-adminsdk-fbsvc-340987efef.json"
echo "   - Update FIREBASE_STORAGE_BUCKET if using community version"