# 每日打卡提醒 Skill

自动发送每日打卡提醒的OpenClaw技能，支持邮件、飞书群消息等多种通知方式。

## 功能特性

- ⏰ **定时提醒**：每天固定时间自动发送打卡提醒
- 📱 **多渠道通知**：支持飞书群消息、邮件、控制台输出
- 🎯 **智能跳过**：自动跳过周末和节假日
- 🔔 **@所有人**：在群聊中@所有成员（飞书）
- 🎨 **随机消息**：每次提醒使用不同的消息模板
- 📊 **日志记录**：完整的操作日志和错误记录
- 🔧 **灵活配置**：可自定义时间、消息、渠道等

## 快速开始

### 安装方法

#### 从Skill Hub同步（推荐）
```bash
同步技能 daily-checkin-reminder
```

#### 手动安装
```bash
# 复制到OpenClaw技能目录
cp -r daily-checkin-reminder ~/.openclaw/extensions/

# 设置执行权限
chmod +x ~/.openclaw/extensions/daily-checkin-reminder/*.sh
```

### 基本设置

#### 设置飞书提醒（推荐）
```bash
# 设置每天18:30在飞书群提醒
设置打卡提醒 18:30

# 或指定飞书群ID
设置打卡提醒 18:30 oc_xxxxxx
```

#### 设置邮件提醒
```bash
# 设置邮件提醒
设置邮件打卡提醒 18:30 user@example.com
```

### 测试设置
```bash
# 测试提醒
测试打卡提醒

# 查看当前设置
查看打卡设置
```

## 详细配置

### 配置文件
复制 `config.example.sh` 为 `config.sh` 并修改：

```bash
cp config.example.sh config.sh
nano config.sh
```

### 主要配置项

#### 基本设置
```bash
REMINDER_TIME="18:30"                    # 提醒时间
NOTIFICATION_CHANNEL="feishu"            # 通知渠道
SKIP_WEEKEND=true                        # 跳过周末
```

#### 飞书设置
```bash
FEISHU_CHAT_ID="oc_xxxxxx"               # 飞书群ID
AT_EVERYONE=true                         # 是否@所有人
```

#### 邮件设置
```bash
TO_EMAILS="user@example.com"             # 收件人
SMTP_SERVER="smtp.example.com"           # SMTP服务器
FROM_EMAIL="noreply@example.com"         # 发件人
```

## 使用命令

### 管理命令
```bash
# 设置提醒
设置打卡提醒 <时间> [群ID]

# 设置邮件提醒
设置邮件打卡提醒 <时间> <邮箱>

# 查看设置
查看打卡设置

# 测试提醒
测试打卡提醒

# 移除提醒
关闭打卡提醒
```

### 脚本命令
```bash
# 手动发送提醒
./send-reminder.sh

# 测试模式
./send-reminder.sh --test

# 强制发送（跳过检查）
./send-reminder.sh --force

# 查看日志
./send-reminder.sh --log
```

## 实现原理

### 定时任务
使用系统cron服务定时执行提醒脚本：
```bash
# cron任务示例
30 18 * * * /path/to/send-reminder.sh
```

### 消息发送
1. **飞书消息**：通过飞书群消息API发送
2. **邮件通知**：通过SMTP服务器发送邮件
3. **控制台输出**：测试和调试用

### 智能跳过
- **周末跳过**：周六周日不发送提醒
- **节假日跳过**：法定节假日不发送提醒
- **配置控制**：可通过配置禁用跳过功能

## 扩展功能

### 自定义消息模板
编辑 `templates/messages.txt` 文件添加自定义消息：
```
🎉 自定义提醒消息！
📅 今天是{date}，记得打卡哦！
```

### 多语言支持
创建不同语言的消息模板文件：
- `templates/messages_zh.txt` - 中文
- `templates/messages_en.txt` - 英文
- `templates/messages_ja.txt` - 日文

### 高级统计
可扩展功能：
- 打卡人数统计
- 月度打卡报告
- 迟到/早退分析

## 故障排除

### 常见问题

#### 1. 提醒未发送
```bash
# 检查cron服务
systemctl status cron      # Linux
brew services list         # macOS

# 检查cron任务
crontab -l

# 查看日志
./send-reminder.sh --log
```

#### 2. 飞书消息发送失败
- 检查飞书群ID是否正确
- 确认机器人有发送消息权限
- 检查网络连接

#### 3. 邮件发送失败
- 检查SMTP配置
- 确认邮箱密码正确
- 检查防火墙设置

#### 4. 时区问题
```bash
# 查看系统时区
timedatectl

# 设置时区（中国）
sudo timedatectl set-timezone Asia/Shanghai
```

### 调试模式
```bash
# 启用详细日志
export LOG_LEVEL="debug"
./send-reminder.sh --test

# 查看系统日志
tail -f /var/log/syslog | grep cron
```

## 安全建议

1. **配置文件权限**
   ```bash
   chmod 600 config.sh
   ```

2. **敏感信息加密**
   - 邮箱密码建议使用环境变量
   - 或使用专门的密码管理工具

3. **访问控制**
   - 限制可修改配置的用户
   - 定期审查cron任务

4. **日志监控**
   - 定期检查提醒日志
   - 设置异常报警

## 性能优化

### 减少资源占用
- 使用轻量级邮件客户端
- 优化消息模板加载
- 合理设置日志级别

### 提高可靠性
- 添加失败重试机制
- 实现消息队列
- 设置监控告警

## 贡献指南

欢迎提交改进建议和代码贡献！

1. Fork Skill Hub仓库
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

### 开发规范
- 遵循Shell脚本最佳实践
- 添加详细的注释
- 编写测试用例
- 更新文档

## 许可证

MIT License - 详见 LICENSE 文件

## 支持与反馈

- **GitHub Issues**: 提交问题和建议
- **功能请求**: 描述需要的功能
- **错误报告**: 提供复现步骤和日志

---

**让打卡成为习惯，让工作更高效！** 🚀