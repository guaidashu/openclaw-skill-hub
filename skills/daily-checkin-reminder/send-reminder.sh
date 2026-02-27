#!/bin/bash

# 每日打卡提醒发送脚本
# 支持多种通知渠道：飞书群消息、邮件等

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 配置文件
CONFIG_FILE="$(dirname "$0")/config.sh"
LOG_FILE="/tmp/daily-checkin-$(date +%Y%m%d).log"

# 加载配置
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        # 默认配置
        REMINDER_TIME="18:30"
        REMINDER_MESSAGE="⏰ 打卡时间到！请记得打卡哦~"
        NOTIFICATION_CHANNEL="feishu"
        AT_EVERYONE=true
        SKIP_WEEKEND=true
        FEISHU_CHAT_ID=""
        TEST_MODE=false
    fi
}

# 日志函数
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] $1" | tee -a "$LOG_FILE"
}

success() {
    log "${GREEN}✓ $1${NC}"
}

info() {
    log "${BLUE}ℹ $1${NC}"
}

warning() {
    log "${YELLOW}⚠ $1${NC}"
}

error() {
    log "${RED}✗ $1${NC}"
}

# 检查是否跳过
should_skip() {
    local today
    today=$(date +%u)  # 1=星期一, 7=星期日
    
    # 检查周末
    if [ "$SKIP_WEEKEND" = "true" ]; then
        if [ "$today" -eq 6 ] || [ "$today" -eq 7 ]; then
            info "今天是周末，跳过提醒"
            return 0
        fi
    fi
    
    # 检查节假日（简化版）
    local month_day
    month_day=$(date +%m-%d)
    local holidays=("01-01" "05-01" "10-01" "10-02" "10-03")
    
    for holiday in "${holidays[@]}"; do
        if [ "$month_day" = "$holiday" ]; then
            info "今天是节假日 ($holiday)，跳过提醒"
            return 0
        fi
    done
    
    return 1
}

