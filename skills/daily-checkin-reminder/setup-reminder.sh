#!/bin/bash

# 打卡提醒设置脚本
# 配置和安装每日打卡提醒

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"
CRON_FILE="/tmp/daily-checkin-cron"

# 显示帮助
show_help() {
    echo "用法: setup-reminder.sh [选项] [参数]"
    echo ""
    echo "选项:"
    echo "  setup <时间>          设置打卡提醒（例: 18:30）"
    echo "  setup-mail <时间> <邮箱> 设置邮件提醒"
    echo "  setup-feishu <时间> <群ID> 设置飞书提醒"
    echo "  show                 显示当前设置"
    echo "  test                 测试提醒"
    echo "  remove               移除提醒"
    echo "  enable               启用提醒"
    echo "  disable              禁用提醒"
    echo "  --help               显示帮助"
    echo ""
    echo "示例:"
    echo "  setup-reminder.sh setup 18:30"
    echo "  setup-reminder.sh setup-mail 18:30 user@example.com"
    echo "  setup-reminder.sh setup-feishu 18:30 oc_xxxxxx"
    echo "  setup-reminder.sh show"
    echo "  setup-reminder.sh test"
}

# 检查cron是否可用
check_cron() {
    if ! command -v crontab &> /dev/null; then
        echo -e "${RED}错误: crontab 未安装${NC}"
        echo "请安装cron服务:"
        echo "  Ubuntu/Debian: sudo apt-get install cron"
        echo "  macOS: brew install cron"
        echo "  CentOS/RHEL: sudo yum install cronie"
        return 1
    fi
    return 0
}

# 创建配置文件
create_config() {
    local time="$1"
    local channel="$2"
    local target="$3"
    
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash

# 每日打卡提醒配置
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

# 基本配置
REMINDER_TIME="$time"
REMINDER_MESSAGE="⏰ 打卡时间到！请记得打卡哦~"
NOTIFICATION_CHANNEL="$channel"
AT_EVERYONE=true
SKIP_WEEKEND=true
ENABLED=true

# 飞书配置
FEISHU_CHAT_ID="$([ "$channel" = "feishu" ] && echo "$target" || echo "")"

# 邮件配置
TO_EMAILS="$([ "$channel" = "email" ] && echo "$target" || echo "")"
SMTP_SERVER="smtp.example.com"
SMTP_PORT="587"
FROM_EMAIL="noreply@example.com"
FROM_NAME="打卡提醒助手"

# 高级配置
TEST_MODE=false
LOG_LEVEL="info"
EOF
    
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✓ 配置文件已创建: $CONFIG_FILE${NC}"
}

# 解析时间
parse_time() {
    local time_str="$1"
    local hour
    local minute
    
    if [[ "$time_str" =~ ^([0-9]{1,2}):([0-9]{2})$ ]]; then
        hour="${BASH_REMATCH[1]}"
        minute="${BASH_REMATCH[2]}"
        
        # 验证时间有效性
        if [ "$hour" -lt 0 ] || [ "$hour" -gt 23 ]; then
            echo -e "${RED}错误: 小时必须在0-23之间${NC}"
            return 1
        fi
        if [ "$minute" -lt 0 ] || [ "$minute" -gt 59 ]; then
            echo -e "${RED}错误: 分钟必须在0-59之间${NC}"
            return 1
        fi
        
        echo "$minute $hour"
        return 0
    else
        echo -e "${RED}错误: 时间格式不正确，请使用 HH:MM 格式${NC}"
        return 1
    fi
}

# 设置cron任务
setup_cron() {
    local cron_time="$1"
    
    check_cron || return 1
    
    echo -e "${BLUE}设置cron定时任务...${NC}"
    
    # 创建cron条目
    local cron_entry="$cron_time * * * $SCRIPT_DIR/send-reminder.sh >> $SCRIPT_DIR/reminder.log 2>&1"
    
    # 备份现有cron
    crontab -l > "$CRON_FILE" 2>/dev/null || true
    
    # 移除现有的打卡提醒任务
    grep -v "send-reminder.sh" "$CRON_FILE" > "${CRON_FILE}.new" || true
    mv "${CRON_FILE}.new" "$CRON_FILE"
    
    # 添加新任务
    echo "$cron_entry" >> "$CRON_FILE"
    
    # 安装cron
    crontab "$CRON_FILE"
    
    echo -e "${GREEN}✓ cron任务已设置${NC}"
    echo "任务详情: $cron_entry"
    
    # 清理
    rm -f "$CRON_FILE"
}

# 设置提醒
setup_reminder() {
    local time="$1"
    local channel="${2:-feishu}"
    local target="$3"
    
    echo -e "${CYAN}设置每日打卡提醒...${NC}"
    
    # 解析时间
    local cron_time
    cron_time=$(parse_time "$time")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # 创建配置
    create_config "$time" "$channel" "$target"
    
    # 设置cron
    setup_cron "$cron_time"
    
    echo ""
    echo -e "${GREEN}✅ 打卡提醒设置完成！${NC}"
    echo "提醒时间: 每天 $time"
    echo "通知渠道: $channel"
    if [ -n "$target" ]; then
        echo "目标: $target"
    fi
    echo ""
    echo "测试命令: $SCRIPT_DIR/send-reminder.sh --test"
    echo "查看日志: $SCRIPT_DIR/send-reminder.sh --log"
}

