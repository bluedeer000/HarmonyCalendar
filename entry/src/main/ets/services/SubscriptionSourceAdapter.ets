/**
 * SubscriptionSourceAdapter — ICS 订阅源适配器
 *
 * 将 CalendarSubscriptionClient 包装为 CalendarSourceAdapter 标准接口，
 * 使 ICS 订阅（URL）通过统一的适配器模式接入系统。
 */

import {
  CalendarEvent,
  CalendarEventDraft,
  CalendarFreeBusySlot,
  CalendarSource,
  CalendarAccount,
  CalendarConnectionTestResult
} from "./CalendarTypes";
import { CalendarSubscriptionClient, SubscriptionFetchResult, SubscriptionHttpError } from "./CalendarSubscriptionClient";
import {
  AdapterListResult,
  CalendarSourceAdapter,
  DiscoveredSource,
  DiscoveryTrace,
  PutEventResult
} from "./CalendarSourceAdapter";

/* ===================================================================
 * ICS 订阅适配器实现
 * =================================================================== */

export class SubscriptionSourceAdapter implements CalendarSourceAdapter {
  private readonly account: CalendarAccount;
  private readonly client: CalendarSubscriptionClient;

  constructor(account: CalendarAccount = { serverUrl: "", username: "", password: "" }) {
    this.account = account;
    this.client = new CalendarSubscriptionClient();
  }

  /* -------- 连接与发现 -------- */

  async testConnection(account: CalendarAccount): Promise<CalendarConnectionTestResult> {
    const url: string = account.serverUrl.trim();
    if (url.length === 0) {
      throw new Error("订阅源 URL 不能为空");
    }

    try {
      const result: SubscriptionFetchResult = await this.client.fetch(url);
      return {
        providerType: "ics-subscription",
        normalizedServerUrl: url,
        collectionUrl: url,
        authHint: "ICS 订阅通常无需认证，部分服务商支持 HTTP Basic Auth",
        discoveryHint: "直接读取 URL 返回的 iCalendar 数据",
        capabilities: "VEVENT",
        diagnosticHint: result.notModified === true ? "订阅内容未变更" : "订阅源可访问",
        discoveryTrace: JSON.stringify({
          url,
          httpStatus: result.httpStatus,
          etag: result.etag,
          lastModified: result.lastModified,
          notModified: result.notModified === true
        }),
        diagnosticJson: result.diagnosticJson ?? "",
        syncStrategy: "poll",
        sources: 1,
        total: result.total,
        parsed: result.events.length,
        failed: result.failed
      };
    } catch (error) {
      const message: string = describeError(error);
      const httpStatus: number = httpStatusFromError(error);
      return {
        providerType: "ics-subscription",
        normalizedServerUrl: url,
        collectionUrl: url,
        authHint: "确认 URL 可访问，如需认证请提供 header",
        discoveryHint: "订阅源连接失败",
        capabilities: "",
        diagnosticHint: `连接失败: ${message}`,
        discoveryTrace: JSON.stringify({ url, error: message, httpStatus }),
        diagnosticJson: JSON.stringify({ protocol: "ics-subscription", error: message, checkedAt: Date.now() }),
        syncStrategy: "",
        sources: 0,
        total: 0,
        parsed: 0,
        failed: 1
      };
    }
  }

  async discoverSources(_account: CalendarAccount): Promise<DiscoveredSource[]> {
    const url: string = _account.serverUrl.trim();
    return [{
      name: _account.displayName ?? "订阅日历",
      description: "自动发现的 ICS 订阅源",
      collectionUrl: url,
      principalUrl: "",
      homeSetUrl: "",
      scheduleInboxUrl: "",
      scheduleOutboxUrl: "",
      calendarUserAddressSet: "",
      ownerEmail: "",
      color: "#2563EB",
      backgroundColor: "#2563EB",
      borderColor: "#2563EB",
      textColor: "#FFFFFF",
      isReadOnly: true,
      permissionsJson: "read",
      supportedReportsJson: "",
      supportedComponentsJson: JSON.stringify(["VEVENT"]),
      capabilitySource: "ics-subscription",
      ctag: "",
      syncToken: "",
      syncStrategy: "poll"
    }];
  }

