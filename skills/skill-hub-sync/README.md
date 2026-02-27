# 技能同步Skill

从OpenClaw Skill Hub同步技能到本地的工具。

## 功能特性

- 🔄 **自动同步**：从GitHub仓库同步最新技能
- 📊 **版本管理**：智能比较技能版本
- 🚀 **增量更新**：只下载变更的文件
- 🔒 **安全验证**：检查文件完整性
- 📝 **详细日志**：记录所有同步操作
- ⚡ **性能优化**：并行下载、缓存机制

## 安装方法

### 方法一：手动安装
1. 复制本目录到OpenClaw的skills目录：
   ```bash
   cp -r skill-hub-sync ~/.openclaw/extensions/
   ```

2. 确保依赖已安装：
   ```bash
   # 检查依赖
   which git curl jq
   
   # 如果缺少jq，安装它
   # macOS
   brew install jq
   
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # CentOS/RHEL
   sudo yum install jq
   ```

3. 重启OpenClaw服务：
   ```bash
   openclaw gateway restart
   ```

### 方法二：通过Skill Hub安装（未来）
```
同步技能
```

## 使用方法

### 基本命令
```
同步技能
```

### 强制更新
```
强制同步技能
```

### 查看状态
```
技能状态
```

### 查看帮助
```
技能同步帮助
```

## 配置说明

编辑 `config.json` 文件：

```json
{
  "repo_url": "https://github.com/guaidashu/openclaw-skill-hub.git",
  "local_skill_dir": "~/.openclaw/extensions/skill-hub",
  "sync_interval": 3600,
  "auto_update": true,
  "log_level": "info"
}
```

### 配置选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `repo_url` | string | GitHub URL | Skill Hub仓库地址 |
| `local_skill_dir` | string | ~/.openclaw/extensions/skill-hub | 本地技能目录 |
| `sync_interval` | number | 3600 | 同步间隔（秒） |
| `auto_update` | boolean | true | 是否自动更新 |
| `log_level` | string | "info" | 日志级别：debug/info/warn/error |
| `max_retries` | number | 3 | 最大重试次数 |
| `retry_delay` | number | 5 | 重试延迟（秒） |
| `notify_on_update` | boolean | true | 更新时通知 |
| `exclude_skills` | array | [] | 排除的技能ID |
| `include_skills` | array | ["*"] | 包含的技能ID |
| `proxy` | string | "" | 代理服务器 |
| `timeout` | number | 30 | 超时时间（秒） |
| `concurrent_downloads` | number | 3 | 并发下载数 |
| `validate_signatures` | boolean | false | 验证签名 |
| `backup_before_update` | boolean | true | 更新前备份 |
| `cleanup_after_days` | number | 7 | 清理旧日志天数 |

## 工作流程

1. **检查依赖**：确保git、curl、jq已安装
2. **创建目录**：创建必要的目录结构
3. **更新仓库**：克隆或拉取最新代码
4. **解析注册表**：读取registry.json
5. **比较版本**：对比本地和远程技能版本
6. **下载技能**：复制新增或更新的技能
7. **更新注册表**：更新本地registry.json
8. **同步成员**：更新成员信息
9. **清理文件**：删除临时文件
10. **生成报告**：输出同步结果

## 文件结构

```
skill-hub-sync/
├── SKILL.md          # 技能主文件
├── sync.sh           # 同步脚本
├── config.json       # 配置文件
├── README.md         # 本文件
└── cache/           # 缓存目录（运行时创建）
```

## 错误处理

### 常见错误及解决方案

1. **网络连接失败**
   ```
   错误：无法连接到GitHub
   解决方案：检查网络连接，配置代理
   ```

2. **权限不足**
   ```
   错误：无法写入目录
   解决方案：检查目录权限，使用sudo（不推荐）
   ```

3. **依赖缺失**
   ```
   错误：命令未找到
   解决方案：安装缺失的依赖（git/curl/jq）
   ```

4. **磁盘空间不足**
   ```
   错误：磁盘空间不足
   解决方案：清理磁盘空间
   ```

5. **版本冲突**
   ```
   警告：本地版本较新
   解决方案：手动决定是否覆盖
   ```

## 日志文件

同步日志保存在：
```
~/.openclaw/logs/skill-sync-YYYYMMDD.log
```

查看最新日志：
```bash
tail -f ~/.openclaw/logs/skill-sync-$(date +%Y%m%d).log
```

## 定时任务

### 使用cron定时同步
```bash
# 编辑crontab
crontab -e

# 每小时同步一次
0 * * * * /path/to/skill-hub-sync/sync.sh >> /tmp/skill-sync.log 2>&1

# 每天凌晨3点同步
0 3 * * * /path/to/skill-hub-sync/sync.sh >> /tmp/skill-sync.log 2>&1
```

### 使用OpenClaw定时任务
```bash
# 创建定时任务
openclaw cron add "技能同步" "0 * * * *" "同步技能"
```

## 性能优化建议

1. **使用SSH克隆**：配置SSH密钥加速Git操作
2. **启用缓存**：减少重复下载
3. **限制并发**：避免网络拥堵
4. **定期清理**：删除旧日志和缓存
5. **使用CDN**：如果仓库较大，考虑使用GitHub CDN

## 安全建议

1. **验证来源**：只从可信的GitHub仓库同步
2. **检查权限**：技能文件应为只读权限
3. **定期审计**：检查同步的技能内容
4. **备份重要数据**：同步前备份现有技能
5. **使用签名验证**：如果支持，启用签名验证

## 贡献指南

欢迎提交Issue和Pull Request：
1. Fork本仓库
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 许可证

MIT License