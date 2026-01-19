#!/usr/bin/env bash
set -euo pipefail

# Continueベンチマーク実行時のスワップ監視スクリプト
# 使用法: ./continue_bench_pack.sh <モデル名>

if [ $# -ne 1 ]; then
    echo "使用方法: $0 <モデル名>" >&2
    exit 1
fi

MODEL_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHLOGS_DIR="${SCRIPT_DIR}/../benchlogs"

# benchlogsディレクトリを作成
mkdir -p "$BENCHLOGS_DIR"

# タイムスタンプを生成
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# モデルの指紋を収集
echo "モデル指紋を収集中: $MODEL_NAME"
FINGERPRINT_FILE="${BENCHLOGS_DIR}/${TIMESTAMP}-${MODEL_NAME//\//_}.model.json"
"${SCRIPT_DIR}/ollama_fingerprint.sh" "$MODEL_NAME" > "$FINGERPRINT_FILE"
echo "指紋保存完了: $FINGERPRINT_FILE"

# 初期スワップ情報を取得
get_swap_info() {
    # vm.swapusageからスワップ使用量を取得
    swap_usage=$(sysctl vm.swapusage 2>/dev/null | grep -oE '[0-9.]+[[:space:]]*[MG]B' | head -1 | sed 's/MB//;s/GB//;s/ //g')
    
    # vm_statからpageoutsを取得
    pageouts=$(vm_stat | grep "Pageouts" | awk '{print $3}' | tr -d '.' || echo "0")
    
    echo "$swap_usage,$pageouts"
}

# スワップ監視ログファイル
SWAP_LOG="${BENCHLOGS_DIR}/${TIMESTAMP}-${MODEL_NAME//\//_}.swap.csv"
echo "timestamp,swap_used_mb,pageouts" > "$SWAP_LOG"

# 初期値を記録
INITIAL_SWAP=$(get_swap_info)
echo "$(date +%s),$INITIAL_SWAP" >> "$SWAP_LOG"

echo ""
echo "=== スワップ監視開始 ==="
echo "VS CodeのContinueで以下を実行:"
echo "1. モデルを '$MODEL_NAME' に設定"
echo "2. Agent modeで '/bench' を実行"
echo ""
echo "完了したらEnterを押してください..."

# スワップ監視ループ
while true; do
    if read -t 1 -n 1; then
        # Enterが押されたら終了
        if [ "$REPLY" = "" ]; then
            break
        fi
    fi
    
    # 1秒ごとにスワップ情報を記録
    swap_info=$(get_swap_info)
    echo "$(date +%s),$swap_info" >> "$SWAP_LOG"
    sleep 1
done

echo ""
echo "=== 監視終了 ==="

# 結果を分析
echo ""
echo "=== スワップ使用状況分析 ==="
python3 "${SCRIPT_DIR}/continue_swapreport.py" "$SWAP_LOG"

echo ""
echo "ログファイル:"
echo "- 指紋: $FINGERPRINT_FILE"
echo "- スワップ: $SWAP_LOG"