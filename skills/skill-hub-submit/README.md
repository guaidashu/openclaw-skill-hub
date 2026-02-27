# 技能提交Skill

一个OpenClaw技能，用于将本地技能提交到OpenClaw Skill Hub共享。

## 功能特性

- ✅ **格式验证**：自动检查技能格式是否符合标准
- 📦 **智能打包**：将技能目录打包成标准格式
- 🚀 **多种提交方式**：手动/自动提交到GitHub
- 📝 **详细指南**：生成完整的提交步骤说明
- 🔒 **安全检查**：验证文件权限和大小限制
- 📊 **完整日志**：记录所有操作便于调试

## 快速开始

### 安装方法

#### 方法一：从Skill Hub同步（推荐）
```
同步技能
```
然后从同步的技能中找到 `skill-hub-submit`

#### 方法二：手动安装
```bash
# 1. 复制到OpenClaw技能目录
cp -r skill-hub-submit ~/.openclaw/extensions/

# 2. 确保脚本可执行
chmod +x ~/.openclaw/extensions/skill-hub-submit/*.sh

# 3. 重启OpenClaw服务
openclaw gateway restart
```

### 基本使用

#### 验证技能格式
```
验证技能 ~/skills/my-skill
```

#### 打包技能
```
打包技能 ~/skills/my-skill
```

#### 提交技能（手动模式）
```
提交技能 ~/packages/my-skill
```

## 详细使用指南

### 1. 验证技能格式

```bash
# 基本验证
./validate.sh ~/skills/weather

# 详细输出
./validate.sh -v ~/skills/weather

# 严格模式（警告视为错误）
./validate.sh -s ~/skills/weather
```

### 2. 打包技能

```bash
# 基本打包
./package.sh ~/skills/weather

# 指定输出目录和技能ID
./package.sh -o ./dist ~/skills/weather weather-skill

# 打包前先验证
./package.sh -v ~/skills/weather

# 强制覆盖已存在的包
./package.sh -f ~/skills/weather
```

### 3. 提交技能

```bash
# 生成手动提交指南（推荐）
./submit.sh -m ./packages/weather

# 自动提交（需要GitHub Token）
./submit.sh --github-token YOUR_TOKEN ./packages/weather

# 试运行（不实际提交）
./submit.sh --dry-run ./packages/weather

# 强制提交（跳过部分检查）
./submit.sh -f ./packages/weather
```

## 工作流程示例

### 完整提交流程

```bash
# 1. 开发你的技能
mkdir -p ~/skills/my-awesome-skill
# 创建 SKILL.md, README.md, 脚本文件等

# 2. 验证技能格式
./validate.sh -v ~/skills/my-awesome-skill

# 3. 打包技能
./package.sh -v ~/skills/my-awesome-skill

# 4. 查看生成的包
ls -la ./packages/my-awesome-skill/

# 5. 生成提交指南
./submit.sh -m ./packages/my-awesome-skill

# 6. 按照指南提交到Skill Hub
```

### 快速提交（一行命令）

```bash
# 验证、打包、生成指南
./validate.sh ~/skills/my-skill && \
./package.sh ~/skills/my-skill && \
./submit.sh -m ./packages/$(basename ~/skills/my-skill)
```

## 配置说明

编辑 `config.json` 文件自定义行为：

```json
{
  "github": {
    "repo_owner": "guaidashu",
    "repo_name": "openclaw-skill-hub",
    "api_token": "",
    "use_api": false
  },
  "validation": {
    "strict_mode": true,
    "max_size_mb": 10
  }
}
```

### 配置GitHub自动提交

1. 生成GitHub Personal Access Token：
   - 访问 https://github.com/settings/tokens
   - 点击 "Generate new token"
   - 选择权限：`repo`（完全控制仓库）
   - 复制生成的Token

2. 配置Token：
   ```bash
   # 方法一：设置环境变量
   export GITHUB_TOKEN="your_token_here"
   
   # 方法二：编辑config.json
   # 将token填入 "api_token" 字段
   
   # 方法三：命令行参数
   ./submit.sh --github-token "your_token_here" ./packages/weather
   ```

## 技能格式要求

### 必需文件
- `SKILL.md` - 技能主文件（必须）

### SKILL.md 必需字段
```markdown
# SKILL.md - [技能名称]

**触发词**: [关键词1], [关键词2], [关键词3]

**描述**: [技能功能描述]

**作者**: [你的名字或OpenClaw ID]

**版本**: [x.x.x]

**依赖**: [无 或 依赖列表]
```

### 推荐文件
- `README.md` - 详细说明文档
- `config.json` - 配置文件
- 相关脚本文件（*.sh）

## 错误处理

### 常见错误及解决方案

1. **验证失败：缺少SKILL.md**
   ```
   错误：创建 SKILL.md 文件
   参考 templates/SKILL.md.template
   ```

2. **打包失败：技能ID格式错误**
   ```
   错误：技能ID只能包含小写字母、数字和连字符
   有效示例：weather, coding-agent, my-skill-123
   ```

3. **提交失败：GitHub认证无效**
   ```
   错误：生成手动提交指南
   按照指南手动提交
   ```

4. **文件过大：超过大小限制**
   ```
   警告：技能包较大，建议优化
   删除不必要的文件，压缩大文件
   ```

## 高级功能

### 批量处理多个技能

```bash
# 批量验证
for skill in ~/skills/*; do
  [ -d "$skill" ] && ./validate.sh "$skill"
done

# 批量打包
for skill in ~/skills/*; do
  [ -d "$skill" ] && ./package.sh "$skill"
done
```

### 集成到OpenClaw工作流

```bash
# 在OpenClaw中直接调用
exec command="cd /path/to/skill-hub-submit && ./validate.sh ~/skills/weather"
```

### 定时自动提交

```bash
# 使用cron定时检查并提交新技能
0 2 * * * cd /path/to/skill-hub-submit && ./submit.sh --dry-run ./packages/* 2>&1 | mail -s "技能提交报告" your@email.com
```

## 模板文件

使用模板快速创建标准技能：

```bash
# 复制模板
cp templates/SKILL.md.template ~/skills/new-skill/SKILL.md

# 编辑模板
# 填写技能名称、触发词、描述等信息
```

## 贡献指南

欢迎改进这个技能提交工具！

1. Fork Skill Hub仓库
2. 创建功能分支
3. 提交更改
4. 创建Pull Request

## 支持与反馈

- **GitHub Issues**: https://github.com/guaidashu/openclaw-skill-hub/issues
- **问题模板**: 提交问题时请包含：
  - OpenClaw版本
  - 错误信息
  - 复现步骤
  - 相关日志

## 许可证

MIT License - 详见 LICENSE 文件

---

**开始分享你的技能吧！** 🚀

让更多OpenClaw受益于你的创造！