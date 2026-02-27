#!/bin/bash

# 指定技能同步脚本
# 同步特定的一个或多个技能

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
REPO_URL="https://github.com/guaidashu/openclaw-skill-hub.git"
TEMP_DIR="/tmp/skill-hub-specific-$(date +%s)"
LOCAL_DIR="$HOME/.openclaw/extensions/skill-hub"

# 显示帮助
show_help() {
    echo "用法: sync-specific.sh [选项] [技能ID...]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -l, --list       列出所有可同步的技能"
    echo "  -a, --all        同步所有技能（默认）"
    echo "  -f, --force      强制覆盖本地已存在的技能"
    echo "  -d, --dry-run    试运行，不实际同步"
    echo "  --skip-verify    跳过技能验证"
    echo ""
    echo "示例:"
    echo "  sync-specific.sh                    # 同步所有技能"
    echo "  sync-specific.sh weather            # 只同步天气技能"
    echo "  sync-specific.sh weather coding-agent # 同步多个技能"
    echo "  sync-specific.sh -l                 # 列出所有技能"
    echo "  sync-specific.sh -f weather         # 强制同步天气技能"
}

# 列出所有技能
list_skills() {
    echo -e "${CYAN}从GitHub获取技能列表...${NC}"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 克隆仓库
    if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        echo -e "${GREEN}✓ 仓库克隆成功${NC}"
    else
        echo -e "${RED}✗ 仓库克隆失败${NC}"
        return 1
    fi
    
    # 检查registry.json
    local registry_file="$TEMP_DIR/registry.json"
    if [ ! -f "$registry_file" ]; then
        echo -e "${RED}错误: registry.json不存在${NC}"
        return 1
    fi
    
    # 显示技能列表
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║             可同步的技能列表                         ║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    
    local skill_count=0
    while IFS= read -r line; do
        local skill_id
        local skill_name
        local description
        
        skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
        skill_name=$(echo "$line" | sed 's/.*"name": "\([^"]*\)".*/\1/')
        description=$(echo "$line" | sed 's/.*"description": "\([^"]*\)".*/\1/')
        
        if [ -n "$skill_id" ] && [ "$skill_id" != "{" ] && [ "$skill_id" != "}" ]; then
            skill_count=$((skill_count + 1))
            
            # 检查是否已安装
            local installed=""
            if [ -d "$LOCAL_DIR/skills/$skill_id" ]; then
                installed="${GREEN}[已安装]${NC}"
            fi
            
            echo -e "${GREEN}$skill_count. $skill_name${NC} ${YELLOW}($skill_id)${NC} $installed"
            echo "   描述: $description"
            echo ""
        fi
    done < <(grep -E '^\s*\{' "$registry_file")
    
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║ 总共: $skill_count 个技能                            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "使用示例:"
    echo "  sync-specific.sh weather          # 同步天气技能"
    echo "  sync-specific.sh skill-hub-sync   # 同步技能同步工具"
    echo "  sync-specific.sh                  # 同步所有技能"
    
    # 清理
    rm -rf "$TEMP_DIR"
}

