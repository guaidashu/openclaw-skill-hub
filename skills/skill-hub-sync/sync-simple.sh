#!/bin/bash

# 简化版技能同步脚本（不需要jq）

set -e

# 配置
REPO_URL="https://github.com/guaidashu/openclaw-skill-hub.git"
TEMP_DIR="/tmp/skill-hub-simple-$(date +%s)"
LOCAL_DIR="$HOME/.openclaw/extensions/skill-hub"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}开始同步OpenClaw Skill Hub...${NC}"

# 检查git
if ! command -v git &> /dev/null; then
    echo -e "${RED}错误: git未安装${NC}"
    exit 1
fi

# 创建目录
mkdir -p "$TEMP_DIR"
mkdir -p "$LOCAL_DIR/skills"

# 克隆仓库
echo "克隆仓库..."
if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
    echo -e "${GREEN}✓ 仓库克隆成功${NC}"
else
    echo -e "${RED}✗ 仓库克隆失败${NC}"
    exit 1
fi

# 检查文件
if [ ! -f "$TEMP_DIR/registry.json" ]; then
    echo -e "${RED}错误: registry.json不存在${NC}"
    exit 1
fi

# 显示技能列表
echo -e "\n${BLUE}可用技能:${NC}"
grep '"id"' "$TEMP_DIR/registry.json" | sed 's/.*"id": "\([^"]*\)".*/\1/' | while read skill_id; do
    skill_name=$(grep -A5 "\"id\": \"$skill_id\"" "$TEMP_DIR/registry.json" | grep '"name"' | sed 's/.*"name": "\([^"]*\)".*/\1/')
    echo "  - $skill_name ($skill_id)"
done

# 复制技能
echo -e "\n${BLUE}同步技能...${NC}"
for skill_dir in "$TEMP_DIR/skills"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        echo "同步技能: $skill_name"
        mkdir -p "$LOCAL_DIR/skills/$skill_name"
        cp -r "$skill_dir"/* "$LOCAL_DIR/skills/$skill_name/" 2>/dev/null || true
    fi
done

# 复制配置文件
echo "复制配置文件..."
cp "$TEMP_DIR/registry.json" "$LOCAL_DIR/"
cp "$TEMP_DIR/members.json" "$LOCAL_DIR/"
cp "$TEMP_DIR/README.md" "$LOCAL_DIR/"

# 清理
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}✓ 技能同步完成！${NC}"
echo "技能已保存到: $LOCAL_DIR"
echo "GitHub仓库: $REPO_URL"