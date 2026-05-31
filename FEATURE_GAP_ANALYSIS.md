# macOS Calendar / Google Calendar 功能对标

## 参考范围

- Apple Calendar User Guide for macOS Tahoe 26：事件、全天/多日、重复、地点与旅行时间、提醒、邀请、FaceTime、备注/URL/文件、多日历、共享、订阅、刷新、时区和通知等。参考 Apple Support 的 [Add, modify, or delete events](https://support.apple.com/guide/calendar/add-modify-or-delete-events-icalwr13-events/16.0/mac/26)、[Add notes, a URL, or files](https://support.apple.com/en-asia/guide/calendar/icl58679aba2/mac) 和 [Calendar settings](https://support.apple.com/en-euro/guide/calendar/icle574a4381/mac)。
- Google Calendar Help：普通事件、参会人、Google Meet、颜色、重复、隐私、任务、专注时间、外出、办公地点、预约日程、共享权限、时区和可用性。参考 Google Support 的 [attachments](https://support.google.com/calendar/answer/6192039?hl=en&ref_topic=10510450)、[video conferencing](https://support.google.com/calendar/answer/9896550?hl=en&ref_topic=10510450)、[tasks](https://support.google.com/calendar/answer/9901136?hl=en&ref_topic=14286980)、[visibility](https://support.google.com/calendar/answer/34580?hl=en&ref_topic=10510243)、[appointment schedules](https://support.google.com/calendar/answer/10729749?hl=en&ref_topic=10729441) 和 [notifications](https://support.google.com/calendar/answer/37242?hl=en&ref_topic=10510243)。

## 已有能力

- 本地加密 SQLite 缓存、待同步状态、CalDAV 双向同步。
- Zoho/iCloud/Google/Nextcloud/自定义 CalDAV 预设，多账号保存和切换。
- 日/周/月/年/列表视图、搜索、今天、颜色、提醒、基础重复、冲突提示、地图打开地点。
- `UID`、`href`、`ETag`、`RRULE`、`VALARM`、颜色和事件类型持久化。
- 参会人、链接、附件、视频会议、第二提醒、忙闲、隐私、旅行时间、时区、事件类型。
- 标准日历源适配器模式（`CalendarSourceAdapter`），支持 CalDAV 和 ICS 订阅。
- 适配器注册中心（`CalendarSourceAdapterRegistry`），新增日历源类型无需修改核心代码。

## 标准日历源适配器架构

### 核心接口

| 接口/类 | 职责 |
|---|---|
| `CalendarSourceAdapter` | 统一标准接口：连接、发现、事件 CRUD、集合管理、FreeBusy、共享 |
| `CalDavSourceAdapter` | CalDAV 协议实现，包装 `CalDavClient` |
| `SubscriptionSourceAdapter` | ICS 订阅实现，包装 `CalendarSubscriptionClient` |
| `CalendarSourceAdapterRegistry` | 适配器注册中心，管理适配器查找与工厂创建 |
| `CalendarProviderPresets` | 服务商预设配置，携带 `adapterType` 指向对应适配器 |

### 适配器支持的特性

| 特性 | CalDAV | ICS 订阅 |
|---|---|---|
| 自动发现（principal → home-set） | ✅ | ❌（直接使用 URL） |
| 增量同步（sync-token） | ✅ | ❌（依赖 ETag/304） |
| 全量同步 | ✅ | ✅ |
| 创建事件 | ✅ | ❌（只读） |
| 更新事件 | ✅ | ❌（只读） |
| 删除事件 | ✅ | ❌（只读） |
| FreeBusy 查询 | ✅ | ❌ |
| 服务端创建日历集合 | ✅ | ❌ |
| 共享/授权 | ✅ | ❌ |

### 新增日历源类型的步骤

1. 实现 `CalendarSourceAdapter` 接口
2. 在 `CalendarSourceAdapterRegistry.registerAdapter()` 注册
3. `CalendarSyncService` 自动适配，无需修改同步编排代码

示例：添加 Google Calendar API 适配器

```typescript
const registry = CalendarSourceAdapterRegistry.getInstance();
registry.registerAdapter({
  type: "google-api",
  displayName: "Google Calendar API",
  description: "使用 Google Calendar API 直接对接",
  capability: { /* AdapterCapability */ },
  factory: (account) => new GoogleApiSourceAdapter(account)
});
```

## 本次已整合

- 参会人：编辑页支持邮箱列表，CalDAV 写入/读取 `ATTENDEE`。
- 链接和附件：支持网页 URL、附件 URL，写入/读取 `URL`、`ATTACH`。
- 视频会议：支持视频会议链接，写入/读取 `X-HARMONY-CONFERENCE-URL`。
- 第二提醒：支持两个提醒，写入/读取多个 `VALARM`。
- 忙闲状态：支持"忙/空闲"，写入/读取 `TRANSP:OPAQUE/TRANSPARENT`。
- 隐私：支持默认/公开/私密/机密，写入/读取 `CLASS`。
- 旅行时间：支持旅行分钟，使用 `X-HARMONY-TRAVEL-MINUTES` 保留。
- 时区：支持填写 TZID，非全天事件写入 `DTSTART;TZID=...` / `DTEND;TZID=...`。
- Google 风格事件类型：新增任务、专注、外出、办公地点、预约，并持久化到本地与 CalDAV。
- 搜索与列表摘要：参会人、链接、会议链接纳入搜索，日程行展示提醒、会议、旅行、忙闲、隐私和重复状态。
- 标准日历源适配器模式：`CalendarSourceAdapter` + `CalDavSourceAdapter` + `SubscriptionSourceAdapter` + `CalendarSourceAdapterRegistry`，所有操作通过适配器接口完成。
- 服务商预设已标注 `adapterType`，新服务商只需注册预设 + 适配器即可接入。
- ICS 订阅源管理：支持添加、编辑、删除订阅源，ETag/If-Modified-Since 条件请求。

## 仍不建议直接做成纯本地功能的缺口

- Google Meet 自动创建、自动拒绝会议、Focus time 勿扰、Out of office 自动回复/自动拒绝、Appointment schedule 公开预约页：这些依赖 Google Workspace/Calendar API、OAuth 和服务器端策略，CalDAV 只能保存近似事件字段。
- Apple/iCloud 共享权限、受邀者 RSVP 状态、可用性查询、日历订阅管理、系统级 Focus filter、Siri Suggestions：需要平台账户权限或系统服务，不适合只靠本应用本地数据库模拟。
- 复杂重复例外：`BYDAY`、`EXDATE`、`RDATE`、`RECURRENCE-ID`、单次例外编辑还未实现，是下一批最值得补的同步层能力。

## 未来可扩展的适配器类型

| 适配器类型 | 说明 | 优先级 |
|---|---|---|
| `google-api` | 使用 Google Calendar API（OAuth 2.0），支持 Meet/Focus/OutOfOffice 等原生功能 | 高 |
| `microsoft-graph` | 使用 Microsoft Graph Calendar API，支持 Exchange Online/Office 365 | 中 |
| `exchange` | 使用 Exchange Web Services (EWS)，支持自建 Exchange | 低 |
| `icloud-native` | 使用 Apple Calendar Server API（如果有） | 低 |
| `local` | 纯本地日历源，不依赖任何远端服务 | 低 |
