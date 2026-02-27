#!/bin/bash

# Skill Hub全家桶安装脚本
# 一键安装Skill Hub核心功能

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
REPO_URL="https://github.com/guaidashu/openclaw-skill-hub.git"
INSTALL_DIR="$HOME/.openclaw/extensions/skill-hub"
TEMP_DIR="/tmp/skill-hub-install-$$"
CONFIG_FILE="$INSTALL_DIR/config.json"
LOG_FILE="/tmp/skill-hub-install.log"

# 核心技能列表
CORE_SKILLS=("skill-hub-sync" "skill-hub-submit" "skill-hub-enhanced-list")

# 显示标题
show_title() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               OpenClaw Skill Hub 全家桶安装                ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示步骤
show_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

# 显示成功
show_success() {
    echo -e "  ${GREEN}✓ $1${NC}"
}

# 显示警告
show_warning() {
    echo -e "  ${YELLOW}⚠ $1${NC}"
}

# 显示错误
show_error() {
    echo -e "  ${RED}✗ $1${NC}"
}

# 检查依赖
check_dependencies() {
    show_step "检查系统依赖"
    
    local missing_deps=()
    
    # 检查git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    else
        show_success "git 已安装"
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    else
        show_success "curl 已安装"
    fi
    
    # 检查bash版本
    if [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
        show_warning "Bash版本较低 (${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]})，建议升级到4.0+"
    else
        show_success "Bash版本符合要求"
    fi
    
    # 检查OpenClaw目录
    if [ ! -d "$HOME/.openclaw" ]; then
        show_warning "未找到OpenClaw目录，将自动创建"
    else
        show_success "OpenClaw目录存在"
    fi
    
    # 如果有缺失的依赖
    if [ ${#missing_deps[@]} -gt 0 ]; then
        show_error "缺少以下依赖: ${missing_deps[*]}"
        echo ""
        echo "请安装缺失的依赖:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "git")
                    echo "  macOS: brew install git"
                    echo "  Ubuntu/Debian: sudo apt-get install git"
                    echo "  CentOS/RHEL: sudo yum install git"
                    ;;
                "curl")
                    echo "  macOS: brew install curl"
                    echo "  Ubuntu/Debian: sudo apt-get install curl"
                    echo "  CentOS/RHEL: sudo yum install curl"
                    ;;
            esac
        done
        echo ""
        read -p "是否继续安装？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo ""
}

# 准备安装目录
prepare_directories() {
    show_step "准备安装目录"
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    show_success "创建临时目录: $TEMP_DIR"
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    show_success "创建安装目录: $INSTALL_DIR"
    
    # 创建子目录
    mkdir -p "$INSTALL_DIR/skills"
    mkdir -p "$INSTALL_DIR/cache"
    mkdir -p "$INSTALL_DIR/logs"
    show_success "创建子目录结构"
    
    echo ""
}

# 克隆Skill Hub仓库
clone_repository() {
    show_step "克隆Skill Hub仓库"
    
    if [ -d "$TEMP_DIR/repo" ]; then
        rm -rf "$TEMP_DIR/repo"
    fi
    
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        show_success "仓库克隆成功"
    else
        show_error "仓库克隆失败"
        exit 1
    fi
    
    echo ""
}

# 安装核心技能
install_core_skills() {
    show_step "安装核心技能"
    
    local installed_count=0
    local failed_count=0
    
    for skill in "${CORE_SKILLS[@]}"; do
        local skill_src="$TEMP_DIR/repo/skills/$skill"
        local skill_dest="$INSTALL_DIR/skills/$skill"
        
        if [ -d "$skill_src" ]; then
            # 复制技能文件
            cp -r "$skill_src" "$skill_dest" 2>/dev/null || true
            
            # 设置执行权限
            find "$skill_dest" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            find "$skill_dest" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
            
            show_success "安装: $skill"
            installed_count=$((installed_count + 1))
        else
            show_warning "技能不存在: $skill"
            failed_count=$((failed_count + 1))
        fi
    done
    
    # 复制registry.json
    if [ -f "$TEMP_DIR/repo/registry.json" ]; then
        cp "$TEMP_DIR/repo/registry.json" "$INSTALL_DIR/"
        show_success "复制技能注册表"
    fi
    
    # 复制README
    if [ -f "$TEMP_DIR/repo/README.md" ]; then
        cp "$TEMP_DIR/repo/README.md" "$INSTALL_DIR/"
        show_success "复制文档"
    fi
    
    echo ""
    echo -e "安装统计: ${GREEN}成功 $installed_count${NC} / ${RED}失败 $failed_count${NC}"
    echo ""
}

# 创建配置文件
create_config() {
    show_step "创建配置文件"
    
    cat > "$CONFIG_FILE" << EOF
{
  "installation": {
    "version": "1.0.0",
    "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "components": ["sync", "submit", "list"],
    "auto_update": true,
    "update_frequency": 86400
  },
  "paths": {
    "skills_dir": "$INSTALL_DIR/skills",
    "cache_dir": "$INSTALL_DIR/cache",
    "log_dir": "$INSTALL_DIR/logs",
    "registry": "$INSTALL_DIR/registry.json"
  },
  "repository": {
    "url": "$REPO_URL",
    "branch": "main",
    "last_updated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "core_skills": {
    "sync": "skill-hub-sync",
    "submit": "skill-hub-submit", 
    "list": "skill-hub-enhanced-list",
    "installed": true
  },
  "features": {
    "enable_auto_sync": true,
    "enable_notifications": true,
    "enable_analytics": false,
    "enable_backup": true
  }
}
EOF
    
    show_success "配置文件已创建: $CONFIG_FILE"
    echo ""
}

# 创建环境配置
create_environment() {
    show_step "配置运行环境"
    
    # 创建bash配置文件
    local bash_config="$HOME/.skillhub_env.sh"
    
    cat > "$bash_config" << EOF
#!/bin/bash
# Skill Hub环境配置

export SKILL_HUB_PATH="$INSTALL_DIR"
export SKILL_HUB_REPO="$REPO_URL"
export SKILL_HUB_REGISTRY="$INSTALL_DIR/registry.json"
export SKILL_HUB_CACHE="$INSTALL_DIR/cache"
export SKILL_HUB_LOGS="$INSTALL_DIR/logs"

# 添加到PATH
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-sync"
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-submit"
export PATH="\$PATH:$INSTALL_DIR/skills/skill-hub-enhanced-list"

# 别名
alias skillhub-sync="cd $INSTALL_DIR && ./skills/skill-hub-sync/sync-simple.sh"
alias skillhub-list="cd $INSTALL_DIR && ./skills/skill-hub-enhanced-list/enhanced-list-compat.sh"
alias skillhub-status="cat $INSTALL_DIR/config.json | jq '.installation'"

echo "Skill Hub环境已加载"
EOF
    
    chmod +x "$bash_config"
    show_success "环境配置文件: $bash_config"
    
    # 添加到bashrc/zshrc
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi
    
    if [ -f "$shell_rc" ]; then
        if ! grep -q "skillhub_env" "$shell_rc"; then
            echo "" >> "$shell_rc"
            echo "# Skill Hub环境配置" >> "$shell_rc"
            echo "source $bash_config" >> "$shell_rc"
            show_success "已添加到 $shell_rc"
        else
            show_success "已在 $shell_rc 中配置"
        fi
    fi
    
    echo ""
}

# 创建快捷命令
create_shortcuts() {
    show_step "创建快捷命令"
    
    # 创建skillhub命令
    local skillhub_cmd="$INSTALL_DIR/skillhub"
    
    cat > "$skillhub_cmd" << 'EOF'
#!/bin/bash
# Skill Hub统一命令接口

set -e

SKILL_HUB_PATH="$HOME/.openclaw/extensions/skill-hub"
CONFIG_FILE="$SKILL_HUB_PATH/config.json"

show_help() {
    echo "Skill Hub命令工具"
    echo ""
    echo "使用方法:"
    echo "  skillhub [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  sync      同步技能"
    echo "  list      列出技能"
    echo "  submit    提交技能"
    echo "  status    查看状态"
    echo "  update    更新Skill Hub"
    echo "  help      显示帮助"
    echo ""
    echo "示例:"
    echo "  skillhub sync weather"
    echo "  skillhub list --category 工具"
    echo "  skillhub status"
}

case "$1" in
    "sync"|"同步")
        shift
        "$SKILL_HUB_PATH/skills/skill-hub-sync/sync-simple-specific.sh" "$@"
        ;;
    "list"|"列出"|"列表")
        shift
        "$SKILL_HUB_PATH/skills/skill-hub-enhanced-list/enhanced-list-compat.sh" "$@"
        ;;
    "submit"|"提交")
        shift
        "$SKILL_HUB_PATH/skills/skill-hub-submit/submit.sh" "$@"
        ;;
    "status"|"状态")
        if command -v jq &> /dev/null; then
            jq '.installation' "$CONFIG_FILE"
        else
            grep -A5 '"installation"' "$CONFIG_FILE"
        fi
        ;;
    "update"|"更新")
        echo "更新功能开发中..."
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "未知命令: $1"
        echo "使用 'skillhub help' 查看帮助"
        exit 1
        ;;
