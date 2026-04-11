#!/bin/bash
#
# install.sh - ~/.local/bin にシンボリックリンクを作成する
#
# Usage:
#   ./install.sh          # 対話的にツールを選択してインストール
#   ./install.sh --all    # 全ツールをインストール
#   ./install.sh --remove # リンク削除
#

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# ツール一覧（表示順を固定するため配列で管理）
TOOL_NAMES=(nippou ecs_exec db_connect aws_logs devops_agent)
declare -A TOOLS=(
    [nippou]="nippou/nippou.sh"
    [ecs_exec]="ecs-exec/ecs-exec.sh"
    [db_connect]="db-connect/db-connect.sh"
    [aws_logs]="aws-logs/aws_logs.sh"
    [devops_agent]="devops-agent/devops-agent.sh"
)

declare -A TOOL_DESC=(
    [nippou]="日報・月報生成"
    [ecs_exec]="ECS コンテナ接続"
    [db_connect]="RDS データベース接続"
    [aws_logs]="AWS ログ分析 (WAF/CF/ALB)"
    [devops_agent]="DevOps エージェント"
)

select_tools() {
    echo "インストールするツールを選択してください"
    echo "(スペース区切りで番号を入力、a で全選択)"
    echo ""

    local i=1
    for name in "${TOOL_NAMES[@]}"; do
        local src="${REPO_DIR}/${TOOLS[$name]}"
        local status=""
        if [[ -L "${BIN_DIR}/${name}" ]]; then
            status=" [インストール済み]"
        elif [[ ! -f "$src" ]]; then
            status=" [ファイルなし]"
        fi
        printf "  %d) %-15s %s%s\n" "$i" "$name" "${TOOL_DESC[$name]}" "$status"
        ((i++))
    done

    echo ""
    local input
    read -rp "番号を入力> " input

    if [[ "$input" == "a" || "$input" == "A" ]]; then
        SELECTED=("${TOOL_NAMES[@]}")
        return
    fi

    SELECTED=()
    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#TOOL_NAMES[@]} )); then
            SELECTED+=("${TOOL_NAMES[$((num - 1))]}")
        else
            echo "無効な番号をスキップ: $num" >&2
        fi
    done

    if [[ ${#SELECTED[@]} -eq 0 ]]; then
        echo "ツールが選択されませんでした"
        exit 0
    fi
}

install_link() {
    local name="$1"
    local src="${REPO_DIR}/${TOOLS[$name]}"
    local dest="${BIN_DIR}/${name}"

    if [[ ! -f "$src" ]]; then
        echo "スキップ: ${src} が見つかりません"
        return
    fi

    chmod +x "$src"

    if [[ -L "$dest" ]]; then
        echo "更新: ${name} -> ${src}"
        ln -sf "$src" "$dest"
    elif [[ -e "$dest" ]]; then
        echo "スキップ: ${dest} は既に存在します（シンボリックリンクではありません）"
    else
        echo "作成: ${name} -> ${src}"
        ln -s "$src" "$dest"
    fi
}

install_selected() {
    mkdir -p "$BIN_DIR"

    for name in "${SELECTED[@]}"; do
        install_link "$name"
    done

    check_path
    echo ""
    echo "完了"
}

install_all() {
    mkdir -p "$BIN_DIR"

    for name in "${TOOL_NAMES[@]}"; do
        install_link "$name"
    done

    check_path
    echo ""
    echo "完了"
}

remove_links() {
    for name in "${TOOL_NAMES[@]}"; do
        local dest="${BIN_DIR}/${name}"
        if [[ -L "$dest" ]]; then
            echo "削除: ${dest}"
            rm "$dest"
        fi
    done

    echo ""
    echo "完了"
}

check_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo ""
        echo "注意: ${BIN_DIR} が PATH に含まれていません。"
        echo "以下を .zshrc に追加してください:"
        echo ""
        echo '  export PATH="$HOME/.local/bin:$PATH"'
    fi
}

case "${1:-}" in
    --all)    install_all ;;
    --remove) remove_links ;;
    *)
        select_tools
        install_selected
        ;;
esac
