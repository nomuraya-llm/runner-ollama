# Ollama + VOICEVOX 統合環境

完全無料のローカルLLM・TTS環境構築リポジトリ

## 概要

このリポジトリは、以下の完全無料なローカルAI環境を構築・管理します：

- **Ollama**: ローカルLLM実行環境（対話AI）
- **VOICEVOX**: 日本語音声合成エンジン（TTS）

APIキー不要、レート制限なし、完全にオフラインで動作可能です。

## 動作確認済み環境

- **マシン**: Mac Studio (M2 Max)
- **メモリ**: 32GB
- **OS**: macOS
- **Ollama**: v0.x
- **VOICEVOX**: 0.14.x

## クイックスタート

### 1. 環境構築（ワンコマンド）

```bash
./scripts/setup.sh
```

このスクリプトが以下を自動実行します：
- Ollamaのインストール確認
- 推奨モデル（Phi-3.5-mini）のダウンロード
- VOICEVOXの起動確認
- 動作テスト

### 2. サービス起動

```bash
# Ollama起動（バックグラウンド）
ollama serve &

# VOICEVOX起動（アプリケーションから起動、またはCLI）
# ※ 既に起動済みの場合はスキップ
```

### 3. 動作確認

```bash
./scripts/test-ollama.sh
```

## 使用可能なモデル

### 推奨モデル

| モデル | サイズ | メモリ | 特徴 | 用途 |
|--------|--------|--------|------|------|
| **phi3.5:latest** | 2.2GB | 3GB | 軽量、日本語対応 | デモ、開発 |
| **llama3.2:3b** | 2.0GB | 3GB | 高速、英語強い | テスト |

### 高性能モデル（メモリ8GB以上推奨）

| モデル | サイズ | メモリ | 特徴 | 用途 |
|--------|--------|--------|------|------|
| **qwen2.5:7b** | 4.7GB | 8GB | 高品質、多言語 | 本番 |
| **gemma2:9b** | 5.4GB | 10GB | Google製、高精度 | 本番 |

詳細は [docs/models.md](docs/models.md) を参照。

## プロジェクト統合例

### AI-IVR（AI電話応答システム）

完全無料化の実装例：

```typescript
// Ollama統合
import { OllamaClient } from './examples/ai-ivr-integration/ollama-client';

const client = new OllamaClient('http://localhost:11434');
const response = await client.chat('こんにちは');

// VOICEVOX統合
import { VoicevoxClient } from './examples/ai-ivr-integration/voicevox-client';

const tts = new VoicevoxClient('http://localhost:50021');
const audio = await tts.speak('こんにちは', 1); // speaker_id: 1 (四国めたん)
```

詳細は [examples/ai-ivr-integration/](examples/ai-ivr-integration/) を参照。

## ディレクトリ構成

```
nomuraya-llm/ollama/
├── README.md                    # このファイル
├── docs/
│   ├── setup.md                # 詳細セットアップガイド
│   ├── models.md               # モデル選択ガイド
│   └── integration.md          # 他プロジェクトとの統合方法
├── scripts/
│   ├── setup.sh                # 環境構築スクリプト
│   ├── test-ollama.sh          # 動作テストスクリプト
│   └── benchmark.sh            # 性能ベンチマーク
├── configs/
│   ├── phi3.5-mini.modelfile   # Phi-3.5-mini設定
│   └── voicevox.json           # VOICEVOX設定
├── examples/
│   ├── basic-chat.js           # 基本的なチャット例
│   ├── streaming.js            # ストリーミング応答例
│   └── ai-ivr-integration/     # AI-IVR統合サンプル
│       ├── ollama-client.ts    # Ollamaクライアント
│       ├── voicevox-client.ts  # VOICEVOXクライアント
│       └── demo.html           # 統合デモページ
└── .github/
    └── workflows/
        └── test.yml            # CI: 動作確認テスト
```

## よくある質問

### Q: Ollamaが起動しない

```bash
# Ollamaのステータス確認
curl http://localhost:11434/api/tags

# 起動
ollama serve
```

### Q: VOICEVOXが起動しない

VOICEVOXアプリケーションを起動してください。
- macOS: アプリケーションフォルダから起動
- デフォルトポート: 50021

```bash
# ステータス確認
curl http://localhost:50021/speakers
```

### Q: メモリ不足エラー

より軽量なモデルを使用してください：
```bash
ollama pull phi3.5:latest  # 2.2GB
```

### Q: 日本語の精度が低い

日本語特化モデルを試してください：
```bash
ollama pull qwen2.5:7b  # 日本語強化
```

## 関連リンク

- [Ollama公式サイト](https://ollama.ai/)
- [VOICEVOX公式サイト](https://voicevox.hiroshiba.jp/)
- [AI-IVRプロジェクト](https://github.com/nomuraya-entertainment/AI-IVR)

## ライセンス

MIT License

## 貢献

Issue、Pull Requestを歓迎します。

---

生成日: 2026-01-07
