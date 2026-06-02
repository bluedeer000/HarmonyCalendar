# Macto 日历

独立 HarmonyOS 项目，保留 Zoho CalDAV 双向同步作为日历主数据源。

## 上架分支

- 当前应用市场上架分支：`release/appgallery`
- AppGallery 提交材料目录：`docs/appgallery/`
- 发布前自检脚本：`scripts/preflight_release_check.sh`

## 当前能力

- Zoho CalDAV 账号配置。
- Zoho CalDAV 测试连接，显示发现到的 collection URL、远端对象数、解析数和失败数。
- 本地 SQLite 缓存日程和同步状态。
- 日视图、周视图、月视图和全部列表视图切换。
- 月历单元格展示当天日程颜色点和首个日程标题，点击日期会快速进入该日视图。
- 快速回到今天，搜索后可一键清空搜索条件。
- 按标题、地点、备注搜索筛选日程。
- 日程分类颜色输入、展示、SQLite 持久化，并写入/读取 `X-HARMONY-COLOR`。
- 本地按展开后的日程实例判断重叠，并在日程行和表单编辑时展示冲突提示。
- 新建日程，先进入本地待同步队列，再上传到 Zoho。
- 编辑已有日程，复用表单并进入本地待同步队列。
- 删除日程，先本地标记，再同步删除 Zoho 远端对象。
- 同步时清理 Zoho 端已删除、且本地未修改的缓存日程。
- 支持提醒分钟，写入/读取 `VALARM`。
- 支持第二提醒，写入/读取多个 `VALARM`。
- 支持参会人、网页链接、视频会议链接、附件链接、忙闲、隐私、旅行时间和时区字段。
- 支持任务、专注时间、外出、办公地点和预约类型，用于对齐 Google Calendar 常见事件类型。
- 支持系统本地提醒发布/取消，提醒 ID 会写入本地缓存。
- 支持重复规则，写入/读取原始 `RRULE`，并展开基础 `DAILY/WEEKLY/MONTHLY/YEARLY` 实例用于日/周/月/列表展示。
- 头部展示本地待同步/已同步数量，日程行展示同步状态。
- CalDAV 支持 collection discovery：可从根地址尝试发现 `current-user-principal`、`calendar-home-set` 和支持 `VEVENT` 的日历 collection。
- CalDAV `PROPFIND` 拉取 `.ics` 列表，`GET` 读取 `VEVENT`，`PUT` 上传，`DELETE` 删除。
- 保留 `UID`、`href`、`ETag`、`syncStatus`、`RRULE` 和提醒信息。
- 保留 `ATTENDEE`、`URL`、`ATTACH`、`TRANSP`、`CLASS`、`TZID` 以及 Harmony 自定义扩展字段。
- 本地数据库使用加密 RDB Store，安全级别为 `S3`。
- 详细对标分析见 [FEATURE_GAP_ANALYSIS.md](FEATURE_GAP_ANALYSIS.md)。

## Zoho 配置

页面里的 CalDAV 地址可以填写 Zoho CalDAV discovery 地址或具体日历 collection URL。推荐默认使用 `https://calendar.zoho.com/.well-known/caldav`；应用会先尝试自动发现可用 collection。如果 Zoho 返回不完整或账号权限受限，再手动填写具体日历路径。

账号建议使用 Zoho 邮箱/用户名和应用专用密码。

## 命令行构建

```bash
cd /Users/mini/mactoHarmony/HarmonyCalendar
NODE_HOME=/usr/local \
JAVA_HOME=/Users/mini/.jdk/jdk-17.0.19+10/Contents/Home \
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk/default \
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw \
  --mode module -p module=entry@default -p product=default assembleHap --no-daemon
```

当前项目未绑定可复用的仓库级签名配置，命令行默认会产出 unsigned HAP。要真机安装或提交应用市场，需要在 DevEco Studio 里打开本项目后，到 Signing Configs 里为 `com.macto.harmonycalendar` 生成发布签名，并保管好证书与 profile。

## 仍需真机验证

- Harmony `NetworkKit` 是否允许运行时发送 `PROPFIND`。ArkTS 编译通过，但 CalDAV 方法需要在真机/模拟器网络栈上确认。
- Zoho discovery 和具体 collection URL 都需要用真实账号测试，确认根地址发现、认证、重定向、证书和 ETag 表现。
- 本地系统提醒需要在真机上确认 `PUBLISH_AGENT_REMINDER` 授权、通知开关和到点触发。
- 重复日程目前仅展开基础 `FREQ/INTERVAL/COUNT/UNTIL`，不支持 `BYDAY`、`EXDATE`、`RDATE`、`RECURRENCE-ID` 和单次例外编辑。

## 真机测试清单

1. 在 DevEco Studio 打开本项目，为 `com.macto.harmonycalendar` 配置真机可安装的 Signing Config。
2. 连接 HarmonyOS 真机并确认 `hdc list targets` 能看到设备。
3. 安装签名后的 HAP，启动应用。
4. 在 Zoho CalDAV 区填写根地址或 collection URL、用户名和应用专用密码，先点“测试连接”。
5. “测试连接”应返回发现到的 collection URL、远端对象数、解析数和失败数。
6. 新建一个带提醒和分类颜色的日程，点“同步”，再到 Zoho 日历确认远端出现。
7. 在 Zoho 修改或删除该日程，回到应用点“同步”，确认本地更新或删除。
8. 新建 `FREQ=WEEKLY;COUNT=3` 的重复日程，确认日/周/月/列表视图能看到展开实例。
9. 创建未来提醒，确认系统通知权限、通知开关和到点提醒都正常。

## 产物

```text
entry/build/default/outputs/default/entry-default-unsigned.hap
```
