# 天气技能

通过wttr.in获取天气信息的OpenClaw技能。

## 功能特点

- 🌤️ **实时天气**：获取当前天气状况
- 📅 **天气预报**：支持1-3天预报
- 🌍 **全球覆盖**：支持大多数城市
- 🆓 **免费使用**：无需API密钥
- 📱 **多种格式**：文本、JSON、图片输出

## 安装方法

1. 将本目录复制到OpenClaw的skills目录
2. 确保系统已安装curl
3. 重启OpenClaw服务

## 使用示例

### 基本查询
```bash
# 北京天气
curl "wttr.in/北京"

# 上海天气（单行格式）
curl "wttr.in/上海?format=3"

# 广州天气预报
curl "wttr.in/广州?1"
```

### 高级查询
```bash
# 获取JSON格式数据
curl "wttr.in/深圳?format=j1"

# 获取天气图片
curl "wttr.in/杭州.png"

# 自定义格式
curl "wttr.in/南京?format=%l:+%c+%t+%w+%h"
```

## 支持的城市格式

- 中文城市名：`北京`、`上海`、`广州`
- 拼音城市名：`beijing`、`shanghai`
- 机场代码：`PVG`（上海浦东）、`PEK`（北京首都）
- 经纬度：`@31.2304,121.4737`

## 常见问题

### Q: 为什么查询失败？
A: 可能原因：
1. 城市名称拼写错误
2. 网络连接问题
3. wttr.in服务暂时不可用

### Q: 如何获取更详细的预报？
A: 使用`format=v2`参数获取更详细的一周预报：
```bash
curl "wttr.in/北京?format=v2"
```

### Q: 支持中文输出吗？
A: wttr.in默认支持中文，但部分格式可能显示英文。

## 性能优化

- 避免频繁查询同一城市（有缓存机制）
- 对于常用城市，可以考虑本地缓存
- 批量查询时适当添加延迟

## 相关资源

- [wttr.in官方文档](https://wttr.in/:help)
- [Open-Meteo API](https://open-meteo.com/)
- [中国气象局](http://www.cma.gov.cn/)

## 许可证

MIT License