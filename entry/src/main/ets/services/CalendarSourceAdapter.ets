/**
 * CalendarSourceAdapter — 标准日历源适配器接口
 *
 * 所有日历源（CalDAV、ICS 订阅、本地、将来的 iCloud / Google 原生 API 等）
 * 都通过此接口与业务层对接，实现「对接模式标准化」。
 *
 * 新增一种日历源只需：
 *   1. 实现本接口
 *   2. 在 CalendarSourceAdapterRegistry 中注册
 *   3. CalendarSyncService 自动适配，无需修改同步编排逻辑
 */

import type {
  CalendarAccount,
  CalendarConnectionTestResult,
  CalendarEvent,
  CalendarEventDraft,
  CalendarFreeBusySlot,
  CalendarSource
} from "./CalendarTypes";

/* ===================================================================
 * 标准适配器数据类型 — 各适配器共用的通用格式
 * =================================================================== */

/** 适配器统一的列表结果 */
export interface AdapterListResult {
  readonly events: CalendarEvent[];
  readonly icsList?: string[];
  readonly failed: number;
  readonly total: number;
  readonly deletedHrefs?: string[];
  readonly syncToken?: string;
  readonly incremental?: boolean;
  readonly strategy?: string;
  readonly httpStatus?: number;
  readonly retryAfterSeconds?: number;
  readonly diagnosticJson?: string;
}

/** 发现到的日历源 */
export interface DiscoveredSource {
  readonly name: string;
  readonly description: string;
  readonly collectionUrl: string;
  readonly principalUrl: string;
  readonly homeSetUrl: string;
  readonly scheduleInboxUrl: string;
  readonly scheduleOutboxUrl: string;
  readonly calendarUserAddressSet: string;
  readonly ownerEmail: string;
  readonly color: string;
  readonly backgroundColor: string;
  readonly borderColor: string;
  readonly textColor: string;
  readonly isReadOnly: boolean;
  readonly permissionsJson: string;
  readonly supportedReportsJson: string;
  readonly supportedComponentsJson: string;
  readonly capabilitySource: string;
  readonly ctag: string;
  readonly syncToken: string;
  readonly syncStrategy: string;
}

/** PUT 事件结果 */
export interface PutEventResult {
  readonly href: string;
  readonly etag: string;
}

/** 发现过程诊断追踪 */
export interface DiscoveryTrace {
  readonly directCollectionUrl: string;
  readonly directCollectionMatched: boolean;
  readonly optionsUrl: string;
  readonly davHeader: string;
  readonly allowHeader: string;
  readonly optionsError: string;
  readonly roots: string[];
  readonly principalUrls: string[];
  readonly homeSetUrls: string[];
  readonly sourceUrls: string[];
  readonly errors: string[];
}

/* ===================================================================
 * 适配器能力标记
 * =================================================================== */

/** 适配器能力标记 */
export interface AdapterCapability {
  /** 是否支持日历自动发现（如 CalDAV principal → calendar-home-set） */
  readonly supportsDiscovery: boolean;
  /** 是否支持增量同步（sync-collection / sync-token） */
  readonly supportsIncrementalSync: boolean;
  /** 是否支持忙闲查询 */
  readonly supportsFreeBusy: boolean;
  /** 是否支持创建远程日历集合 */
  readonly supportsCreateCollection: boolean;
  /** 是否支持共享/授权 */
  readonly supportsSharing: boolean;
  /** 是否支持写入事件 */
  readonly supportsWrite: boolean;
  /** 支持的 iCalendar 组件列表（VEVENT, VTODO 等） */
  readonly supportedComponents: string[];
  /** 支持的认证类型 */
  readonly supportedAuthTypes: string[];
  /** 是否需要先发现再操作 */
  readonly discoveryRequired: boolean;
  /** 读取类型：fullSync=全量拉取, incremental=增量, poll=轮询 */
  readonly readStrategy: "fullSync" | "incremental" | "poll";
}

/** 适配器注册信息 */
export interface AdapterRegistration {
  /** 唯一标识，如 "caldav", "ics-subscription", "google-api" */
  readonly type: string;
  /** 展示名称 */
  readonly displayName: string;
  /** 简要描述 */
  readonly description: string;
  /** 能力标记 */
  readonly capability: AdapterCapability;
  /** 创建适配器实例的工厂函数 */
  readonly factory: (account: CalendarAccount) => CalendarSourceAdapter;
}