# 显示当前设置
show_settings() {
    echo -e "${CYAN}当前打卡提醒设置${NC}"
    echo "="*50
    
    if [ -f "$CONFIG_FILE" ]; then
        # 显示配置
        echo "配置文件: $CONFIG_FILE"
        echo ""
        
        # 读取配置
        source "$CONFIG_FILE" 2>/dev/null || true
        
        echo "基本设置:"
        echo "  - 提醒时间: ${REMINDER_TIME:-未设置}"
        echo "  - 通知渠道: ${NOTIFICATION_CHANNEL:-未设置}"
        echo "  - 是否启用: ${ENABLED:-是}"
        echo "  - 跳过周末: ${SKIP_WEEKEND:-是}"
        echo ""
        
        if [ "$NOTIFICATION_CHANNEL" = "feishu" ] && [ -n "$FEISHU_CHAT_ID" ]; then
            echo "飞书设置:"
            echo "  - 群ID: $FEISHU_CHAT_ID"
            echo "  - @所有人: ${AT_EVERYONE:-是}"
        fi
        
        if [ "$NOTIFICATION_CHANNEL" = "email" ] && [ -n "$TO_EMAILS" ]; then
            echo "邮件设置:"
            echo "  - 收件人: $TO_EMAILS"
            echo "  - 发件人: ${FROM_EMAIL:-未设置}"
        fi
        
        # 检查cron任务
        echo ""
        echo "定时任务:"
        if crontab -l 2>/dev/null | grep -q "send-reminder.sh"; then
            echo -e "  ${GREEN}✓ 已安装${NC}"
            crontab -l | grep "send-reminder.sh"
        else
            echo -e "  ${YELLOW}⚠ 未安装${NC}"
        fi
    else
        echo -e "${YELLOW}未找到配置文件${NC}"
        echo "使用 'setup-reminder.sh setup <时间>' 进行设置"
    fi
    
    echo ""
    echo "="*50
}

# 测试提醒
test_reminder() {
    echo -e "${CYAN}测试打卡提醒...${NC}"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误: 请先设置提醒${NC}"
        return 1
    fi
    
    # 运行测试模式
    if "$SCRIPT_DIR/send-reminder.sh" --test; then
        echo ""
        echo -e "${GREEN}✅ 测试成功！${NC}"
        echo "请检查是否收到测试提醒"
    else
        echo -e "${RED}测试失败${NC}"
        return 1
    fi
}

# 移除提醒
remove_reminder() {
    echo -e "${CYAN}移除打卡提醒...${NC}"
    
    # 移除cron任务
    if crontab -l 2>/dev/null | grep -q "send-reminder.sh"; then
        crontab -l | grep -v "send-reminder.sh" | crontab -
        echo -e "${GREEN}✓ 已移除cron任务${NC}"
    else
        echo -e "${YELLOW}未找到cron任务${NC}"
    fi
    
    # 备份配置文件
    if [ -f "$CONFIG_FILE" ]; then
        mv "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d)"
        echo -e "${GREEN}✓ 配置文件已备份${NC}"
    fi
    
    echo -e "${GREEN}✅ 打卡提醒已移除${NC}"
}

# 启用/禁用提醒
toggle_reminder() {
    local action="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误: 请先设置提醒${NC}"
        return 1
    fi
    
    # 更新配置文件
    if [ "$action" = "enable" ]; then
        sed -i.bak 's/ENABLED=false/ENABLED=true/' "$CONFIG_FILE"
        echo -e "${GREEN}✓ 提醒已启用${NC}"
    elif [ "$action" = "disable" ]; then
        sed -i.bak 's/ENABLED=true/ENABLED=false/' "$CONFIG_FILE"
        echo -e "${YELLOW}⚠ 提醒已禁用${NC}"
    fi
    
    # 移除备份文件
    rm -f "${CONFIG_FILE}.bak"
}

# 主函数
main() {
    local action="$1"
    local arg1="$2"
    local arg2="$3"
    
    case "$action" in
        "setup")
            if [ -z "$arg1" ]; then
                echo -e "${RED}错误: 请指定提醒时间${NC}"
                show_help
                exit 1
            fi
            setup_reminder "$arg1"
            ;;
        "setup-mail")
            if [ -z "$arg1" ] || [ -z "$arg2" ]; then
                echo -e "${RED}错误: 请指定时间和邮箱${NC}"
                show_help
                exit 1
            fi
            setup_reminder "$arg1" "email" "$arg2"
            ;;
        "setup-feishu")
            if [ -z "$arg1" ] || [ -z "$arg2" ]; then
                echo -e "${RED}错误: 请指定时间和群ID${NC}"
                show_help
                exit 1
            fi
            setup_reminder "$arg1" "feishu" "$arg2"
            ;;
        "show")
            show_settings
            ;;
        "test")
            test_reminder
            ;;
        "remove")
            remove_reminder
            ;;
        "enable")
            toggle_reminder "enable"
            ;;
        "disable")
            toggle_reminder "disable"
            ;;
        "--help"|"-h"|"help")
            show_help
            ;;
        *)
            if [ -z "$action" ]; then
                show_settings
            else
                echo -e "${RED}错误: 未知操作 '$action'${NC}"
                show_help
                exit 1
            fi
            ;;
    esac
}

# 异常处理
trap 'echo -e "${RED}设置中断${NC}"; exit 1' INT TERM

# 运行主函数
main "$@"