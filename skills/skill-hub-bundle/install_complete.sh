#!/bin/bash

# Skill Hub全家桶安装脚本 - 完整版

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
INSTALL_DIR="$HOME/.openclaw/extensions/skill-hub"
CORE_SKILLS=("skill-hub-sync" "skill-hub-submit" "skill-hub-enhanced-list")

# 显示帮助
show_help() {
    echo "Skill Hub全家桶安装脚本"
    echo ""
    echo "使用方法:"
    echo "  ./install.sh [选项]"
    echo ""
    echo "选项:"
    echo "  --help, -h     显示帮助"
    echo "  --force, -f    强制重新安装"
    echo "  --lite, -l     精简安装（仅核心）"
    echo "  --path <目录>  指定安装目录"
    echo ""
    echo "示例:"
    echo "  ./install.sh                    # 标准安装"
    echo "  ./install.sh --force            # 强制重新安装"
    echo "  ./install.sh --path /opt/skillhub  # 自定义路径"
}

# 检查依赖
check_deps() {
    echo "检查系统依赖..."
    
    local missing=()
    
    # 检查git
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "错误: 缺少以下依赖: ${missing[*]}"
        echo ""
        echo "安装方法:"
        for dep in "${missing[@]}"; do
            case $dep in
                "git")
                    echo "  macOS: brew install git"
                    echo "  Ubuntu: sudo apt install git"
                    ;;
                "curl")
                    echo "  macOS: brew install curl"
                    echo "  Ubuntu: sudo apt install curl"
                    ;;
            esac
        done
        exit 1
    fi
    
    echo "✓ 依赖检查通过"
}

# 准备目录
prepare_dir() {
    echo "准备安装目录..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/skills"
    mkdir -p "$INSTALL_DIR/cache"
    mkdir -p "$INSTALL_DIR/logs"
    
    echo "✓ 目录准备完成: $INSTALL_DIR"
}

# 下载技能
download_skills() {
    echo "下载Skill Hub仓库..."
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    # 克隆仓库
    if git clone --depth 1 "$REPO_URL" "$temp_dir" 2>/dev/null; then
        echo "✓ 仓库克隆成功"
        
        # 复制核心技能
        for skill in "${CORE_SKILLS[@]}"; do
            local src="$temp_dir/skills/$skill"
            local dest="$INSTALL_DIR/skills/$skill"
            
            if [ -d "$src" ]; then
                cp -r "$src" "$dest"
                echo "✓ 安装: $skill"
                
                # 设置权限
                find "$dest" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
                find "$dest" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
            else
                echo "⚠ 技能不存在: $skill"
            fi
        done
        
        # 复制registry
        if [ -f "$temp_dir/registry.json" ]; then
            cp "$temp_dir/registry.json" "$INSTALL_DIR/"
            echo "✓ 复制注册表"
        fi
        
        # 复制README
        if [ -f "$temp_dir/README.md" ]; then
            cp "$temp_dir/README.md" "$INSTALL_DIR/"
            echo "✓ 复制文档"
        fi
        
        rm -rf "$temp_dir"
    else
        echo "错误: 仓库克隆失败"
        exit 1
    fi
}

# 创建配置
create_config() {
    echo "创建配置文件..."
    
    cat > "$INSTALL_DIR/config.json" << EOF
{
  "installation": {
    "version": "1.0.0",
    "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "components": ["sync", "submit", "list"],
    "auto_update": true
  },
  "core_skills": {
    "sync": "skill-hub-sync",
    "submit": "skill-hub-submit",
    "list": "skill-hub-enhanced-list"
  }
}
EOF
    
    echo "✓ 配置文件创建完成"
}

# 创建环境脚本
create_env() {
    echo "配置环境..."
    
    local env_file="$HOME/.skillhub_env.sh"
    
    cat > "$env_file" << EOF
# Skill Hub环境配置
export SKILL_HUB_PATH="$INSTALL_DIR"
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-sync"
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-submit"
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-enhanced-list"
EOF
    
    # 添加到shell配置
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_rc" ] && ! grep -q "skillhub_env" "$shell_rc"; then
        echo "" >> "$shell_rc"
        echo "# Skill Hub环境" >> "$shell_rc"
        echo "source $env_file" >> "$shell_rc"
        echo "✓ 环境配置已添加到 $shell_rc"
    fi
    
    echo "✓ 环境配置完成"
}

