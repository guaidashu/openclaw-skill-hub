#!/bin/bash

# 兼容版增强技能列表（支持旧版bash）

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# 配置
REGISTRY_URL="https://raw.githubusercontent.com/guaidashu/openclaw-skill-hub/main/registry.json"
CACHE_DIR="./cache"

# 默认设置
PAGE_SIZE=20
CURRENT_PAGE=1

# 分类关键词（简化版）
CATEGORY_KEYWORDS="
weather,temperature,forecast:生活
programming,code,development,git:开发
curl,system,file,network:工具
reminder,checkin:办公
email,document:办公
game,music,video:娱乐
learning,education,translation,research:学习
"

# 显示帮助
show_help() {
    echo "增强版技能列表 - 解决列表过长问题"
    echo "="*60
    echo ""
    echo "主要功能:"
    echo "  1. 分页显示 - 默认每页20个，避免列表过长"
    echo "  2. 分类查看 - 按类别筛选技能"
    echo "  3. 搜索过滤 - 快速找到需要的技能"
    echo "  4. 智能统计 - 显示技能分类分布"
    echo ""
    echo "常用命令:"
    echo "  列出技能                    # 分页显示（推荐）"
    echo "  列出技能 --page 2           # 查看第2页"
    echo "  列出技能 --category 工具    # 只看工具类"
    echo "  列出技能 --search 天气      # 搜索天气相关"
    echo "  列出技能 --stats            # 查看统计信息"
    echo "  列出技能 --all              # 显示全部（慎用）"
    echo ""
    echo "设计目标:"
    echo "  • 技能多了也不怕，分页显示更清晰"
    echo "  • 按分类查找，快速定位所需技能"
    echo "  • 智能搜索，支持多条件过滤"
    echo "  • 统计信息，了解技能分布情况"
    echo "="*60
}

# 获取技能数据
get_skills_data() {
    local cache_file="$CACHE_DIR/registry.json"
    
    # 创建缓存目录
    mkdir -p "$CACHE_DIR"
    
    # 检查缓存
    if [ -f "$cache_file" ]; then
        local cache_age=$(( $(date +%s) - $(stat -f%m "$cache_file" 2>/dev/null || stat -c%Y "$cache_file" 2>/dev/null) ))
        if [ "$cache_age" -lt 1800 ]; then  # 30分钟缓存
            cat "$cache_file"
            return 0
        fi
    fi
    
    # 从GitHub获取
    echo "从GitHub获取最新技能列表..."
    
    if command -v curl &> /dev/null; then
        if curl -s -o "$cache_file.tmp" "$REGISTRY_URL"; then
            mv "$cache_file.tmp" "$cache_file"
            cat "$cache_file"
            return 0
        fi
    fi
    
    echo "错误: 无法获取技能数据"
    return 1
}

# 确定技能分类
get_skill_category() {
    local name="$1"
    local description="$2"
    
    local text=$(echo "$name $description" | tr '[:upper:]' '[:lower:]')
    
    # 检查每个分类的关键词
    echo "$CATEGORY_KEYWORDS" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            local keywords=$(echo "$line" | cut -d: -f1)
            local category=$(echo "$line" | cut -d: -f2)
            
            # 检查每个关键词
            echo "$keywords" | tr ',' '\n' | while IFS= read -r keyword; do
                if echo "$text" | grep -iq "$keyword"; then
                    echo "$category"
                    return 0
                fi
            done
        fi
    done
    
    # 默认分类
    echo "其他"
}