esac
EOF
    
    chmod +x "$skillhub_cmd"
    show_success "创建统一命令: skillhub"
    
    # 创建符号链接到/usr/local/bin（需要sudo）
    if command -v sudo &> /dev/null; then
        read -p "是否创建全局命令链接？(需要sudo权限) (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo ln -sf "$skillhub_cmd" /usr/local/bin/skillhub 2>/dev/null && \
            show_success "创建全局命令: /usr/local/bin/skillhub" || \
            show_warning "创建全局命令失败，请手动创建"
        fi
    fi
    
    echo ""
}

# 验证安装
verify_installation() {
    show_step "验证安装结果"
    
    local errors=0
    
    # 检查目录
    if [ ! -d "$INSTALL_DIR" ]; then
        show_error "安装目录不存在"
        errors=$((errors + 1))
    else
        show_success "安装目录存在"
    fi
    
    # 检查配置文件
    if [ ! -f "$CONFIG_FILE" ]; then
        show_error "配置文件不存在"
        errors=$((errors + 1))
    else
        show_success "配置文件存在"
    fi
    
    # 检查核心技能
    for skill in "${CORE_SKILLS[@]}"; do
        if [ ! -d "$INSTALL_DIR/skills/$skill" ]; then
            show_error "技能缺失: $skill"
            errors=$((errors + 1))
        else
            show_success "技能存在: $skill"
        fi
    done
    
    # 检查registry
    if [ ! -f "$INSTALL_DIR/registry.json" ]; then
        show_error "注册表文件缺失"
        errors=$((errors + 1))
    else
        show_success "注册表文件存在"
    fi
    
    echo ""
    
    if [ $errors -eq 0 ]; then
        show_success "✅ 安装验证通过"
        return 0
    else
        show_error "❌ 安装验证失败 ($errors 个错误)"
        return 1
    fi
}