# 创建统一命令
create_command() {
    echo "创建统一命令..."
    
    local cmd_file="$INSTALL_DIR/skillhub"
    
    cat > "$cmd_file" << 'EOF'
#!/bin/bash
# Skill Hub统一命令

SKILL_HUB="$HOME/.openclaw/extensions/skill-hub"

case "$1" in
    "sync"|"同步")
        shift
        "$SKILL_HUB/skills/skill-hub-sync/sync-simple-specific.sh" "$@"
        ;;
    "list"|"列出")
        shift
        "$SKILL_HUB/skills/skill-hub-enhanced-list/enhanced-list-compat.sh" "$@"
        ;;
    "submit"|"提交")
        shift
        "$SKILL_HUB/skills/skill-hub-submit/submit.sh" "$@"
        ;;
    "status"|"状态")
        echo "Skill Hub状态:"
        echo "  安装目录: $SKILL_HUB"
        echo "  安装时间: $(date -r "$SKILL_HUB/config.json" 2>/dev/null || echo "未知")"
        ls "$SKILL_HUB/skills/" | wc -l | xargs echo "  技能数量:"
        ;;
    "help"|"--help"|"-h")
        echo "Skill Hub命令:"
        echo "  skillhub sync <技能名>    # 同步技能"
        echo "  skillhub list             # 列出技能"
        echo "  skillhub submit <路径>    # 提交技能"
        echo "  skillhub status           # 查看状态"
        echo "  skillhub help             # 显示帮助"
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 'skillhub help' 查看帮助"
        ;;
esac
EOF
    
    chmod +x "$cmd_file"
    echo "✓ 统一命令创建完成: $cmd_file"
    
    # 尝试创建符号链接
    if command -v sudo &> /dev/null; then
        read -p "是否创建全局命令链接到 /usr/local/bin？(y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ln -sf "$cmd_file" /usr/local/bin/skillhub 2>/dev/null && \
            echo "✓ 全局命令创建完成" || \
            echo "⚠ 创建全局命令失败，请手动创建"
        fi
    fi
}

# 验证安装
verify_install() {
    echo "验证安装..."
    
    local errors=0
    
    # 检查目录
    [ -d "$INSTALL_DIR" ] || { echo "错误: 安装目录不存在"; errors=$((errors+1)); }
    [ -d "$INSTALL_DIR/skills" ] || { echo "错误: 技能目录不存在"; errors=$((errors+1)); }
    
    # 检查核心技能
    for skill in "${CORE_SKILLS[@]}"; do
        [ -d "$INSTALL_DIR/skills/$skill" ] || { echo "错误: 技能缺失: $skill"; errors=$((errors+1)); }
    done
    
    # 检查配置文件
    [ -f "$INSTALL_DIR/config.json" ] || { echo "错误: 配置文件缺失"; errors=$((errors+1)); }
    [ -f "$INSTALL_DIR/registry.json" ] || { echo "错误: 注册表缺失"; errors=$((errors+1)); }
    
    if [ $errors -eq 0 ]; then
        echo "✓ 安装验证通过"
        return 0
    else
        echo "错误: 安装验证失败 ($errors 个错误)"
        return 1
    fi
}

# 显示总结
show_summary() {
    echo ""
    echo "══════════════════════════════════════════════════════════════"
    echo "                  Skill Hub全家桶安装完成                    "
    echo "══════════════════════════════════════════════════════════════"
    echo ""
    echo "📁 安装目录: $INSTALL_DIR"
    echo "📦 安装技能: ${#CORE_SKILLS[@]} 个核心技能"
    echo ""
    echo "🚀 可用命令:"
    echo "  列出技能                    # 查看所有技能"
    echo "  同步技能 <技能名>           # 安装特定技能"
    echo "  提交技能 <路径>             # 分享你的技能"
    echo "  skillhub status             # 查看状态"
    echo ""
    echo "📚 核心功能:"
    echo "  1. 技能同步 - 从Skill Hub获取技能"
    echo "  2. 技能提交 - 分享技能到Skill Hub"
    echo "  3. 技能列表 - 智能分类和搜索"
    echo ""
    echo "🔧 下一步:"
    echo "  1. 重启终端或运行: source ~/.bashrc (或 ~/.zshrc)"
    echo "  2. 测试: 列出技能"
    echo "  3. 安装示例: 同步技能 weather"
    echo ""
    echo "🎉 安装完成！开始使用Skill Hub吧！"
    echo "══════════════════════════════════════════════════════════════"
}

# 主函数
main() {
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -f|--force)
                echo "强制重新安装..."
                rm -rf "$INSTALL_DIR"
                shift
                ;;
            -l|--lite)
                echo "精简安装模式..."
                shift
                ;;
            --path)
                INSTALL_DIR="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    echo "开始安装Skill Hub全家桶..."
    echo ""
    
    # 执行安装步骤
    check_deps
    prepare_dir
    download_skills
    create_config
    create_env
    create_command
    
    # 验证
    if verify_install; then
        show_summary
    else
        echo "安装失败，请检查错误信息"
        exit 1
    fi
}

# 运行主函数
main "$@"