# 同步特定技能
sync_specific_skills() {
    local skill_ids=("$@")
    local force="$1"
    local dry_run="$2"
    local skip_verify="$3"
    
    echo -e "${CYAN}开始同步指定技能...${NC}"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 克隆仓库
    echo "从GitHub克隆仓库..."
    if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        echo -e "${GREEN}✓ 仓库克隆成功${NC}"
    else
        echo -e "${RED}✗ 仓库克隆失败${NC}"
        return 1
    fi
    
    # 检查registry.json
    local registry_file="$TEMP_DIR/registry.json"
    if [ ! -f "$registry_file" ]; then
        echo -e "${RED}错误: registry.json不存在${NC}"
        return 1
    fi
    
    # 创建本地目录
    mkdir -p "$LOCAL_DIR/skills"
    
    local success_count=0
    local skip_count=0
    local error_count=0
    
    # 处理每个技能
    for skill_id in "${skill_ids[@]}"; do
        echo ""
        echo -e "${BLUE}处理技能: $skill_id${NC}"
        
        # 检查技能是否存在
        local skill_dir="$TEMP_DIR/skills/$skill_id"
        if [ ! -d "$skill_dir" ]; then
            echo -e "${RED}✗ 技能不存在: $skill_id${NC}"
            error_count=$((error_count + 1))
            continue
        fi
        
        # 检查是否已安装
        local local_skill_dir="$LOCAL_DIR/skills/$skill_id"
        if [ -d "$local_skill_dir" ]; then
            if [ "$force" = "true" ]; then
                echo -e "${YELLOW}⚠ 技能已存在，强制覆盖${NC}"
            else
                echo -e "${YELLOW}⚠ 技能已存在，跳过${NC}"
                skip_count=$((skip_count + 1))
                continue
            fi
        fi
        
        # 验证技能（如果启用）
        if [ "$skip_verify" != "true" ]; then
            echo "验证技能格式..."
            if [ -f "$skill_dir/SKILL.md" ]; then
                echo -e "${GREEN}✓ 找到 SKILL.md${NC}"
            else
                echo -e "${RED}✗ 缺少 SKILL.md，跳过${NC}"
                error_count=$((error_count + 1))
                continue
            fi
        fi
        
        # 执行同步
        if [ "$dry_run" = "true" ]; then
            echo "[试运行] 将同步技能: $skill_id"
            echo "  源目录: $skill_dir"
            echo "  目标目录: $local_skill_dir"
            success_count=$((success_count + 1))
        else
            echo "同步技能文件..."
            
            # 创建目标目录
            mkdir -p "$local_skill_dir"
            
            # 复制文件
            if cp -r "$skill_dir"/* "$local_skill_dir"/ 2>/dev/null; then
                # 设置权限
                find "$local_skill_dir" -name "*.sh" -type f -exec chmod +x {} \;
                
                echo -e "${GREEN}✓ 技能同步成功: $skill_id${NC}"
                success_count=$((success_count + 1))
                
                # 显示技能信息
                if [ -f "$skill_dir/SKILL.md" ]; then
                    local skill_name
                    skill_name=$(head -1 "$skill_dir/SKILL.md" | sed 's/^# SKILL.md - //')
                    echo "  名称: $skill_name"
                fi
            else
                echo -e "${RED}✗ 技能同步失败: $skill_id${NC}"
                error_count=$((error_count + 1))
            fi
        fi
    done
    
    # 更新registry.json
    if [ "$dry_run" != "true" ] && [ "$success_count" -gt 0 ]; then
        echo ""
        echo "更新本地注册表..."
        cp "$registry_file" "$LOCAL_DIR/registry.json"
        echo -e "${GREEN}✓ 注册表已更新${NC}"
    fi
    
    # 清理
    rm -rf "$TEMP_DIR"
    
    # 输出结果
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}同步完成${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}成功: $success_count${NC}  ${YELLOW}跳过: $skip_count${NC}  ${RED}失败: $error_count${NC}"
    echo ""
    
    if [ "$success_count" -gt 0 ]; then
        echo -e "${GREEN}✓ 技能已同步到: $LOCAL_DIR/skills/${NC}"
        echo ""
        echo "使用技能:"
        for skill_id in "${skill_ids[@]}"; do
            if [ -d "$LOCAL_DIR/skills/$skill_id" ]; then
                echo "  - $skill_id"
            fi
        done
    fi
    
    if [ "$dry_run" = "true" ]; then
        echo ""
        echo -e "${YELLOW}注意: 这是试运行，没有实际同步文件${NC}"
    fi
}

# 同步所有技能
sync_all_skills() {
    echo -e "${CYAN}同步所有技能...${NC}"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 克隆仓库
    echo "从GitHub克隆仓库..."
    if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
        echo -e "${GREEN}✓ 仓库克隆成功${NC}"
    else
        echo -e "${RED}✗ 仓库克隆失败${NC}"
        return 1
    fi
    
    # 获取所有技能ID
    local registry_file="$TEMP_DIR/registry.json"
    local skill_ids=()
    
    while IFS= read -r line; do
        local skill_id
        skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
        if [ -n "$skill_id" ] && [ "$skill_id" != "{" ] && [ "$skill_id" != "}" ]; then
            skill_ids+=("$skill_id")
        fi
    done < <(grep -E '^\s*\{' "$registry_file")
    
    echo "找到 ${#skill_ids[@]} 个技能"
    
    # 同步所有技能
    sync_specific_skills "${skill_ids[@]}"
}

# 主函数
main() {
    local list_mode=false
    local sync_all=false
    local force=false
    local dry_run=false
    local skip_verify=false
    local skill_ids=()
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -l|--list)
                list_mode=true
                shift
                ;;
            -a|--all)
                sync_all=true
                shift
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            --skip-verify)
                skip_verify=true
                shift
                ;;
            -*)
                echo -e "${RED}错误: 未知选项 $1${NC}"
                show_help
                exit 1
                ;;
            *)
                skill_ids+=("$1")
                shift
                ;;
        esac
    done
    
    # 执行相应操作
    if [ "$list_mode" = "true" ]; then
        list_skills
    elif [ "$sync_all" = "true" ] || [ ${#skill_ids[@]} -eq 0 ]; then
        sync_all_skills
    else
        sync_specific_skills "${skill_ids[@]}" "$force" "$dry_run" "$skip_verify"
    fi
}

# 异常处理
trap 'echo -e "${RED}同步中断${NC}"; rm -rf "$TEMP_DIR"; exit 1' INT TERM

# 运行主函数
main "$@"