#!/bin/bash
# Ollama動作テストスクリプト

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Ollama 動作テスト"
echo "=========================================="
echo

# 1. 接続テスト
echo "🔌 [1/4] 接続テスト..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama に接続できました${NC}"
else
    echo -e "${RED}✗ Ollama に接続できません${NC}"
    echo "Ollamaが起動していることを確認してください: ollama serve"
    exit 1
fi

echo

# 2. モデル一覧
echo "📋 [2/4] インストール済みモデル:"
ollama list

echo

# 3. 簡単な応答テスト
echo "💬 [3/4] 応答テスト (phi3.5:latest)..."
echo "質問: 「こんにちは、自己紹介してください」"
echo

RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "phi3.5:latest",
  "prompt": "こんにちは、自己紹介してください。簡潔に1文で答えてください。",
  "stream": false
}' | jq -r '.response')

if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓ 応答成功${NC}"
    echo "応答: $RESPONSE"
else
    echo -e "${RED}✗ 応答失敗${NC}"
    exit 1
fi

echo

# 4. 日本語会話テスト
echo "🇯🇵 [4/4] 日本語会話テスト..."
echo "質問: 「東京の観光地を3つ教えて」"
echo

RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "phi3.5:latest",
  "prompt": "東京の有名な観光地を3つ挙げてください。それぞれ1行で簡潔に説明してください。",
  "stream": false
}' | jq -r '.response')

if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓ 応答成功${NC}"
    echo "応答:"
    echo "$RESPONSE"
else
    echo -e "${RED}✗ 応答失敗${NC}"
    exit 1
fi

echo
echo "=========================================="
echo -e "${GREEN}すべてのテストが成功しました！${NC}"
echo "=========================================="
echo
echo "次のステップ:"
echo "  - サンプルコードを試す: examples/basic-chat.js"
echo "  - AI-IVR統合: examples/ai-ivr-integration/"
echo
