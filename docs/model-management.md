# Ollamaモデル管理運用ルール

## 基本方針

Ollamaモデルは大容量（数GB〜数十GB）のため、適切な管理が必要。

---

## モデル導入手順

### 1. モデルのpull

```bash
ollama pull <model-name>:<tag>
```

### 2. リポジトリ作成（必須）

```bash
cd ~/workspace-ai/nomuraya-llm
mkdir -p model-<モデル名>
cd model-<モデル名>
git init
```

### 3. README.md作成

```markdown
# <モデル名>

## 基本情報

- **モデル名**: <model-name>:<tag>
- **サイズ**: <size>GB
- **導入日**: YYYY-MM-DD
- **用途**: <用途>

## 導入コマンド

\`\`\`bash
ollama pull <model-name>:<tag>
\`\`\`

## 使用例

\`\`\`bash
ollama run <model-name>:<tag>
\`\`\`

## パフォーマンス

- **メモリ使用量**: <size>GB
- **推論速度**: <speed> tokens/sec

## 備考

<特記事項>
\`\`\`

###4. Git操作

```bash
git add .
git commit -m "初期セットアップ: <モデル名>"
gh repo create nomuraya-llm/model-<モデル名> --private
git remote add origin https://github.com/nomuraya-llm/model-<モデル名>.git
git push -u origin main
```

---

## モデル削除手順

### 1. 復元可能性確認

```bash
# モデル情報確認
ollama show <model-name>:<tag>

# リポジトリ存在確認
ls ~/workspace-ai/nomuraya-llm/model-<モデル名>
```

### 2. 削除実行

```bash
ollama rm <model-name>:<tag>
```

---

## 定期メンテナンス

### 月次: 未使用モデルの棚卸し

```bash
# モデル一覧確認
ollama list

# 30日以上使用していないモデルを特定
# （TODO: 自動化スクリプト作成）
```

### 四半期: ディスク容量確認

```bash
du -sh ~/.ollama
```

**目安**: 50GB以下を維持

---

## 復元手順

### 公式モデルの復元

```bash
ollama pull <model-name>:<tag>
```

### カスタムモデルの復元

Modelfileをリポジトリから取得して再ビルド。

---

## 更新履歴

- 2026-02-01: 初版作成（162GB→30GB削減後）