# 显示分页技能列表
show_paged_skills() {
    local skills_data="$1"
    local page="$2"
    local page_size="$3"
    local category_filter="$4"
    local search_term="$5"
    
    # 计算分页
    local total_skills=$(echo "$skills_data" | grep -c '"id"')
    local total_pages=$(( (total_skills + page_size - 1) / page_size ))
    local start_index=$(( (page - 1) * page_size + 1 ))
    local end_index=$(( page * page_size ))
    if [ "$end_index" -gt "$total_skills" ]; then
        end_index="$total_skills"
    fi
    
    # 显示标题
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  OpenClaw Skill Hub                         ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    
    if [ -n "$category_filter" ]; then
        echo "║ 分类: $category_filter | 页码: $page/$total_pages | 技能: $start_index-$end_index/$total_skills ║"
    elif [ -n "$search_term" ]; then
        echo "║ 搜索: \"$search_term\" | 页码: $page/$total_pages | 技能: $start_index-$end_index/$total_skills ║"
    else
        echo "║ 页码: $page/$total_pages | 技能: $start_index-$end_index/$total_skills ║"
    fi
    
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # 显示技能
    local displayed=0
    local index=0
    
    while IFS= read -r line; do
        if echo "$line" | grep -q '"id":'; then
            index=$((index + 1))
            
            # 检查是否在显示范围内
            if [ "$index" -lt "$start_index" ] || [ "$index" -gt "$end_index" ]; then
                continue
            fi
            
            # 提取技能信息
            local skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
            
            # 获取技能详细信息
            local skill_block=$(echo "$skills_data" | sed -n "/\"id\": \"$skill_id\"/,/},/p")
            local skill_name=$(echo "$skill_block" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
            local description=$(echo "$skill_block" | grep '"description"' | sed 's/.*"description": "\([^"]*\)".*/\1/')
            local author=$(echo "$skill_block" | grep '"author"' | sed 's/.*"author": "\([^"]*\)".*/\1/')
            local version=$(echo "$skill_block" | grep '"version"' | sed 's/.*"version": "\([^"]*\)".*/\1/')
            
            if [ -n "$skill_id" ] && [ "$skill_id" != "version" ] && [ "$skill_id" != "last_updated" ]; then
                # 分类过滤
                if [ -n "$category_filter" ]; then
                    local category=$(get_skill_category "$skill_name" "$description")
                    if [ "$category" != "$category_filter" ]; then
                        continue
                    fi
                fi
                
                # 搜索过滤
                if [ -n "$search_term" ]; then
                    local search_text="$skill_name $description $author $skill_id"
                    if ! echo "$search_text" | grep -iq "$search_term"; then
                        continue
                    fi
                fi
                
                displayed=$((displayed + 1))
                local display_index=$(( (page - 1) * page_size + displayed ))
                
                # 获取分类
                local category=$(get_skill_category "$skill_name" "$description")
                
                # 显示技能
                printf "%3d. %-25s (%-20s)\n" "$display_index" "$skill_name" "$skill_id"
                printf "     分类: %-8s 作者: %-20s 版本: %s\n" "$category" "$author" "$version"
                
                # 截断描述
                if [ ${#description} -gt 60 ]; then
                    description="${description:0:57}..."
                fi
                echo "     $description"
                echo ""
            fi
        fi
    done < <(echo "$skills_data" | grep '"id":')
    
    # 分页信息
    echo "══════════════════════════════════════════════════════════════"
    echo "第 $page 页 / 共 $total_pages 页"
    echo "显示 $displayed 个技能 / 总计 $total_skills 个技能"
    echo ""
    
    # 导航提示
    if [ "$total_pages" -gt 1 ]; then
        echo "分页导航:"
        if [ "$page" -gt 1 ]; then
            echo "  上一页: 列出技能 --page $((page - 1))"
        fi
        if [ "$page" -lt "$total_pages" ]; then
            echo "  下一页: 列出技能 --page $((page + 1))"
        fi
        echo ""
    fi
    
    # 分类提示
    echo "分类查看:"
    echo "  列出技能 --category 工具      # 查看工具类技能"
    echo "  列出技能 --category 开发      # 查看开发类技能"
    echo "  列出技能 --category 生活      # 查看生活类技能"
    echo "  列出技能 --stats              # 查看分类统计"
    echo ""
    
    # 搜索提示
    echo "搜索技能:"
    echo "  列出技能 --search <关键词>    # 搜索技能"
    echo "  列出技能 --author <作者>      # 按作者搜索"
}

# 显示分类统计
show_category_stats() {
    local skills_data="$1"
    
    echo "技能分类统计"
    echo "="*50
    
    # 初始化分类计数
    declare -a categories=("工具" "开发" "生活" "办公" "娱乐" "学习" "其他")
    declare -a counts=(0 0 0 0 0 0 0)
    
    # 统计每个分类
    while IFS= read -r line; do
        if echo "$line" | grep -q '"id":'; then
            local skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
            
            local skill_block=$(echo "$skills_data" | sed -n "/\"id\": \"$skill_id\"/,/},/p")
            local skill_name=$(echo "$skill_block" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
            local description=$(echo "$skill_block" | grep '"description"' | sed 's/.*"description": "\([^"]*\)".*/\1/')
            
            if [ -n "$skill_id" ] && [ "$skill_id" != "version" ] && [ "$skill_id" != "last_updated" ]; then
                local category=$(get_skill_category "$skill_name" "$description")
                
                # 更新计数
                case "$category" in
                    "工具") counts[0]=$((counts[0] + 1)) ;;
                    "开发") counts[1]=$((counts[1] + 1)) ;;
                    "生活") counts[2]=$((counts[2] + 1)) ;;
                    "办公") counts[3]=$((counts[3] + 1)) ;;
                    "娱乐") counts[4]=$((counts[4] + 1)) ;;
                    "学习") counts[5]=$((counts[5] + 1)) ;;
                    *) counts[6]=$((counts[6] + 1)) ;;
                esac
            fi
        fi
    done < <(echo "$skills_data" | grep '"id":')
    
    local total_skills=$(echo "$skills_data" | grep -c '"id"')
    
    # 显示统计
    for i in "${!categories[@]}"; do
        local category="${categories[$i]}"
        local count="${counts[$i]}"
        
        if [ "$count" -gt 0 ]; then
            local percentage=$(( count * 100 / total_skills ))
            local bar=""
            local bar_length=$(( percentage / 2 ))
            
            for ((j=0; j<bar_length; j++)); do
                bar="${bar}█"
            done
            
            printf "  %-8s %3d 个 %3d%% %s\n" "$category" "$count" "$percentage" "$bar"
        fi
    done
    
    echo ""
    echo "总计: $total_skills 个技能"
    echo "="*50
}

# 主函数
main() {
    # 默认参数
    local action="list"
    local page=1
    local page_size=20
    local category=""
    local search=""
    local show_stats=false
    local show_all=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --page|-p)
                page="$2"
                shift 2
                ;;
            --page-size|-n)
                page_size="$2"
                shift 2
                ;;
            --category|-c)
                category="$2"
                shift 2
                ;;
            --search|-s)
                search="$2"
                shift 2
                ;;
            --stats)
                show_stats=true
                shift
                ;;
            --all)
                show_all=true
                page_size=1000  # 显示所有
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # 获取技能数据
    local skills_data
    skills_data=$(get_skills_data)
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # 执行相应操作
    if [ "$show_stats" = "true" ]; then
        show_category_stats "$skills_data"
    elif [ "$show_all" = "true" ]; then
        show_paged_skills "$skills_data" 1 1000 "$category" "$search"
    else
        show_paged_skills "$skills_data" "$page" "$page_size" "$category" "$search"
    fi
}

# 运行主函数
main "$@"