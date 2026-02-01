#!/bin/bash
# =========================================
# Operation CRM + Ollama 完全セットアップ
# 新規環境向け統一スクリプト
# =========================================

set -e

# カラー出力
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER_OLLAMA_DIR="$(dirname "$SCRIPT_DIR")"
NOMURAYA_LLM_DIR="$(dirname "$RUNNER_OLLAMA_DIR")"
MODEL_QWEN_DIR="$NOMURAYA_LLM_DIR/model-qwen"
WORKSPACE_AI_DIR="$(dirname "$NOMURAYA_LLM_DIR")"
CRM_DIR="$WORKSPACE_AI_DIR/nomuraya-job-ai-ivr/operation-crm"

MODEL_FILE="Qwen2.5-7B-Instruct-Q4_K_M.gguf"
MODEL_SIZE="4.4GB"
HF_MODEL_URL="https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Operation CRM + Ollama 完全セットアップ${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

# ----------------------------------------
# Step 1: 前提条件確認
# ----------------------------------------
echo "📋 [1/7] 前提条件確認..."
echo

PREREQ_OK=true

check_command() {
    local cmd=$1
    local install_hint=$2
    echo -n "  $cmd: "
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗ 未インストール${NC}"
        echo "    → $install_hint"
        PREREQ_OK=false
    fi
}

check_command "node" "brew install node"
check_command "npm" "brew install node"
check_command "curl" "brew install curl"
check_command "git" "brew install git"

echo -n "  jq: "
if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}⚠ 未インストール（推奨）${NC}"
    echo "    → brew install jq"
fi

if [ "$PREREQ_OK" = false ]; then
    echo
    echo -e "${RED}前提条件を満たしていません。上記をインストールしてください。${NC}"
    exit 1
fi

echo

# ----------------------------------------
# Step 2: Ollamaインストール
# ----------------------------------------
echo "🤖 [2/7] Ollamaインストール確認..."
echo

echo -n "  Ollama: "
if command -v ollama &> /dev/null; then
    OLLAMA_VERSION=$(ollama --version 2>/dev/null | head -1)
    echo -e "${GREEN}✓ インストール済み ($OLLAMA_VERSION)${NC}"
else
    echo -e "${YELLOW}未インストール${NC}"
    echo "  Ollamaをインストールします..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install ollama
        else
            echo -e "${RED}Homebrewが必要です: https://brew.sh/${NC}"
            exit 1
        fi
    else
        curl -fsSL https://ollama.ai/install.sh | sh
    fi

    echo -e "  ${GREEN}✓ Ollamaインストール完了${NC}"
fi

echo

# ----------------------------------------
# Step 3: Ollama起動
# ----------------------------------------
echo "🔌 [3/7] Ollama起動確認..."
echo

echo -n "  Ollama API: "
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 起動中${NC}"
else
    echo -e "${YELLOW}未起動${NC}"
    echo "  Ollamaを起動します..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew services start ollama 2>/dev/null || ollama serve &
    else
        ollama serve &
    fi

    echo "  起動待機中..."
    sleep 5

    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ Ollama起動完了${NC}"
    else
        echo -e "  ${RED}✗ Ollama起動失敗${NC}"
        echo "  手動で起動してください: ollama serve"
        exit 1
    fi
fi

echo

# ----------------------------------------
# Step 4: モデルファイル確認
# ----------------------------------------
echo "📁 [4/7] モデルファイル確認..."
echo

if [ ! -d "$MODEL_QWEN_DIR" ]; then
    echo -e "  ${YELLOW}model-qwenディレクトリが存在しません${NC}"
    echo "  作成します..."
    mkdir -p "$MODEL_QWEN_DIR"
fi

MODEL_PATH="$MODEL_QWEN_DIR/$MODEL_FILE"

if [ -f "$MODEL_PATH" ]; then
    SIZE=$(ls -lh "$MODEL_PATH" | awk '{print $5}')
    echo -e "  ${GREEN}✓ モデルファイル存在 ($SIZE)${NC}"
