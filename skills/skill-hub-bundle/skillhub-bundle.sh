#!/bin/bash

# Skill Hub全家桶 - OpenClaw技能包装器
# 用户只需说"安装skillhub"即可一键安装

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install_complete.sh"
INSTALL_DIR="$HOME/.openclaw/extensions/skill-hub"

# 显示帮助
show_help() {
    echo "Skill Hub全家桶 - 一键安装OpenClaw Skill Hub核心功能"
    echo ""
    echo "使用方法:"
    echo "  安装skillhub                    # 一键安装全家桶"
    echo "  安装skillhub --force            # 强制重新安装"
    echo "  安装skillhub --help             # 显示帮助"
    echo ""
    echo "包含功能:"
    echo "  📦 技能同步 - 从Skill Hub获取最新技能"
    echo "  📤 技能提交 - 分享你的技能到Skill Hub"
    echo "  📋 技能列表 - 智能分类、分页、搜索"
    echo ""
    echo "安装后命令:"
    echo "  列出技能                        # 查看所有可用技能"
    echo "  同步技能 <技能名>               # 安装特定技能"
    echo "  提交技能 <路径>                 # 分享你的技能"
    echo "  skillhub status                 # 查看Skill Hub状态"
}

# 检查是否已安装
check_installed() {
    if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/config.json" ]; then
        local installed_at
        installed_at=$(grep -o '"installed_at":"[^"]*"' "$INSTALL_DIR/config.json" | cut -d'"' -f4 2>/dev/null || echo "未知时间")
        
        echo -e "${YELLOW}⚠ Skill Hub已安装于: $INSTALL_DIR${NC}"
        echo -e "${YELLOW}  安装时间: $installed_at${NC}"
        echo ""
        
        read -p "是否重新安装？(y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}✓ 跳过安装，Skill Hub已就绪${NC}"
            echo ""
            echo "使用以下命令:"
            echo "  列出技能                    # 查看技能"
            echo "  同步技能 <技能名>           # 安装技能"
            echo "  提交技能 <路径>             # 分享技能"
            exit 0
        fi
    fi
}

# 执行安装
run_installation() {
    echo -e "${CYAN}🚀 开始安装Skill Hub全家桶...${NC}"
    echo ""
    
    # 检查安装脚本
    if [ ! -f "$INSTALL_SCRIPT" ]; then
        echo -e "${RED}错误: 安装脚本不存在${NC}"
        echo "请确保以下文件存在:"
        echo "  $INSTALL_SCRIPT"
        exit 1
    fi
    
    # 设置执行权限
    chmod +x "$INSTALL_SCRIPT"
    
    # 执行安装
    if "$INSTALL_SCRIPT" "$@"; then
        echo ""
        echo -e "${GREEN}✅ Skill Hub全家桶安装成功！${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}❌ 安装失败${NC}"
        return 1
    fi
}

# 显示安装后提示
post_install_tips() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    安装完成提示                             ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}🎯 一句话安装示例技能:${NC}"
    echo "  同步技能 weather              # 安装天气技能"
    echo "  同步技能 daily-checkin-reminder  # 安装打卡提醒"
    echo "  同步技能 novel-rewrite-assistant # 安装小说仿写助手"
    echo ""
    
    echo -e "${BLUE}🔧 常用命令:${NC}"
    echo "  列出技能                      # 查看所有技能（分页显示）"
    echo "  列出技能 --category 工具      # 按分类查看"
    echo "  列出技能 --search 天气        # 搜索技能"
    echo "  列出技能 --stats              # 查看统计"
    echo ""
    
    echo -e "${BLUE}📤 分享你的技能:${NC}"
    echo "  1. 创建技能目录"
    echo "  2. 添加SKILL.md文件"
    echo "  3. 运行: 提交技能 /path/to/your-skill"
    echo ""
    
    echo -e "${BLUE}🔄 更新Skill Hub:${NC}"
    echo "  同步技能 skill-hub-sync       # 更新同步工具"
    echo "  同步技能 skill-hub-list       # 更新列表工具"
    echo "  同步技能 skill-hub-submit     # 更新提交工具"
    echo ""
    
    echo -e "${GREEN}💡 提示: 重启OpenClaw或终端使新技能生效${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

# 主函数
main() {
    # 解析参数
    local force_install=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --force|-f)
                force_install=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # 显示标题
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              OpenClaw Skill Hub 全家桶                      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 检查是否已安装（除非强制安装）
    if [ "$force_install" = false ]; then
        check_installed
    else
        echo -e "${YELLOW}⚠ 强制安装模式，将覆盖现有安装${NC}"
        echo ""
    fi
    
    # 确认安装
    echo "即将安装以下核心功能:"
    echo "  1. 📦 技能同步 (skill-hub-sync)"
    echo "  2. 📤 技能提交 (skill-hub-submit)"
    echo "  3. 📋 增强版技能列表 (skill-hub-list)"
    echo ""
    echo "安装目录: $INSTALL_DIR"
    echo ""
    
    read -p "确认安装？(Y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}安装取消${NC}"
        exit 0
    fi
    
    # 执行安装
    if run_installation "$@"; then
        post_install_tips
    else
        echo -e "${RED}安装过程出错，请检查错误信息${NC}"
        exit 1
    fi
}

# 运行主函数
main "$@"