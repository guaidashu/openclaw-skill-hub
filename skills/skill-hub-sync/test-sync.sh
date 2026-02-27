#!/bin/bash

# 简化版测试脚本
echo "测试技能同步脚本..."
echo "当前目录: $(pwd)"
echo "GitHub仓库: https://github.com/guaidashu/openclaw-skill-hub.git"

# 检查基本依赖
echo "检查依赖:"
which git && echo "✓ git已安装" || echo "✗ git未安装"
which curl && echo "✓ curl已安装" || echo "✗ curl未安装"

# 创建测试目录
TEST_DIR="/tmp/skill-hub-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

echo "克隆测试仓库..."
git clone --depth 1 https://github.com/guaidashu/openclaw-skill-hub.git "$TEST_DIR" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ 仓库克隆成功"
    echo "文件列表:"
    ls -la "$TEST_DIR"
    
    echo "registry.json内容:"
    cat "$TEST_DIR/registry.json" | head -20
    
    echo "members.json内容:"
    cat "$TEST_DIR/members.json" | head -10
else
    echo "✗ 仓库克隆失败"
fi

# 清理
rm -rf "$TEST_DIR"
echo "测试完成"