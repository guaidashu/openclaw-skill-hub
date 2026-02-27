# SKILL.md - 每日打卡提醒

**触发词**: 打卡提醒, 设置打卡, 每日提醒, 自动打卡, 考勤提醒

**描述**: 自动发送每日打卡提醒，支持邮件、飞书群消息等多种通知方式

**作者**: 小怪 (openclaw-001)

**版本**: 1.0.0

**依赖**: cron, curl (邮件通知需要mail命令或API)

## 功能
- **定时提醒**: 每天固定时间发送打卡提醒
- **多渠道通知**: 支持邮件、飞书群消息、微信等
- **自定义消息**: 可配置提醒内容和时间
- **@所有人功能**: 在群聊中@所有成员
- **节假日跳过**: 可配置跳过周末和节假日
- **统计报告**: 生成打卡统计报告

## 使用方法

### 设置每日打卡提醒
```
设置打卡提醒 18:30
```

### 设置邮件提醒
```
设置邮件打卡提醒 18:30 example@email.com
```

### 查看当前设置
```
查看打卡设置
```

### 测试提醒
```
测试打卡提醒
```

### 关闭提醒
```
关闭打卡提醒
```

## 配置说明

### 基本配置
```bash
# 提醒时间 (24小时制)
REMINDER_TIME="18:30"

# 提醒消息
REMINDER_MESSAGE="⏰ 打卡时间到！请记得打卡哦~"

# 通知渠道 (mail, feishu, wechat, all)
NOTIFICATION_CHANNEL="feishu"

# 是否@所有人
AT_EVERYONE=true

# 跳过周末
SKIP_WEEKEND=true

# 跳过节假日 (需要节假日API)
SKIP_HOLIDAYS=false
```

### 飞书配置
```bash
# 飞书群ID
FEISHU_CHAT_ID="oc_3ff7c798f86b530300574c851431b07d"

# 飞书机器人Webhook (可选)
FEISHU_WEBHOOK_URL=""
```

### 邮件配置
```bash
# SMTP服务器
SMTP_SERVER="smtp.example.com"
SMTP_PORT="587"

# 发件人信息
FROM_EMAIL="noreply@example.com"
FROM_NAME="打卡提醒助手"

# 收件人列表 (逗号分隔)
TO_EMAILS="user1@example.com,user2@example.com"
```

## 实现方式

### 方案A: 使用系统cron (推荐)
```bash
# 创建cron任务
30 18 * * * /path/to/daily-checkin-reminder/send-reminder.sh
```

### 方案B: 使用OpenClaw定时任务
```bash
# 创建OpenClaw定时任务
openclaw cron add "打卡提醒" "30 18 * * *" "打卡提醒"
```

### 方案C: 使用Python脚本
```python
# Python定时任务，更灵活
import schedule
import time

def send_reminder():
    # 发送提醒逻辑
    pass

schedule.every().day.at("18:30").do(send_reminder)
```

## 文件结构
- `SKILL.md` - 本文件
- `send-reminder.sh` - 提醒发送脚本
- `setup-reminder.sh` - 设置脚本
- `config.sh` - 配置文件
- `check-holiday.py` - 节假日检查脚本
- `templates/` - 消息模板目录

## 安全考虑
1. **敏感信息加密**: 邮箱密码等敏感信息加密存储
2. **频率限制**: 防止消息轰炸
3. **权限控制**: 只有授权用户可设置提醒
4. **错误处理**: 网络失败重试机制
5. **日志记录**: 所有操作记录日志

## 扩展功能

### 1. 多语言支持
- 中文: "打卡时间到！"
- 英文: "Time to check in!"
- 日文: "チェックインの時間です！"

### 2. 随机提醒消息
```bash
MESSAGES=(
    "⏰ 叮咚~打卡时间到啦！"
    "📢 提醒：该打卡咯！"
    "🔔 别忘了今天的打卡哦~"
    "💼 工作一天辛苦了，记得打卡！"
)
```

### 3. 打卡统计
- 每日打卡人数统计
- 月度打卡报告
- 迟到/早退提醒

### 4. 智能提醒
- 根据天气调整提醒语气
- 节假日特别提醒
- 生日祝福+打卡提醒

## 安装说明

### 快速安装
```bash
# 1. 从Skill Hub同步
同步技能 daily-checkin-reminder

# 2. 或手动安装
cp -r daily-checkin-reminder ~/.openclaw/extensions/

# 3. 配置提醒
设置打卡提醒 18:30
```

### 依赖安装
```bash
# 安装cron (如果未安装)
# Ubuntu/Debian
sudo apt-get install cron

# macOS
brew install cron

# 安装邮件工具
sudo apt-get install mailutils  # Ubuntu/Debian
```

## 更新日志
- v1.0.0 (2026-02-27): 初始版本，基础打卡提醒功能
- 计划功能: 多渠道通知、节假日跳过、统计报告

## 故障排除

### 常见问题
1. **提醒未发送**: 检查cron服务是否运行
2. **邮件发送失败**: 检查SMTP配置和网络
3. **飞书@所有人失效**: 检查群权限和消息格式
4. **时区问题**: 确保系统时区设置正确

### 调试命令
```bash
# 查看cron日志
tail -f /var/log/cron.log

# 手动测试脚本
./send-reminder.sh --test

# 检查配置
./setup-reminder.sh --check
```

## 贡献指南
欢迎提交改进建议和代码贡献！

1. Fork Skill Hub仓库
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

---

**让打卡成为习惯，让提醒更贴心！** 🎯