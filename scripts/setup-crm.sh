#!/bin/bash
# Operation CRM 向け Ollama セットアップスクリプト
# Qwen2.5-7B を使用したアウトバウンド支援・研修シミュレーション環境

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Operation CRM - Ollama セットアップ"
echo "=========================================="
echo

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Ollamaインストール確認
echo "📦 [1/4] Ollamaインストール確認..."
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
echo "🔌 [2/4] Ollama起動確認..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Ollama 起動中${NC}"
else
    echo -e "${YELLOW}⚠ Ollama が起動していません${NC}"
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

# 3. モデルファイル確認
echo "📁 [3/4] モデルファイル確認..."

MODEL_FILE="$ROOT_DIR/models/Qwen2.5-7B-Instruct-Q4_K_M.gguf"

if [ -L "$MODEL_FILE" ]; then
    # シンボリックリンクの場合、実体を確認
    REAL_PATH=$(readlink -f "$MODEL_FILE" 2>/dev/null || readlink "$MODEL_FILE")
    if [ -f "$REAL_PATH" ]; then
        echo -e "${GREEN}✓ モデルファイル確認（シンボリックリンク）${NC}"
        echo "  リンク: $MODEL_FILE"
        echo "  実体: $REAL_PATH"
        echo "  サイズ: $(ls -lh "$REAL_PATH" | awk '{print $5}')"
    else
        echo -e "${RED}✗ シンボリックリンクの実体が見つかりません${NC}"
        echo "  期待パス: $REAL_PATH"
        exit 1
    fi
elif [ -f "$MODEL_FILE" ]; then
    echo -e "${GREEN}✓ モデルファイル確認${NC}"
    echo "  パス: $MODEL_FILE"
    echo "  サイズ: $(ls -lh "$MODEL_FILE" | awk '{print $5}')"
else
    echo -e "${RED}✗ モデルファイルが見つかりません${NC}"
    echo "  期待パス: $MODEL_FILE"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "新規環境の場合は full-setup.sh を使用してください:"
    echo "  bash $SCRIPT_DIR/full-setup.sh"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "手動でダウンロードする場合:"
    echo
    echo "  1. model-qwenディレクトリ作成"
    echo "     mkdir -p ~/workspace-ai/nomuraya-llm/model-qwen"
    echo
    echo "  2. モデルダウンロード（約4.4GB）"
    echo "     cd ~/workspace-ai/nomuraya-llm/model-qwen"
    echo "     curl -L -o Qwen2.5-7B-Instruct-Q4_K_M.gguf \\"
    echo "       https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf"
    echo
    echo "  3. シンボリックリンク作成"
    echo "     cd $ROOT_DIR/models"
    echo "     ln -sf ../../model-qwen/Qwen2.5-7B-Instruct-Q4_K_M.gguf ."
    echo
    echo "詳細: $ROOT_DIR/INSTALL.md"
    exit 1
fi

echo

# 4. カスタムモデルをOllamaに登録
echo "🤖 [4/4] カスタムモデル (qwen2.5-7b-crm) をOllamaに登録..."

MODELFILE="$ROOT_DIR/configs/qwen2.5-7b.Modelfile"

if [ ! -f "$MODELFILE" ]; then
    echo -e "${RED}✗ Modelfileが見つかりません: $MODELFILE${NC}"
    exit 1
fi

# 既にインストール済みか確認
if ollama list | grep -q "qwen2.5-7b-crm"; then
    echo -e "${YELLOW}⚠ qwen2.5-7b-crm は既にインストール済み${NC}"
    echo "再インストールする場合: ollama rm qwen2.5-7b-crm && $0"
else
    echo "カスタムモデルをビルド中... (数分かかる場合があります)"
    cd "$ROOT_DIR/configs"
    ollama create qwen2.5-7b-crm -f qwen2.5-7b.Modelfile
    echo -e "${GREEN}✓ qwen2.5-7b-crm インストール完了${NC}"
fi

echo

# 動作テスト
echo "🧪 動作テスト..."
echo -n "Ollama応答テスト: "
TEST_RESPONSE=$(curl -s http://localhost:11434/api/generate -d '{
  "model": "qwen2.5-7b-crm",
  "prompt": "こんにちは、電気代の削減についてご提案させていただきます。",
  "stream": false
}' | jq -r '.response' 2>/dev/null)

if [ -n "$TEST_RESPONSE" ] && [ "$TEST_RESPONSE" != "null" ]; then
    echo -e "${GREEN}✓ 成功${NC}"
    echo "  応答: ${TEST_RESPONSE:0:100}..."
else
    echo -e "${RED}✗ 失敗${NC}"
    echo "  エラー詳細を確認: ollama run qwen2.5-7b-crm"
fi

echo
echo "=========================================="
echo -e "${GREEN}セットアップ完了！${NC}"
echo "=========================================="
echo
echo "Operation CRM での使用方法:"
echo
echo "  1. 環境変数を設定"
echo "     export AI_PROVIDER=ollama"
echo "     export OLLAMA_MODEL=qwen2.5-7b-crm"
echo
echo "  2. CRMサービス起動"
echo "     cd ~/workspace-ai/nomuraya-job-ai-ivr/operation-crm"
echo "     npm run dev"
echo
echo "モデル一覧: ollama list"
echo "手動テスト: ollama run qwen2.5-7b-crm"
echo