# 显示安装总结
show_summary() {
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                   安装完成总结                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${WHITE}📁 安装目录:${NC} $INSTALL_DIR"
    echo -e "${WHITE}⚙️  配置文件:${NC} $CONFIG_FILE"
    echo -e "${WHITE}📦 安装技能:${NC} ${#CORE_SKILLS[@]} 个核心技能"
    echo ""
    
    echo -e "${WHITE}🚀 可用命令:${NC}"
    echo "  列出技能                    # 查看所有可用技能"
    echo "  同步技能 <技能名>           # 安装特定技能"
    echo "  提交技能 <路径>             # 分享你的技能"
    echo "  skillhub status             # 查看Skill Hub状态"
    echo ""
    
    echo -e "${WHITE}📚 核心功能:${NC}"
    echo "  1. 技能同步 - 从Skill Hub获取最新技能"
    echo "  2. 技能提交 - 分享你的创作到Skill Hub"
    echo "  3. 技能列表 - 智能分类和搜索技能"
    echo ""
    
    echo -e "${WHITE}🔧 下一步操作:${NC}"
    echo "  1. 重启终端或运行: source ~/.bashrc (或 ~/.zshrc)"
    echo "  2. 测试命令: 列出技能"
    echo "  3. 安装示例技能: 同步技能 weather"
    echo "  4. 查看帮助: skillhub help"
    echo ""
    
    echo -e "${GREEN}🎉 Skill Hub全家桶安装完成！${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

# 清理临时文件
cleanup() {
    show_step "清理临时文件"
    
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        show_success "清理临时目录"
    fi
    
    if [ -f "$LOG_FILE" ]; then
        show_success "安装日志: $LOG_FILE"
    fi
    
    echo ""
}

# 主安装函数
main_install() {
    # 显示标题
    show_title
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行安装步骤
    check_dependencies
    prepare_directories
    clone_repository
    install_core_skills
    create_config
    create_environment
    create_shortcuts
    
    # 验证安装
    if verify_installation; then
        # 计算安装时间
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
