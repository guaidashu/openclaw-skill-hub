#!/bin/bash

# 简化版技能列表脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
REGISTRY_URL="https://raw.githubusercontent.com/guaidashu/openclaw-skill-hub/main/registry.json"

echo -e "${CYAN}获取技能列表...${NC}"

# 下载registry.json
if command -v curl &> /dev/null; then
    registry_content=$(curl -s "$REGISTRY_URL")
else
    echo -e "${RED}错误: 需要curl命令${NC}"
    exit 1
fi

if [ -z "$registry_content" ]; then
    echo -e "${RED}错误: 无法获取技能列表${NC}"
    exit 1
fi

# 提取技能数量
skill_count=$(echo "$registry_content" | grep -o '"id"' | wc -l)
version=$(echo "$registry_content" | grep '"version"' | head -1 | sed 's/.*"version": "\([^"]*\)".*/\1/')
last_updated=$(echo "$registry_content" | grep '"last_updated"' | head -1 | sed 's/.*"last_updated": "\([^"]*\)".*/\1/')

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}        OpenClaw Skill Hub 技能列表                  ${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo -e "版本: $version | 最后更新: ${last_updated:-未知} | 技能数量: $skill_count"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""

# 提取并显示技能
index=1
while IFS= read -r line; do
    if echo "$line" | grep -q '"id":'; then
        # 提取技能信息
        skill_id=$(echo "$line" | sed 's/.*"id": "\([^"]*\)".*/\1/')
        skill_name=$(echo "$registry_content" | sed -n "/\"id\": \"$skill_id\"/,/},/p" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
        description=$(echo "$registry_content" | sed -n "/\"id\": \"$skill_id\"/,/},/p" | grep '"description"' | sed 's/.*"description": "\([^"]*\)".*/\1/')
        
        if [ -n "$skill_id" ] && [ "$skill_id" != "version" ] && [ "$skill_id" != "last_updated" ]; then
            # 简洁显示
            printf "${GREEN}%2d.${NC} %-20s ${YELLOW}(%-15s)${NC}\n" "$index" "$skill_name" "$skill_id"
            if [ -n "$description" ]; then
                # 截断过长的描述
                if [ ${#description} -gt 50 ]; then
                    description="${description:0:47}..."
                fi
                echo "     $description"
            fi
            echo ""
            index=$((index + 1))
        fi
    fi
done < <(echo "$registry_content" | grep '"id":')

echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}使用命令:${NC}"
echo "  列出技能                    # 查看所有技能"
echo "  同步技能                    # 获取所有技能"
echo "  同步技能 [技能名]           # 获取指定技能"
echo "  搜索技能 [关键词]           # 搜索技能"
echo ""
echo -e "${GREEN}示例:${NC}"
echo "  同步技能 weather           # 获取天气技能"
echo "  同步技能 skill-hub-list    # 获取技能列表工具"
echo "  搜索技能 天气              # 搜索天气相关技能"