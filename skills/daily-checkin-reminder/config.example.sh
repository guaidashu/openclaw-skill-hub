#!/bin/bash

# 每日打卡提醒配置示例
# 复制此文件为 config.sh 并修改配置

# 基本配置
REMINDER_TIME="18:30"                    # 提醒时间 (HH:MM)
REMINDER_MESSAGE="⏰ 打卡时间到！请记得打卡哦~"  # 提醒消息
NOTIFICATION_CHANNEL="feishu"            # 通知渠道: feishu, email, console, all
AT_EVERYONE=true                         # 是否@所有人
SKIP_WEEKEND=true                        # 是否跳过周末
ENABLED=true                             # 是否启用

# 飞书配置
FEISHU_CHAT_ID="oc_3ff7c798f86b530300574c851431b07d"  # 飞书群ID
# FEISHU_WEBHOOK_URL=""                  # 飞书机器人Webhook (可选)

# 邮件配置
TO_EMAILS="user1@example.com,user2@example.com"  # 收件人列表 (逗号分隔)
SMTP_SERVER="smtp.example.com"           # SMTP服务器
SMTP_PORT="587"                          # SMTP端口
FROM_EMAIL="noreply@example.com"         # 发件人邮箱
FROM_NAME="打卡提醒助手"                  # 发件人名称
# SMTP_USERNAME=""                       # SMTP用户名 (如果需要认证)
# SMTP_PASSWORD=""                       # SMTP密码 (如果需要认证)

# 高级配置
TEST_MODE=false                          # 测试模式 (不实际发送)
LOG_LEVEL="info"                         # 日志级别: debug, info, warn, error

# 消息模板变量
# 可在消息中使用以下变量：
# {date} - 当前日期 (如: 2026年02月27日 星期四)
# {time} - 当前时间 (如: 18:30)
# {week} - 星期几 (如: 星期四)