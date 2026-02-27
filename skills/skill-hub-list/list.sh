#!/bin/bash

# 技能列表脚本
# 列出OpenClaw Skill Hub中所有可用技能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 配置
REPO_URL="https://github.com/guaidashu/openclaw-skill-hub.git"
CACHE_DIR="./cache"
CACHE_TTL=3600  # 1小时
REGISTRY_URL="https://raw.githubusercontent.com/guaidashu/openclaw-skill-hub/main/registry.json"

# 显示帮助
show_help() {
    echo "用法: list.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -v, --verbose    详细输出模式"
    echo "  -s, --simple     简洁输出模式（默认）"
    echo "  -o, --online     强制在线模式（忽略缓存）"
    echo "  -f, --offline    离线模式（仅使用缓存）"
    echo "  --search <关键词> 搜索技能"
    echo "  --detail <技能ID> 查看技能详情"
    echo "  --update         更新缓存"
    echo ""
    echo "示例:"
    echo "  list.sh                    # 列出所有技能"
    echo "  list.sh -v                 # 详细列表"
    echo "  list.sh --search 天气      # 搜索天气相关技能"
    echo "  list.sh --detail weather   # 查看天气技能详情"
}

# 获取技能数据
get_skills_data() {
    local mode="$1"  # online, offline, cache
    
    local cache_file="$CACHE_DIR/registry.json"
    local cache_age=0
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        cache_age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null) ))
    fi
    
    case "$mode" in
        "online")
            echo "从GitHub获取最新技能列表..."
            fetch_from_github
            ;;
        "offline")
            if [ -f "$cache_file" ]; then
                echo "使用缓存数据（最后更新: $(date -r "$cache_file" '+%Y-%m-%d %H:%M:%S')）"
                cat "$cache_file"
            else
                echo "错误: 没有缓存数据，请先使用在线模式"
                return 1
            fi
            ;;
        *)
            # 自动模式：缓存有效则使用缓存，否则从GitHub获取
            if [ -f "$cache_file" ] && [ "$cache_age" -lt "$CACHE_TTL" ]; then
                echo "使用缓存数据（最后更新: $(date -r "$cache_file" '+%Y-%m-%d %H:%M:%S')）"
                cat "$cache_file"
            else
                echo "缓存已过期或不存在，从GitHub获取..."
                fetch_from_github
            fi
            ;;
    esac
}

# 从GitHub获取数据
fetch_from_github() {
    mkdir -p "$CACHE_DIR"
    
    # 尝试直接下载registry.json
    if command -v curl &> /dev/null; then
        if curl -s -o "$CACHE_DIR/registry.tmp" "$REGISTRY_URL"; then
            mv "$CACHE_DIR/registry.tmp" "$CACHE_DIR/registry.json"
            cat "$CACHE_DIR/registry.json"
            return 0
        fi
    fi
    
    # 如果curl失败，尝试git clone
    echo "使用curl下载失败，尝试git clone..."
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if git clone --depth 1 "$REPO_URL" "$temp_dir" 2>/dev/null; then
        if [ -f "$temp_dir/registry.json" ]; then
            cp "$temp_dir/registry.json" "$CACHE_DIR/registry.json"
            cat "$CACHE_DIR/registry.json"
            rm -rf "$temp_dir"
            return 0
        fi
    fi
    
    rm -rf "$temp_dir"
    echo "错误: 无法从GitHub获取技能列表"
    return 1
}

