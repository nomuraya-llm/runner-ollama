#!/bin/bash
# Ollama + VOICEVOX 環境セットアップスクリプト

set -e

echo "=========================================="
echo "Ollama + VOICEVOX 環境セットアップ"
echo "=========================================="
echo

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Ollamaインストール確認
echo "📦 [1/5] Ollamaインストール確認..."
if command -v ollama &> /dev/null; then
    echo -e "${GREEN}✓ Ollama インストール済み${NC}"
    ollama --version
else
    echo -e "${YELLOW}⚠ Ollama が見つかりません${NC}"
    echo "インストール方法:"
    echo "  macOS: brew install ollama"
    echo "  Linux: curl -fsSL https://ollama.ai/install.sh | sh"
    exit 1
fi

echo

# 2. Ollama起動確認
echo "🔌 [2/5] Ollama起動確認..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama 起動中${NC}"
else
    echo -e "${YELLOW}⚠ Ollama が起動していません${NC}"
    echo "起動コマンド: ollama serve &"
    echo "バックグラウンドで起動中..."
    ollama serve > /dev/null 2>&1 &
    sleep 3

    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Ollama 起動成功${NC}"
    else
        echo -e "${RED}✗ Ollama 起動失敗${NC}"
        exit 1
    fi
fi

echo

# 3. 推奨モデルのインストール
echo "🤖 [3/5] 推奨モデル (phi3.5:latest) のインストール..."

# 既にインストール済みか確認
if ollama list | grep -q "phi3.5:latest"; then
    echo -e "${GREEN}✓ phi3.5:latest は既にインストール済み${NC}"
else
    echo "phi3.5:latest をダウンロード中... (約2.2GB)"
    echo "※ 初回のみ時間がかかります"
    ollama pull phi3.5:latest
    echo -e "${GREEN}✓ phi3.5:latest インストール完了${NC}"
fi

echo

# 4. VOICEVOX起動確認
echo "🔊 [4/5] VOICEVOX起動確認..."
if curl -s http://localhost:50021/speakers > /dev/null 2>&1; then
    echo -e "${GREEN}✓ VOICEVOX 起動中${NC}"

    # 利用可能な話者を表示
    echo "利用可能な話者:"
    curl -s http://localhost:50021/speakers | jq -r '.[] | "  - \(.name) (ID: \(.styles[0].id))"' | head -n 5
else
    echo -e "${YELLOW}⚠ VOICEVOX が起動していません${NC}"
    echo "VOICEVOXアプリケーションを起動してください"
    echo "ダウンロード: https://voicevox.hiroshiba.jp/"
fi

echo

# 5. 動作テスト
echo "🧪 [5/5] 動作テスト..."

# Ollamaテスト
echo -n "Ollama応答テスト: "
TEST_RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "phi3.5:latest",
  "prompt": "こんにちは",
  "stream": false
}' | jq -r '.response')

if [ -n "$TEST_RESPONSE" ]; then
    echo -e "${GREEN}✓ 成功${NC}"
    echo "  応答: ${TEST_RESPONSE:0:50}..."
else
    echo -e "${RED}✗ 失敗${NC}"
fi

echo

# VOICEVOXテスト（起動している場合のみ）
if curl -s http://localhost:50021/speakers > /dev/null 2>&1; then
    echo -n "VOICEVOX音声合成テスト: "

    # 音声クエリ作成
    QUERY=$(curl -s -X POST "http://localhost:50021/audio_query?text=テスト&speaker=1" \
        -H "Content-Type: application/json")

    if [ -n "$QUERY" ]; then
        echo -e "${GREEN}✓ 成功${NC}"
    else
        echo -e "${RED}✗ 失敗${NC}"
    fi
fi

echo
echo "=========================================="
echo -e "${GREEN}セットアップ完了！${NC}"
echo "=========================================="
echo
echo "次のステップ:"
echo "  1. 動作テストを実行: ./scripts/test-ollama.sh"
echo "  2. サンプルを試す: node examples/basic-chat.js"
echo "  3. AI-IVR統合を確認: examples/ai-ivr-integration/"
echo
echo "モデル一覧: ollama list"
echo "他のモデルをインストール: ollama pull <model-name>"
echo
