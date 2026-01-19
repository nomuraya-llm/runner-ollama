#!/usr/bin/env bash
set -euo pipefail

# Ollamaモデルの指紋を収集するスクリプト
# 使用法: ./ollama_fingerprint.sh <モデル名>
# 出力: JSON形式

if [ $# -ne 1 ]; then
    echo "使用方法: $0 <モデル名>" >&2
    exit 1
fi

MODEL_NAME="$1"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# 初期JSON構造
json_output=$(cat <<EOF
{
  "ts": "$TIMESTAMP",
  "model": "$MODEL_NAME",
  "digest": "",
  "size": "",
  "modified": "",
  "parameter_size": "",
  "quantization": "",
  "family": "",
  "format": "",
  "architecture": "",
  "context_length": "",
  "modelfile_sha256": ""
}
EOF
)

# ollama listから情報を取得
if list_output=$(ollama list 2>/dev/null | grep -F "$MODEL_NAME"); then
    # digestを抽出 (sha256:から始まる部分)
    digest=$(echo "$list_output" | grep -oE 'sha256:[a-f0-9]{64}' || echo "")
    
    # sizeを抽出 (GB/MB表記)
    size=$(echo "$list_output" | grep -oE '[0-9.]+[[:space:]]*[GM]B' || echo "")
    
    # modifiedを抽出 (最後のカラム)
    modified=$(echo "$list_output" | awk 'NF>1{print $NF}' || echo "")
    
    # JSONを更新
    json_output=$(echo "$json_output" | jq --arg d "$digest" --arg s "$size" --arg m "$modified" \
        '.digest = $d | .size = $s | .modified = $m')
fi

# ollama showから詳細情報を取得
if show_output=$(ollama show "$MODEL_NAME" 2>/dev/null); then
    # parameter_sizeを抽出
    parameter_size=$(echo "$show_output" | grep -i "parameters" | head -1 | sed 's/.*parameters[[:space:]]*//' | tr -d ' ' || echo "")
    
    # quantizationを抽出
    quantization=$(echo "$show_output" | grep -i "quantization" | head -1 | sed 's/.*quantization[[:space:]]*//' | tr -d ' ' || echo "")
    
    # familyを抽出
    family=$(echo "$show_output" | grep -i "family" | head -1 | sed 's/.*family[[:space:]]*//' | tr -d ' ' || echo "")
    
    # formatを抽出
    format=$(echo "$show_output" | grep -i "format" | head -1 | sed 's/.*format[[:space:]]*//' | tr -d ' ' || echo "")
    
    # architectureを抽出
    architecture=$(echo "$show_output" | grep -i "architecture" | head -1 | sed 's/.*architecture[[:space:]]*//' | tr -d ' ' || echo "")
    
    # context_lengthを抽出
    context_length=$(echo "$show_output" | grep -i "context length" | head -1 | sed 's/.*context length[[:space:]]*//' | tr -d ' ' || echo "")
    
    # JSONを更新
    json_output=$(echo "$json_output" | jq --arg p "$parameter_size" --arg q "$quantization" --arg f "$family" \
        --arg fmt "$format" --arg a "$architecture" --arg c "$context_length" \
        '.parameter_size = $p | .quantization = $q | .family = $f | .format = $fmt | .architecture = $a | .context_length = $c')
fi

# modelfileのSHA256を計算
if modelfile=$(ollama show "$MODEL_NAME" --modelfile 2>/dev/null); then
    modelfile_sha256=$(echo "$modelfile" | shasum -a 256 | cut -d' ' -f1)
    json_output=$(echo "$json_output" | jq --arg m "$modelfile_sha256" '.modelfile_sha256 = $m')
fi

# 結果を出力
echo "$json_output"