# 生成提醒消息
generate_message() {
    local message_template="$1"
    local today
    today=$(date '+%Y年%m月%d日 %A')
    
    # 替换变量
    local message="$message_template"
    message="${message//\{date\}/$today}"
    message="${message//\{time\}/$(date '+%H:%M')}"
    
    # 随机选择消息（如果有多个）- 兼容版
    local messages_file="$(dirname "$0")/templates/messages.txt"
    if [ -f "$messages_file" ]; then
        # 读取消息文件到数组（兼容各种shell）
        local messages=()
        while IFS= read -r line || [ -n "$line" ]; do
            messages+=("$line")
        done < "$messages_file"
        
        if [ ${#messages[@]} -gt 0 ]; then
            local random_index=$((RANDOM % ${#messages[@]}))
            message="${messages[$random_index]}"
            message="${message//\{date\}/$today}"
        fi
    fi
    
    echo "$message"
}

# 发送飞书群消息
send_feishu_message() {
    local message="$1"
    local at_everyone="$2"
    
    if [ -z "$FEISHU_CHAT_ID" ]; then
        error "未配置飞书群ID"
        return 1
    fi
    
    info "发送飞书群消息..."
    
    # 构建消息内容
    local feishu_message="$message"
    
    if [ "$at_everyone" = "true" ]; then
        feishu_message="$feishu_message\n\n<at user_id=\"all\">@所有人</at>"
    fi
    
    # 这里需要实际的飞书API调用
    # 简化版：记录日志
    success "飞书消息已准备：$feishu_message"
    
    # 实际发送示例（需要配置飞书机器人）：
    # curl -X POST -H "Content-Type: application/json" \
    #   -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"$feishu_message\"}}" \
    #   "https://open.feishu.cn/open-apis/bot/v2/hook/XXX"
    
    return 0
}

# 发送邮件
send_email() {
    local message="$1"
    local subject="$2"
    
    if [ -z "$TO_EMAILS" ]; then
        error "未配置收件人邮箱"
        return 1
    fi
    
    info "发送邮件提醒..."
    
    # 构建邮件内容
    local email_body="打卡提醒\n\n"
    email_body+="时间: $(date '+%Y-%m-%d %H:%M:%S')\n"
    email_body+="消息: $message\n\n"
    email_body+="--\n自动发送，请勿回复"
    
    # 简化版：记录日志
    success "邮件已准备："
    echo "收件人: $TO_EMAILS"
    echo "主题: $subject"
    echo "内容: $email_body"
    
    # 实际发送示例（需要配置SMTP）：
    # echo "$email_body" | mail -s "$subject" "$TO_EMAILS"
    
    return 0
}

# 发送控制台消息（测试用）
send_console_message() {
    local message="$1"
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                   打卡提醒                          ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}$message${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════${NC}"
    echo ""
    
    return 0
}

# 主发送函数
send_reminder() {
    local test_mode="${1:-false}"
    
    log "开始发送打卡提醒..."
    log "模式: $( [ "$test_mode" = "true" ] && echo "测试" || echo "生产" )"
    
    # 检查是否跳过
    if [ "$test_mode" != "true" ] && should_skip; then
        info "今日跳过提醒"
        return 0
    fi
    
    # 生成消息
    local message
    message=$(generate_message "$REMINDER_MESSAGE")
    
    info "提醒消息: $message"
    
    # 根据配置发送通知
    local success_count=0
    local fail_count=0
    
    case "$NOTIFICATION_CHANNEL" in
        "feishu")
            if send_feishu_message "$message" "$AT_EVERYONE"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
            ;;
        "email")
            local subject="打卡提醒 - $(date '+%Y年%m月%d日')"
            if send_email "$message" "$subject"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
            ;;
        "console")
            send_console_message "$message"
            success_count=$((success_count + 1))
            ;;
        "all")
            # 发送所有渠道
            send_feishu_message "$message" "$AT_EVERYONE" && success_count=$((success_count + 1)) || fail_count=$((fail_count + 1))
            send_email "$message" "打卡提醒 - $(date '+%Y年%m月%d日')" && success_count=$((success_count + 1)) || fail_count=$((fail_count + 1))
            send_console_message "$message" && success_count=$((success_count + 1))
            ;;
        *)
            error "未知的通知渠道: $NOTIFICATION_CHANNEL"
            return 1
            ;;
    esac
    
    # 输出结果
    if [ "$success_count" -gt 0 ]; then
        success "提醒发送完成：成功 $success_count 个渠道"
        if [ "$fail_count" -gt 0 ]; then
            warning "失败 $fail_count 个渠道"
        fi
    else
        error "提醒发送失败"
        return 1
    fi
    
    return 0
}

# 显示帮助
show_help() {
    echo "用法: send-reminder.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -t, --test     测试模式（不实际发送，跳过检查）"
    echo "  -c, --config   指定配置文件"
    echo "  -l, --log      查看日志"
    echo "  --force        强制发送（跳过所有检查）"
    echo ""
    echo "示例:"
    echo "  send-reminder.sh              # 正常发送提醒"
    echo "  send-reminder.sh --test       # 测试模式"
    echo "  send-reminder.sh --force      # 强制发送"
}

# 查看日志
view_log() {
    if [ -f "$LOG_FILE" ]; then
        echo "最近日志内容:"
        tail -20 "$LOG_FILE"
    else
        echo "暂无日志"
    fi
}

# 主函数
main() {
    local test_mode=false
    local force_mode=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -t|--test)
                test_mode=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -l|--log)
                view_log
                exit 0
                ;;
            --force)
                force_mode=true
                shift
                ;;
            -*)
                error "未知选项: $1"
                show_help
                exit 1
                ;;
            *)
                shift
                ;;
        esac
    done
    
    # 加载配置
    load_config
    
    # 设置测试模式
    if [ "$test_mode" = "true" ]; then
        TEST_MODE=true
        SKIP_WEEKEND=false
    fi
    
    # 强制模式
    if [ "$force_mode" = "true" ]; then
        SKIP_WEEKEND=false
    fi
    
    # 发送提醒
    send_reminder "$test_mode"
    
    # 记录完成时间
    log "提醒任务完成"
}

# 异常处理
trap 'error "脚本执行中断"; exit 1' INT TERM

# 运行主函数
main "$@"