/* ===================================================================
 * 适配器接口定义
 * =================================================================== */

export interface CalendarSourceAdapter {
  /* -------- 连接与发现 -------- */

  /** 测试账号连接性，返回诊断结果 */
  testConnection(account: CalendarAccount): Promise<CalendarConnectionTestResult>;

  /** 自动发现可用的日历源集合（CalDAV principal → home-set → collections） */
  discoverSources(account: CalendarAccount): Promise<DiscoveredSource[]>;

  /** 追踪发现过程，返回详细诊断信息 */
  traceDiscovery(account: CalendarAccount): Promise<DiscoveryTrace>;

  /* -------- 事件操作 -------- */

  /** 拉取日历源下的所有事件 */
  listEvents(source: CalendarSource): Promise<CalendarEvent[]>;

  /** 拉取事件带详细状态（总数、失败数等），适配器统一格式 */
  listEventsWithStatus(source: CalendarSource): Promise<AdapterListResult>;

  /** 增量同步（基于 sync-token 或 ETag） */
  listEventsIncremental(source: CalendarSource, syncToken: string): Promise<AdapterListResult>;

  /** 创建事件 */
  createEvent(source: CalendarSource, draft: CalendarEventDraft): Promise<CalendarEvent>;

  /** 更新事件，返回新 href 和 etag */
  updateEvent(source: CalendarSource, event: CalendarEvent): Promise<PutEventResult>;

  /** 删除事件 */
  deleteEvent(source: CalendarSource, event: CalendarEvent): Promise<void>;

  /** 获取事件当前远端版本 */
  getCurrentEvent(source: CalendarSource, event: CalendarEvent): Promise<CalendarEvent | null>;

  /* -------- 日历集合管理 -------- */

  /** 在服务端创建日历集合 */
  createSourceCollection(account: CalendarAccount, homeSetUrl: string, name: string, color: string): Promise<DiscoveredSource>;

  /** 更新服务端日历集合的元数据（名称、颜色） */
  updateSourceMetadata(source: CalendarSource, name: string, color: string): Promise<DiscoveredSource>;

  /** 删除服务端日历集合 */
  deleteSourceCollection(source: CalendarSource): Promise<void>;

  /* -------- 高级功能 -------- */

  /** 忙闲查询 */
  queryFreeBusy(source: CalendarSource, startAt: number, endAt: number): Promise<CalendarFreeBusySlot[]>;

  /** 授权用户访问日历 */
  grantAccess(source: CalendarSource, email: string, role: string): Promise<void>;
}

/* ===================================================================
 * 辅助函数
 * =================================================================== */

/** 从 CalendarSource 推断适配器类型 */
export const inferAdapterType = (source: CalendarSource): string => {
  if (source.sourceType === "caldav") {
    return source.providerAdapterType ?? "caldav";
  }
  if (source.sourceType === "subscription") {
    return "ics-subscription";
  }
  return "local";
};

/** 从适配器类型获取展示名称 */
export const adapterDisplayName = (type: string): string => {
  const names: Record<string, string> = {
    "caldav": "CalDAV",
    "ics-subscription": "ICS 订阅",
    "local": "本地日历",
    "google-api": "Google Calendar API",
    "microsoft-graph": "Microsoft Graph API"
  };
  return names[type] ?? type;
};

/** 构建默认适配器能力 — 适用于 CalDAV */
export const defaultDavCapability = (): AdapterCapability => ({
  supportsDiscovery: true,
  supportsIncrementalSync: true,
  supportsFreeBusy: true,
  supportsCreateCollection: true,
  supportsSharing: true,
  supportsWrite: true,
  supportedComponents: ["VEVENT", "VTODO"],
  supportedAuthTypes: ["basic", "bearer"],
  discoveryRequired: true,
  readStrategy: "incremental"
});

/** 构建只读订阅适配器能力 */
export const defaultSubscriptionCapability = (): AdapterCapability => ({
  supportsDiscovery: false,
  supportsIncrementalSync: false,
  supportsFreeBusy: false,
  supportsCreateCollection: false,
  supportsSharing: false,
  supportsWrite: false,
  supportedComponents: ["VEVENT"],
  supportedAuthTypes: ["none", "basic"],
  discoveryRequired: false,
  readStrategy: "poll"
});
