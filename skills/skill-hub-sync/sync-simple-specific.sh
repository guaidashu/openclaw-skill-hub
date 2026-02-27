#!/bin/bash

# 简化版指定技能同步

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
LOCAL_DIR="$HOME/.openclaw/extensions/skill-hub"

echo -e "${CYAN}OpenClaw Skill Hub 技能同步${NC}"
echo "="*50

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法: $0 [技能ID...]"
    echo "示例:"
    echo "  $0                    # 同步所有技能"
    echo "  $0 weather           # 只同步天气技能"
    echo "  $0 weather coding-agent # 同步多个技能"
    echo ""
    echo "可用技能:"
    
    # 获取技能列表
    if command -v curl &> /dev/null; then
        registry_content=$(curl -s "https://raw.githubusercontent.com/guaidashu/openclaw-skill-hub/main/registry.json")
        if [ -n "$registry_content" ]; then
            index=1
            while IFS= read -r line; do
                if echo "$line" | grep -q '"id":'; then
                    skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
                    skill_name=$(echo "$registry_content" | sed -n "/\"id\": \"$skill_id\"/,/},/p" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
                    
                    if [ -n "$skill_id" ] && [ "$skill_id" != "version" ] && [ "$skill_id" != "last_updated" ]; then
                        # 检查是否已安装
                        installed=""
                        if [ -d "$LOCAL_DIR/skills/$skill_id" ]; then
                            installed="${GREEN}[已安装]${NC}"
                        fi
                        
                        printf "  ${GREEN}%2d.${NC} %-20s ${YELLOW}(%-15s)${NC} %s\n" "$index" "$skill_name" "$skill_id" "$installed"
                        index=$((index + 1))
                    fi
                fi
            done < <(echo "$registry_content" | grep '"id":')
        fi
    fi
    
    echo ""
    echo "使用 '同步技能 [技能名]' 来同步指定技能"
    exit 0
fi

# 同步指定技能
echo "同步技能: $*"
echo ""

# 创建临时目录
TEMP_DIR="/tmp/skill-sync-$(date +%s)"
mkdir -p "$TEMP_DIR"

# 克隆仓库
echo "从GitHub获取技能..."
if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    echo -e "${GREEN}✓ 仓库克隆成功${NC}"
else
    echo -e "${RED}✗ 仓库克隆失败${NC}"
    exit 1
fi

# 创建本地目录
mkdir -p "$LOCAL_DIR/skills"

success_count=0
error_count=0

# 处理每个技能
for skill_id in "$@"; do
    echo ""
    echo -e "${BLUE}处理: $skill_id${NC}"
    
    skill_dir="$TEMP_DIR/skills/$skill_id"
    local_skill_dir="$LOCAL_DIR/skills/$skill_id"
    
    # 检查技能是否存在
    if [ ! -d "$skill_dir" ]; then
        echo -e "${RED}✗ 技能不存在: $skill_id${NC}"
        error_count=$((error_count + 1))
        continue
    fi
    
    # 检查是否已安装
    if [ -d "$local_skill_dir" ]; then
        echo -e "${YELLOW}⚠ 技能已存在，覆盖${NC}"
        rm -rf "$local_skill_dir"
    fi
    
    # 同步技能
    echo "复制技能文件..."
    mkdir -p "$local_skill_dir"
    
    if cp -r "$skill_dir"/* "$local_skill_dir"/ 2>/dev/null; then
        # 设置权限
        find "$local_skill_dir" -name "*.sh" -type f -exec chmod +x {} \;
        
        echo -e "${GREEN}✓ 同步成功: $skill_id${NC}"
        success_count=$((success_count + 1))
        
        # 显示技能信息
        if [ -f "$skill_dir/SKILL.md" ]; then
            skill_name=$(head -1 "$skill_dir/SKILL.md" | sed 's/^# SKILL.md - //')
            echo "  名称: $skill_name"
        fi
    else
        echo -e "${RED}✗ 同步失败: $skill_id${NC}"
        error_count=$((error_count + 1))
    fi
done

# 更新registry.json
if [ -f "$TEMP_DIR/registry.json" ] && [ "$success_count" -gt 0 ]; then
    echo ""
    echo "更新注册表..."
    cp "$TEMP_DIR/registry.json" "$LOCAL_DIR/registry.json"
    echo -e "${GREEN}✓ 注册表已更新${NC}"
fi

# 清理
rm -rf "$TEMP_DIR"

# 输出结果
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}同步完成${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}成功: $success_count${NC}  ${RED}失败: $error_count${NC}"
echo ""

if [ "$success_count" -gt 0 ]; then
    echo -e "${GREEN}✓ 技能已同步到: $LOCAL_DIR/skills/${NC}"
    echo ""
    echo "已同步的技能:"
    for skill_id in "$@"; do
        if [ -d "$LOCAL_DIR/skills/$skill_id" ]; then
        echo "  - $skill_id"
        fi
    done
fi

echo ""
echo -e "${BLUE}下一步:${NC}"
echo "  使用 '列出技能' 查看所有技能"
echo "  重启OpenClaw服务使新技能生效"