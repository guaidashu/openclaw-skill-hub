# SKILL.md - 天气技能

**触发词**：天气, 温度, 天气预报, 气象

**描述**：通过wttr.in或Open-Meteo获取当前天气和天气预报

**作者**：openclaw-system

**版本**：1.0.0

**依赖**：curl

## 功能
- 获取当前天气状况
- 获取天气预报（今天、明天、3天、一周）
- 支持全球大多数城市
- 无需API密钥

## 使用方法

### 当前天气
```bash
# 单行摘要
curl "wttr.in/北京?format=3"

# 详细当前条件
curl "wttr.in/上海?0"

# 特定城市
curl "wttr.in/广州?format=3"
```

### 天气预报
```bash
# 3天预报
curl "wttr.in/深圳"

# 一周预报
curl "wttr.in/杭州?format=v2"

# 特定日期 (0=今天, 1=明天, 2=后天)
curl "wttr.in/成都?1"
```

### 格式选项
```bash
# 单行格式
curl "wttr.in/南京?format=%l:+%c+%t+%w"

# JSON输出
curl "wttr.in/武汉?format=j1"

# PNG图片
curl "wttr.in/西安.png"
```

### 格式代码
- `%c` — 天气状况表情
- `%t` — 温度
- `%f` — "体感温度"
- `%w` — 风力
- `%h` — 湿度
- `%p` — 降水量
- `%l` — 位置

## 快速响应

**"天气怎么样？"**
```bash
curl -s "wttr.in/北京?format=%l:+%c+%t+(体感%f),+%w+风力,+%h+湿度"
```

**"会下雨吗？"**
```bash
curl -s "wttr.in/上海?format=%l:+%c+%p"
```

**"周末天气预报"**
```bash
curl "wttr.in/广州?format=v2"
```

## 注意事项
- 无需API密钥（使用wttr.in）
- 有速率限制；不要频繁请求
- 支持大多数全球城市
- 支持机场代码：`curl wttr.in/PVG`

## 文件结构
- `SKILL.md` - 本文件
- `README.md` - 详细说明文档

## 更新日志
- v1.0.0 (2026-02-27): 初始版本，基于OpenClaw官方天气技能