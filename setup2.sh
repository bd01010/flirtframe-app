#!/usr/bin/env bash
set -e

echo "🧹 Cleaning up old MCP entries..."
for name in github openai filesystem huggingface puppeteer; do
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
  npx @modelcontextprotocol/server-everything
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

echo -e "\n🎉 Setup complete! Launch Claude to verify connections."