# 解析并显示技能列表
display_skills() {
    local skills_data="$1"
    local mode="$2"  # simple, verbose
    local search_term="$3"
    
    # 提取技能数量
    local skill_count
    skill_count=$(echo "$skills_data" | grep -c '"id"' || echo "0")
    
    if [ "$skill_count" -eq 0 ]; then
        echo "没有找到技能"
        return
    fi
    
    # 提取版本信息
    local version
    version=$(echo "$skills_data" | grep '"version"' | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
    local last_updated
    last_updated=$(echo "$skills_data" | grep '"last_updated"' | head -1 | sed 's/.*"last_updated": "\([^"]*\)".*/\1/')
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              OpenClaw Skill Hub 技能列表             ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║ 版本: $version | 最后更新: ${last_updated:-未知} | 技能数量: $skill_count ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 提取并显示每个技能
    local index=1
    while IFS= read -r line; do
        # 提取技能信息
        local skill_id
        local skill_name
        local description
        local author
        local version
        
        skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
        skill_name=$(echo "$line" | sed 's/.*"name": "\([^"]*\)".*/\1/')
        description=$(echo "$line" | sed 's/.*"description": "\([^"]*\)".*/\1/')
        author=$(echo "$line" | sed 's/.*"author": "\([^"]*\)".*/\1/')
        version=$(echo "$line" | sed 's/.*"version": "\([^"]*\)".*/\1/')
        
        # 搜索过滤
        if [ -n "$search_term" ]; then
            local search_match=false
            if echo "$skill_id $skill_name $description $author" | grep -iq "$search_term"; then
                search_match=true
            fi
            if [ "$search_match" = "false" ]; then
                continue
            fi
        fi
        
        # 显示技能
        if [ "$mode" = "verbose" ]; then
            echo -e "${GREEN}技能 #$index${NC}"
            echo -e "  ${BLUE}ID:${NC} $skill_id"
            echo -e "  ${BLUE}名称:${NC} $skill_name"
            echo -e "  ${BLUE}描述:${NC} $description"
            echo -e "  ${BLUE}作者:${NC} $author"
            echo -e "  ${BLUE}版本:${NC} $version"
            echo ""
        else
            # 简洁模式
            local display_name="$skill_name"
            if [ ${#display_name} -gt 20 ]; then
                display_name="${display_name:0:17}..."
            fi
            
            local display_desc="$description"
            if [ ${#display_desc} -gt 40 ]; then
                display_desc="${display_desc:0:37}..."
            fi
            
            printf "${GREEN}%2d.${NC} %-20s ${YELLOW}(%-15s)${NC}\n" "$index" "$display_name" "$skill_id"
            printf "     %s\n" "$display_desc"
        fi
        
        index=$((index + 1))
    done < <(echo "$skills_data" | grep -E '^\s*\{' | sed 's/^ *//')
    
    echo ""
    echo -e "${CYAN}使用说明:${NC}"
    echo "  列出技能 -v              # 详细模式"
    echo "  列出技能 --detail <ID>   # 查看技能详情"
    echo "  列出技能 --search <关键词> # 搜索技能"
    echo "  同步技能                 # 获取最新技能"
}

# 显示技能详情
show_skill_detail() {
    local skills_data="$1"
    local skill_id="$2"
    
    # 查找特定技能
    local skill_block
    skill_block=$(echo "$skills_data" | awk -v id="$skill_id" '
        /^\s*\{/ { block=$0; in_block=1 }
        in_block { block=block ORS $0 }
        /^\s*\},?$/ { 
            if (block ~ "\"id\": \"" id "\"") print block
            in_block=0; block=""
        }
    ')
    
    if [ -z "$skill_block" ]; then
        echo -e "${RED}错误: 未找到技能 '$skill_id'${NC}"
        echo "使用 '列出技能' 查看所有可用技能"
        return 1
    fi
    
    # 提取详细信息
    local skill_name
    local description
    local author
    local version
    local created_at
    local updated_at
    local triggers
    local dependencies
    local path
    local downloads
    local rating
    
    skill_name=$(echo "$skill_block" | sed 's/.*"name": "\([^"]*\)".*/\1/')
    description=$(echo "$skill_block" | sed 's/.*"description": "\([^"]*\)".*/\1/')
    author=$(echo "$skill_block" | sed 's/.*"author": "\([^"]*\)".*/\1/')
    version=$(echo "$skill_block" | sed 's/.*"version": "\([^"]*\)".*/\1/')
    created_at=$(echo "$skill_block" | sed 's/.*"created_at": "\([^"]*\)".*/\1/')
    updated_at=$(echo "$skill_block" | sed 's/.*"updated_at": "\([^"]*\)".*/\1/')
    triggers=$(echo "$skill_block" | sed 's/.*"triggers": \[\([^]]*\)\].*/\1/')
    dependencies=$(echo "$skill_block" | sed 's/.*"dependencies": \[\([^]]*\)\].*/\1/')
    path=$(echo "$skill_block" | sed 's/.*"path": "\([^"]*\)".*/\1/')
    downloads=$(echo "$skill_block" | sed 's/.*"downloads": \([0-9]*\).*/\1/')
    rating=$(echo "$skill_block" | sed 's/.*"rating": \([0-9.]*\).*/\1/')
    
    # 显示详情
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   技能详情                           ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo ""
    echo -e "${GREEN}名称:${NC} $skill_name"
    echo -e "${GREEN}ID:${NC} $skill_id"
    echo -e "${GREEN}版本:${NC} $version"
    echo ""
    echo -e "${BLUE}描述:${NC}"
    echo "  $description"
    echo ""
    echo -e "${BLUE}作者:${NC} $author"
    echo -e "${BLUE}创建时间:${NC} $created_at"
    echo -e "${BLUE}最后更新:${NC} $updated_at"
    echo ""
    echo -e "${YELLOW}触发词:${NC}"
    echo "  $triggers" | sed 's/,/ /g' | sed 's/"/ /g' | sed 's/^ *//;s/ *$//' | tr ',' '\n' | sed 's/^/  • /'
    echo ""
    if [ -n "$dependencies" ] && [ "$dependencies" != "[]" ]; then
        echo -e "${YELLOW}依赖:${NC}"
        echo "  $dependencies" | sed 's/,/ /g' | sed 's/"/ /g' | sed 's/^ *//;s/ *$//' | tr ',' '\n' | sed 's/^/  • /'
        echo ""
    fi
    echo -e "${MAGENTA}路径:${NC} $path"
    echo -e "${MAGENTA}下载次数:${NC} ${downloads:-0}"
    if [ -n "$rating" ] && [ "$rating" != "0.0" ]; then
        echo -e "${MAGENTA}评分:${NC} ★★★★★ (${rating}/5.0)"
    fi
    echo ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}安装命令:${NC}"
    echo "  同步技能                  # 同步所有技能"
    echo "  同步技能 $skill_id        # 同步此技能（如果支持）"
    echo ""
    echo -e "${BLUE}使用命令:${NC}"
    echo "  $skill_id                 # 直接使用技能ID"
    echo "  [触发词]                  # 使用技能触发词"
}

# 主函数
main() {
    local mode="simple"
    local data_mode="auto"
    local search_term=""
    local detail_id=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                mode="verbose"
                shift
                ;;
            -s|--simple)
                mode="simple"
                shift
                ;;
            -o|--online)
                data_mode="online"
                shift
                ;;
            -f|--offline)
                data_mode="offline"
                shift
                ;;
            --search)
                search_term="$2"
                shift 2
                ;;
            --detail)
                detail_id="$2"
                shift 2
                ;;
            --update)
                data_mode="online"
                shift
                ;;
            -*)
                echo -e "${RED}错误: 未知选项 $1${NC}"
                show_help
                exit 1
                ;;
            *)
                # 如果没有指定选项，可能是搜索词
                if [ -z "$search_term" ] && [ -z "$detail_id" ]; then
                    search_term="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 创建缓存目录
    mkdir -p "$CACHE_DIR"
    
    # 获取技能数据
    local skills_data
    skills_data=$(get_skills_data "$data_mode")
    
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 显示结果
    if [ -n "$detail_id" ]; then
        show_skill_detail "$skills_data" "$detail_id"
    else
        display_skills "$skills_data" "$mode" "$search_term"
    fi
}

# 异常处理
trap 'echo -e "${RED}操作中断${NC}"; exit 1' INT TERM

# 运行主函数
main "$@"