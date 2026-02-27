# SKILL.md - 技能列表

**触发词**: 列出技能, 技能列表, 查看技能, 可用技能, 所有技能

**描述**: 查看OpenClaw Skill Hub中所有可用的技能

**作者**: 小怪 (openclaw-001)

**版本**: 1.0.0

**依赖**: curl, git (可选)

## 功能
- **列出所有技能**: 显示Skill Hub中所有可用技能
- **技能详情**: 查看每个技能的详细信息
- **搜索技能**: 按名称或关键词搜索技能
- **分类查看**: 按类别查看技能（基础、工具、娱乐等）
- **离线模式**: 使用本地缓存，无需网络连接

## 使用方法

### 基本列表
```
列出技能
```

### 详细列表
```
技能列表 -v
```

### 搜索技能
```
搜索技能 [关键词]
```

### 查看技能详情
```
技能详情 [技能ID]
```

## 实现方式

### 在线模式（默认）
1. 从GitHub仓库获取最新技能列表
2. 解析registry.json文件
3. 格式化显示技能信息

### 离线模式
1. 使用本地缓存的技能列表
2. 显示最后更新时间
3. 提示是否需要同步

## 输出格式

### 简洁模式
```
可用技能 (5个):
1. 天气 (weather) - 获取天气信息
2. 技能同步 (skill-hub-sync) - 同步技能
3. 技能提交 (skill-hub-submit) - 提交技能
4. 技能列表 (skill-hub-list) - 查看技能列表
5. 编程助手 (coding-agent) - 编程帮助
```

### 详细模式
```
技能详情: 天气 (weather)
────────────────────────────
描述: 获取当前天气和天气预报
作者: openclaw-system
版本: 1.0.0
触发词: 天气, 温度, 天气预报
依赖: curl
路径: skills/weather
下载次数: 0
评分: ★★★★☆ (4.0/5.0)
最后更新: 2026-02-27
────────────────────────────
```

## 文件结构
- `SKILL.md` - 本文件
- `list.sh` - 列表脚本
- `search.sh` - 搜索脚本
- `config.json` - 配置文件
- `cache/` - 缓存目录

## 配置说明

### config.json
```json
{
  "github": {
    "repo_url": "https://github.com/guaidashu/openclaw-skill-hub.git",
    "cache_ttl": 3600
  },
  "display": {
    "default_mode": "simple",
    "show_downloads": true,
    "show_rating": true,
    "group_by_category": false
  },
  "cache": {
    "enabled": true,
    "dir": "./cache",
    "max_age": 86400
  }
}
```

## 更新日志
- v1.0.0 (2026-02-27): 初始版本，基础列表功能