else
    echo -e "  ${YELLOW}モデルファイルが見つかりません${NC}"
    echo
    echo "  モデルファイル（$MODEL_SIZE）のダウンロードが必要です。"
    echo
    echo "  方法1: huggingface-cliでダウンロード（推奨）"
    echo "    pip install huggingface_hub"
    echo "    cd $MODEL_QWEN_DIR"
    echo "    huggingface-cli download Qwen/Qwen2.5-7B-Instruct-GGUF \\"
    echo "      qwen2.5-7b-instruct-q4_k_m.gguf \\"
    echo "      --local-dir . --local-dir-use-symlinks False"
    echo "    mv qwen2.5-7b-instruct-q4_k_m.gguf $MODEL_FILE"
    echo
    echo "  方法2: ブラウザでダウンロード"
    echo "    URL: $HF_MODEL_URL"
    echo "    保存先: $MODEL_PATH"
    echo

    read -p "  今すぐcurlでダウンロードしますか？ (y/N): " DOWNLOAD_NOW

    if [[ "$DOWNLOAD_NOW" =~ ^[Yy]$ ]]; then
        echo "  ダウンロード中... （$MODEL_SIZE、数分かかります）"
        curl -L -o "$MODEL_PATH" "$HF_MODEL_URL" --progress-bar

        if [ -f "$MODEL_PATH" ]; then
            echo -e "  ${GREEN}✓ ダウンロード完了${NC}"
        else
            echo -e "  ${RED}✗ ダウンロード失敗${NC}"
            exit 1
        fi
    else
        echo
        echo "  モデルファイルをダウンロード後、再度このスクリプトを実行してください。"
        exit 0
    fi
fi

echo

# ----------------------------------------
# Step 5: シンボリックリンク作成
# ----------------------------------------
echo "🔗 [5/7] シンボリックリンク設定..."
echo

LINK_PATH="$RUNNER_OLLAMA_DIR/models/$MODEL_FILE"

if [ -L "$LINK_PATH" ]; then
    echo -e "  ${GREEN}✓ シンボリックリンク既存${NC}"
elif [ -f "$LINK_PATH" ]; then
    echo -e "  ${YELLOW}実ファイルが存在（シンボリックリンクではない）${NC}"
else
    mkdir -p "$RUNNER_OLLAMA_DIR/models"
    ln -sf "../../model-qwen/$MODEL_FILE" "$LINK_PATH"
    echo -e "  ${GREEN}✓ シンボリックリンク作成${NC}"
fi

echo

# ----------------------------------------
# Step 6: カスタムモデル登録
# ----------------------------------------
echo "🏗️  [6/7] カスタムモデル登録..."
echo

MODELFILE="$RUNNER_OLLAMA_DIR/configs/qwen2.5-7b.Modelfile"

if [ ! -f "$MODELFILE" ]; then
    echo -e "  ${RED}✗ Modelfileが見つかりません: $MODELFILE${NC}"
    exit 1
fi

echo "  qwen2.5-7b-crm をビルド中..."
cd "$RUNNER_OLLAMA_DIR/configs"
ollama create qwen2.5-7b-crm -f qwen2.5-7b.Modelfile

echo -e "  ${GREEN}✓ モデル登録完了${NC}"

echo

# ----------------------------------------
# Step 7: 動作確認
# ----------------------------------------
echo "🧪 [7/7] 動作確認..."
echo

echo -n "  モデル一覧: "
if ollama list | grep -q "qwen2.5-7b-crm"; then
    echo -e "${GREEN}✓ qwen2.5-7b-crm 登録済み${NC}"
else
    echo -e "${RED}✗ モデルが見つかりません${NC}"
    exit 1
fi

echo -n "  応答テスト: "
RESPONSE=$(ollama run qwen2.5-7b-crm "1+1=" --nowordwrap 2>/dev/null | head -1)
if [ -n "$RESPONSE" ]; then
    echo -e "${GREEN}✓ 成功${NC}"
    echo "    → $RESPONSE"
else
    echo -e "${RED}✗ 応答なし${NC}"
fi

echo
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}✓ セットアップ完了！${NC}"
echo -e "${BLUE}==========================================${NC}"
echo
echo "次のステップ:"
echo
echo "  1. Operation CRMセットアップ:"
echo "     cd $CRM_DIR"
echo "     bash scripts/setup.sh"
echo
echo "  2. サービス起動:"
echo "     bash scripts/start-all.sh"
echo
echo "  3. ブラウザでアクセス:"
echo "     http://localhost:3000/"
echo