  async traceDiscovery(_account: CalendarAccount): Promise<DiscoveryTrace> {
    return {
      directCollectionUrl: _account.serverUrl,
      directCollectionMatched: false,
      optionsUrl: _account.serverUrl,
      davHeader: "",
      allowHeader: "",
      optionsError: "ICS 订阅不支持 DAV 发现",
      roots: [_account.serverUrl],
      principalUrls: [],
      homeSetUrls: [],
      sourceUrls: [_account.serverUrl],
      errors: []
    };
  }

  /* -------- 事件操作 -------- */

  async listEvents(source: CalendarSource): Promise<CalendarEvent[]> {
    const result: SubscriptionFetchResult = await this.client.fetch(
      source.subscriptionUrl ?? source.collectionUrl,
      source.subscriptionEtag ?? "",
      source.subscriptionLastModified ?? ""
    );
    return result.events;
  }

  async listEventsWithStatus(source: CalendarSource): Promise<AdapterListResult> {
    const result: SubscriptionFetchResult = await this.client.fetch(
      source.subscriptionUrl ?? source.collectionUrl,
      source.subscriptionEtag ?? "",
      source.subscriptionLastModified ?? ""
    );
    return {
      events: result.events,
      icsList: [],
      failed: result.failed,
      total: result.total,
      deletedHrefs: [],
      syncToken: result.etag,
      incremental: false,
      strategy: "poll",
      httpStatus: result.httpStatus,
      retryAfterSeconds: result.retryAfterSeconds,
      diagnosticJson: result.diagnosticJson
    };
  }

  async listEventsIncremental(source: CalendarSource, _syncToken: string): Promise<AdapterListResult> {
    // ICS 订阅不支持真正的增量同步，使用 ETag/If-Modified-Since 做条件请求
    return this.listEventsWithStatus(source);
  }

  async createEvent(_source: CalendarSource, _draft: CalendarEventDraft): Promise<CalendarEvent> {
    throw new Error("ICS 订阅源为只读，不支持创建事件");
  }

  async updateEvent(_source: CalendarSource, _event: CalendarEvent): Promise<PutEventResult> {
    throw new Error("ICS 订阅源为只读，不支持更新事件");
  }

  async deleteEvent(_source: CalendarSource, _event: CalendarEvent): Promise<void> {
    throw new Error("ICS 订阅源为只读，不支持删除事件");
  }

  async getCurrentEvent(_source: CalendarSource, _event: CalendarEvent): Promise<CalendarEvent | null> {
    throw new Error("ICS 订阅源不支持单事件获取");
  }

  /* -------- 日历集合管理 -------- */

  async createSourceCollection(
    _account: CalendarAccount,
    _homeSetUrl: string,
    _name: string,
    _color: string
  ): Promise<DiscoveredSource> {
    throw new Error("ICS 订阅源不支持服务端创建日历集合");
  }

  async updateSourceMetadata(_source: CalendarSource, _name: string, _color: string): Promise<DiscoveredSource> {
    throw new Error("ICS 订阅源不支持修改远端元数据");
  }

  async deleteSourceCollection(_source: CalendarSource): Promise<void> {
    throw new Error("ICS 订阅源不支持删除远端集合");
  }

  /* -------- 高级功能 -------- */

  async queryFreeBusy(
    _source: CalendarSource,
    _startAt: number,
    _endAt: number
  ): Promise<CalendarFreeBusySlot[]> {
    return [];
  }

  async grantAccess(_source: CalendarSource, _email: string, _role: string): Promise<void> {
    throw new Error("ICS 订阅源不支持共享授权");
  }
}

/* ===================================================================
 * 辅助函数
 * =================================================================== */

const describeError = (error: Object): string => {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string") {
    return error;
  }
  try {
    return JSON.stringify(error);
  } catch {
    return `${error}`;
  }
};

const httpStatusFromError = (error: Object): number => {
  if (error instanceof SubscriptionHttpError) {
    return error.status;
  }
  const match: RegExpMatchArray | null = describeError(error).match(/返回\s+(\d{3})|HTTP\s+(\d{3})/i);
  if (match === null) {
    return 0;
  }
  const value: string = match[1] ?? match[2] ?? "";
  const parsed: number = Number(value);
  return Number.isNaN(parsed) ? 0 : parsed;
};
