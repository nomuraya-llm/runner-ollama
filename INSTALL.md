# インストールガイド

他の環境でOperation CRM + Ollamaを動作させるための完全手順。

## 前提条件

| 項目 | 要件 |
|------|------|
| OS | macOS (Apple Silicon推奨) / Linux |
| メモリ | 16GB以上（8GBでも動作可能だが推奨しない） |
| ディスク | 10GB以上の空き容量 |
| Node.js | v18以上 |

## インストール手順

### Step 1: Ollamaインストール

```bash
# macOS (Homebrew)
brew install ollama

# Linux
curl -fsSL https://ollama.ai/install.sh | sh

# 確認
ollama --version
```

### Step 2: Ollamaサービス起動

```bash
# macOS: サービスとして起動（推奨）
brew services start ollama

# または手動起動
ollama serve &

# 起動確認
curl http://localhost:11434/api/tags
```

### Step 3: リポジトリクローン

```bash
cd ~/workspace-ai/nomuraya-llm

# runner-ollama
git clone https://github.com/nomuraya-llm/runner-ollama.git

# model-qwen（モデルファイル管理用）
git clone https://github.com/nomuraya-llm/model-qwen.git
```

### Step 4: モデルファイルダウンロード

モデルファイル（約4.4GB）はGitに含まれていないため、手動ダウンロードが必要です。

```bash
cd ~/workspace-ai/nomuraya-llm/model-qwen

# Hugging Faceからダウンロード
# 方法1: huggingface-cli（推奨）
pip install huggingface_hub
huggingface-cli download Qwen/Qwen2.5-7B-Instruct-GGUF \
  qwen2.5-7b-instruct-q4_k_m.gguf \
  --local-dir . \
  --local-dir-use-symlinks False

# ファイル名を統一
mv qwen2.5-7b-instruct-q4_k_m.gguf Qwen2.5-7B-Instruct-Q4_K_M.gguf

# 方法2: ブラウザからダウンロード
# https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/blob/main/qwen2.5-7b-instruct-q4_k_m.gguf
# ダウンロード後、model-qwen/ に配置してリネーム
```

### Step 5: シンボリックリンク作成

```bash
cd ~/workspace-ai/nomuraya-llm/runner-ollama/models

# シンボリックリンク作成（既に存在する場合はスキップ）
ln -sf ../../model-qwen/Qwen2.5-7B-Instruct-Q4_K_M.gguf .

# 確認
ls -la
# -> Qwen2.5-7B-Instruct-Q4_K_M.gguf -> ../../model-qwen/...
```

### Step 6: カスタムモデル登録

```bash
cd ~/workspace-ai/nomuraya-llm/runner-ollama

# CRM用セットアップスクリプト実行
bash scripts/setup-crm.sh
```

**出力例:**
```
✓ Ollama インストール済み
✓ Ollama 起動中
✓ モデルファイル確認（シンボリックリンク）
✓ qwen2.5-7b-crm インストール完了
✓ 動作テスト成功
```

### Step 7: 動作確認

```bash
# モデル一覧
ollama list
# -> qwen2.5-7b-crm:latest

# 手動テスト
ollama run qwen2.5-7b-crm "こんにちは"
```

## Operation CRMとの統合

### CRMセットアップ

```bash
cd ~/workspace-ai/nomuraya-job-ai-ivr/operation-crm

# 依存関係インストール
npm install

# 環境変数設定（.envファイル作成）
cp .env.example .env

# .env編集: AI_PROVIDER=ollama を確認
```

### CRM起動

```bash
# 全サービス起動
bash scripts/start-all.sh

# ヘルスチェック
bash scripts/health-check.sh

# ブラウザでアクセス
open http://localhost:3000/
```

## 統一セットアップスクリプト（新規環境向け）

すべてのステップを自動化したスクリプト:

```bash
bash ~/workspace-ai/nomuraya-llm/runner-ollama/scripts/full-setup.sh
```

## トラブルシューティング

### モデルファイルが見つからない

```
✗ モデルファイルが見つかりません
```

**対処:**
1. Step 4のモデルダウンロードを実行
2. ファイル名が正確か確認（大文字小文字に注意）
3. シンボリックリンクが正しいか確認

### Ollamaが起動しない

```bash
# プロセス確認
pgrep ollama

# ログ確認（macOS）
cat ~/Library/Logs/Homebrew/ollama.log

# 再起動
brew services restart ollama
```

### メモリ不足

```
Error: model requires more memory than is available
```

**対処:**
- 他のアプリケーションを終了
- より小さいモデルを使用: `ollama pull qwen2.5:3b`

### CRMがOllamaに接続できない

```bash
# Ollama起動確認
curl http://localhost:11434/api/tags

# 環境変数確認
echo $AI_PROVIDER  # -> ollama
echo $OLLAMA_MODEL # -> qwen2.5-7b-crm
```

## ディレクトリ構成（完成形）

```
~/workspace-ai/
├── nomuraya-llm/
│   ├── model-qwen/
│   │   └── Qwen2.5-7B-Instruct-Q4_K_M.gguf  # 実体（4.4GB）
│   └── runner-ollama/
│       ├── models/
│       │   └── Qwen2.5-7B-Instruct-Q4_K_M.gguf -> ../../model-qwen/...
│       ├── configs/
│       │   └── qwen2.5-7b.Modelfile
│       └── scripts/
│           ├── setup-crm.sh
│           └── full-setup.sh
└── nomuraya-job-ai-ivr/
    └── operation-crm/
        ├── .env
        └── scripts/
            └── start-all.sh
```

## 動作確認済み環境

| 環境 | スペック | 動作 |
|------|----------|------|
| Mac Studio | M2 Max / 32GB | ✅ 快適 |
| MacBook Pro | M1 Pro / 16GB | ✅ 動作 |
| MacBook Air | M1 / 8GB | ⚠️ 動作するが遅い |

## 関連ドキュメント

- [operation-crm/README.md](../../nomuraya-job-ai-ivr/operation-crm/README.md)
- [operation-crm/OPERATIONS.md](../../nomuraya-job-ai-ivr/operation-crm/OPERATIONS.md)
