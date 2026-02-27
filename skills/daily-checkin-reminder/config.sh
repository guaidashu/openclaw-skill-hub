#!/bin/bash

# 每日打卡提醒默认配置

# 基本配置
REMINDER_TIME="18:30"
REMINDER_MESSAGE="⏰ 打卡时间到！请记得打卡哦~"
NOTIFICATION_CHANNEL="console"  # 测试用控制台输出
AT_EVERYONE=true
SKIP_WEEKEND=true
ENABLED=true

# 飞书配置（需要时启用）
# FEISHU_CHAT_ID="oc_3ff7c798f86b530300574c851431b07d"

# 邮件配置（需要时启用）
# TO_EMAILS="user@example.com"
# SMTP_SERVER="smtp.example.com"
# SMTP_PORT="587"
# FROM_EMAIL="noreply@example.com"
# FROM_NAME="打卡提醒助手"

# 高级配置
TEST_MODE=false
LOG_LEVEL="info"