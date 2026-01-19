#!/usr/bin/env python3
"""
Continueスワップログ解析スクリプト
スワップ使用状況を分析し、OK/NG判定を行う
"""

import sys
import csv
from pathlib import Path

def analyze_swap_log(csv_file):
    """スワップログを解析する"""
    try:
        with open(csv_file, 'r') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
        
        if len(rows) < 2:
            print("エラー: データが不足しています")
            return False
        
        # 初期値と最終値を取得
        initial_swap = float(rows[0]['swap_used_mb'])
        final_swap = float(rows[-1]['swap_used_mb'])
        initial_pageouts = int(rows[0]['pageouts'])
        final_pageouts = int(rows[-1]['pageouts'])
        
        # 増分を計算
        swap_increase = final_swap - initial_swap
        pageouts_increase = final_pageouts - initial_pageouts
        
        print(f"初期スワップ使用量: {initial_swap:.1f} MB")
        print(f"最終スワップ使用量: {final_swap:.1f} MB")
        print(f"スワップ増加量: {swap_increase:.1f} MB")
        print(f"初期ページアウト: {initial_pageouts}")
        print(f"最終ページアウト: {final_pageouts}")
        print(f"ページアウト増加: {pageouts_increase}")
        
        # 判定基準
        # - スワップ増加 > 100MB: NG
        # - ページアウト増加 > 1000: NG
        # - どちらも条件を満たさなければ OK
        
        is_ng = False
        
        if swap_increase > 100:
            print(f"⚠️  スワップ使用量が {swap_increase:.1f} MB 増加 (閾値: 100MB)")
            is_ng = True
        
        if pageouts_increase > 1000:
            print(f"⚠️  ページアウトが {pageouts_increase} 回増加 (閾値: 1000)")
            is_ng = True
        
        if is_ng:
            print("\n🔴 判定: NG (メモリプレッシャー検出)")
            print("   → より軽量なモデルの使用を検討してください")
        else:
            print("\n🟢 判定: OK (メモリ使用安定)")
            print("   → 現在のモデル設定で問題ありません")
        
        return True
        
    except FileNotFoundError:
        print(f"エラー: ファイル '{csv_file}' が見つかりません")
        return False
    except Exception as e:
        print(f"エラー: 解析中にエラーが発生しました: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("使用方法: python3 continue_swapreport.py <swap_log.csv>")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    if not analyze_swap_log(csv_file):
        sys.exit(1)