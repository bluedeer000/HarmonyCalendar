/**
 * CalDavSourceAdapter — CalDAV 日历源适配器
 *
 * 将 CalDavClient 包装为 CalendarSourceAdapter 标准接口，
 * 所有 CalDAV 服务（Zoho、iCloud、Google、Nextcloud、自建等）共用此适配器，
 * 通过 CalendarProviderPresets 区分服务商特定的发现路径和认证方式。
 */

import {
  CalDavClient,
  CalDavDiscoveryTrace,
  DiscoveredCalendarSource,
  RemoteCalendarListResult
} from "./CalDavClient";
import { normalizeServerUrl } from "./CalendarFormat";
import {
  CalendarAccount,
  CalendarConnectionTestResult,
  CalendarEvent,
  CalendarEventDraft,
  CalendarFreeBusySlot,
  CalendarSource
} from "./CalendarTypes";
import {
  AdapterListResult,
  CalendarSourceAdapter,
  DiscoveredSource,
  DiscoveryTrace,
  PutEventResult
} from "./CalendarSourceAdapter";
import {
  buildProviderPresetJson,
  inferCalendarProviderType,
  normalizeProviderServerUrl,
  providerDiscoveryChecklist,
  providerDiagnosticHint,
  providerPresetFor
} from "./CalendarProviderPresets";


/* ===================================================================
 * 类型转换辅助
 * =================================================================== */

const caldavResultToAdapter = (result: RemoteCalendarListResult): AdapterListResult => ({
  events: result.events.map((remote: { event: CalendarEvent; ics: string }) => remote.event),
  icsList: result.events.map((remote: { event: CalendarEvent; ics: string }) => remote.ics),
  failed: result.failed,
  total: result.total,
  deletedHrefs: result.deletedHrefs,
  syncToken: result.syncToken,
  incremental: result.incremental,
  strategy: result.strategy ?? "full-sync",
  httpStatus: result.httpStatus,
  retryAfterSeconds: result.retryAfterSeconds,
  diagnosticJson: result.diagnosticJson
});

const toDiscoveredSource = (source: DiscoveredCalendarSource, strategy: string = ""): DiscoveredSource => ({
  name: source.name,
  description: source.description,
  collectionUrl: source.collectionUrl,
  principalUrl: source.principalUrl,
  homeSetUrl: source.homeSetUrl,
  scheduleInboxUrl: source.scheduleInboxUrl,
  scheduleOutboxUrl: source.scheduleOutboxUrl,
  calendarUserAddressSet: source.calendarUserAddressSet,
  ownerEmail: source.ownerEmail,
  color: source.color,
  backgroundColor: source.backgroundColor,
  borderColor: source.borderColor,
  textColor: source.textColor,
  isReadOnly: source.isReadOnly,
  permissionsJson: source.permissionsJson,
  supportedReportsJson: source.supportedReportsJson,
  supportedComponentsJson: source.supportedComponentsJson,
  capabilitySource: source.capabilitySource,
  ctag: source.ctag,
  syncToken: source.syncToken,
  syncStrategy: strategy
});

const toDiscoveryTrace = (trace: CalDavDiscoveryTrace): DiscoveryTrace => ({
  directCollectionUrl: trace.directCollectionUrl,
  directCollectionMatched: trace.directCollectionMatched,
  optionsUrl: trace.optionsUrl,
  davHeader: trace.davHeader,
  allowHeader: trace.allowHeader,
  optionsError: trace.optionsError,
  roots: trace.roots,
  principalUrls: trace.principalUrls,
  homeSetUrls: trace.homeSetUrls,
  sourceUrls: trace.sourceUrls,
  errors: trace.errors
});

const toPutEventResult = (result: { href: string; etag: string }): PutEventResult => ({
  href: result.href,
  etag: result.etag
});

/* ===================================================================
 * 客户端工厂
 * =================================================================== */

const buildDavClient = (account: CalendarAccount, extraCollectionUrl: string = ""): CalDavClient => {
  const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
  const serverUrl: string = normalizeServerUrl(
    normalizeProviderServerUrl(providerType, account.serverUrl, account.username)
  );
  return new CalDavClient(
    {
      id: account.id,
      displayName: account.displayName,
      serverUrl,
      username: account.username.trim(),
      password: account.password,
      authType: account.authType,
      bearerToken: account.bearerToken,
      customHeadersJson: account.customHeadersJson,
      isActive: account.isActive,
      providerType,
      providerPresetJson: account.providerPresetJson ?? buildProviderPresetJson(providerType, serverUrl)
    },
    extraCollectionUrl
  );
};

/** 从 CalendarSource 构建最小 account 用于 CalDavClient（需补充密码等敏感信息） */
const sourceToMinimalAccount = (source: CalendarSource): CalendarAccount => ({
  serverUrl: normalizeServerUrl(source.homeSetUrl.length > 0 ? source.homeSetUrl : source.collectionUrl),
  username: source.ownerEmail ?? "",
  password: "",
  authType: "basic",
  displayName: source.name,
  providerType: source.providerType ?? "custom",
  providerPresetJson: source.providerPresetJson ?? ""
});

/* ===================================================================
 * CalDAV 适配器实现
 * =================================================================== */

export class CalDavSourceAdapter implements CalendarSourceAdapter {
  private readonly account: CalendarAccount;

  constructor(account: CalendarAccount) {
    this.account = account;
  }

  /* -------- 连接与发现 -------- */

  async testConnection(account: CalendarAccount): Promise<CalendarConnectionTestResult> {
    const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
    const serverUrl: string = normalizeServerUrl(
      normalizeProviderServerUrl(providerType, account.serverUrl, account.username)
    );
    const preset = providerPresetFor(providerType);
    const client = buildDavClient(account);
    const trace: CalDavDiscoveryTrace = await client.traceDiscovery();

    let discoveredSources: DiscoveredCalendarSource[] = [];
    let discoveryError: string = "";
    try {
      discoveredSources = await client.discoverSources();
    } catch (error) {
      discoveryError = describeError(error);
    }

    const collectionUrl: string = discoveredSources.length > 0
      ? discoveredSources[0].collectionUrl
      : await client.resolveCollectionUrl();

    let listResult: RemoteCalendarListResult = { events: [], failed: 0, total: 0 };
    try {
      listResult = await buildDavClient(account, collectionUrl).listEventsWithStatus();
    } catch (error) {
      discoveryError = (discoveryError.length > 0 ? `${discoveryError}; ` : "") + describeError(error);
    }

    const capabilities: string[] = [];
    if (trace.davHeader.length > 0) {
      capabilities.push(`DAV=${trace.davHeader}`);
    }
    if (trace.allowHeader.length > 0) {
      capabilities.push(`Allows=${trace.allowHeader}`);
    }
    if (discoveredSources.length > 0) {
      const reports: string[] = [];
      discoveredSources.forEach((source: DiscoveredCalendarSource) => {
        if (source.supportedReportsJson.length > 0) {
          reports.push(source.supportedReportsJson);
        }
      });
      if (reports.length > 0) {
        capabilities.push(`reports=${reports.join(";")}`);
      }
    }

    const checklist: string = providerDiscoveryChecklist(providerType, account.serverUrl, account.username);
    const diagnosticHint: string = providerDiagnosticHint(providerType, discoveryError);

    return {
      providerType,
      normalizedServerUrl: serverUrl,
      collectionUrl,
      authHint: preset.authHint,
      discoveryHint: preset.discoveryHint,
      capabilities: capabilities.length > 0 ? capabilities.join(", ") : preset.capabilityHints.join(", "),
      diagnosticHint,
      discoveryTrace: JSON.stringify(trace),
      diagnosticJson: listResult.failed > 0
        ? JSON.stringify({ protocol: "caldav", failed: listResult.failed, total: listResult.total, checkedAt: Date.now() })
        : "",
      syncStrategy: listResult.events.length > 0 && listResult.events[0].event.etag.length > 0 ? "full-sync" : "",
      sources: discoveredSources.length,
      total: listResult.total,
      parsed: listResult.events.length,
      failed: listResult.failed
    };
  }

  async discoverSources(account: CalendarAccount): Promise<DiscoveredSource[]> {
    const client = buildDavClient(account);
    const sources: DiscoveredCalendarSource[] = await client.discoverSources();
    return sources.map((source: DiscoveredCalendarSource) => {
      const strategy: string = detectSyncStrategy(source);
      return toDiscoveredSource(source, strategy);
    });
  }

  async traceDiscovery(account: CalendarAccount): Promise<DiscoveryTrace> {
    const client = buildDavClient(account);
    const trace: CalDavDiscoveryTrace = await client.traceDiscovery();
    return toDiscoveryTrace(trace);
  }

  /* -------- 事件操作 -------- */

  async listEvents(source: CalendarSource): Promise<CalendarEvent[]> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const events: { event: CalendarEvent; ics: string }[] = await client.listEvents();
    return events.map((remote: { event: CalendarEvent; ics: string }) => remote.event);
  }

  async listEventsWithStatus(source: CalendarSource): Promise<AdapterListResult> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const result: RemoteCalendarListResult = await client.listEventsWithStatus();
    return caldavResultToAdapter(result);
  }

  async listEventsIncremental(source: CalendarSource, syncToken: string): Promise<AdapterListResult> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const result: RemoteCalendarListResult = await client.listEventsSinceSyncToken(syncToken);
    return caldavResultToAdapter(result);
  }

  async createEvent(source: CalendarSource, draft: CalendarEventDraft): Promise<CalendarEvent> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const event: CalendarEvent = draftToEvent(draft, source);
    const result = await client.putEvent(event);
    return { ...event, href: result.href, etag: result.etag };
  }

  async updateEvent(source: CalendarSource, event: CalendarEvent): Promise<PutEventResult> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const result = await client.putEvent(event);
    return toPutEventResult(result);
  }

  async deleteEvent(source: CalendarSource, event: CalendarEvent): Promise<void> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    await client.deleteEvent(event);
  }

  async getCurrentEvent(source: CalendarSource, event: CalendarEvent): Promise<CalendarEvent | null> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    return client.getCurrentEvent(event);
  }

  /* -------- 日历集合管理 -------- */

  async createSourceCollection(
    account: CalendarAccount,
    homeSetUrl: string,
    name: string,
    color: string
  ): Promise<DiscoveredSource> {
    const client = buildDavClient(account);
    const remote: DiscoveredCalendarSource = await client.createCalendarCollection(homeSetUrl, name, color);
    return toDiscoveredSource(remote, "full-sync");
  }

  async updateSourceMetadata(source: CalendarSource, name: string, color: string): Promise<DiscoveredSource> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const remote: DiscoveredCalendarSource = await client.updateCalendarCollection(
      source.collectionUrl,
      name,
      color
    );
    return toDiscoveredSource(remote, source.syncStrategy ?? "full-sync");
  }

  async deleteSourceCollection(source: CalendarSource): Promise<void> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    await client.deleteCalendarCollection(source.collectionUrl);
  }

  /* -------- 高级功能 -------- */

  async queryFreeBusy(
    source: CalendarSource,
    startAt: number,
    endAt: number
  ): Promise<CalendarFreeBusySlot[]> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    const queryUrl: string = source.scheduleOutboxUrl?.length ?? 0 > 0
      ? (source.scheduleOutboxUrl ?? "")
      : (source.principalUrl?.length ?? 0) > 0
        ? (source.principalUrl ?? "")
        : source.collectionUrl;
    return client.queryFreeBusy(startAt, endAt, queryUrl);
  }

  async grantAccess(source: CalendarSource, email: string, role: string): Promise<void> {
    const account: CalendarAccount = mergeAccount(source, this.account);
    const client = buildDavClient(account, source.collectionUrl);
    await client.grantCalendarAccess(source.collectionUrl, email, role);
  }
}

/* ===================================================================
 * 内部辅助函数
 * =================================================================== */

/** 合并 source 中的账号信息与构造时传入的 account，优先使用传入的敏感信息 */
const mergeAccount = (source: CalendarSource, fallback: CalendarAccount): CalendarAccount => {
  const providerType: string = source.providerType ?? fallback.providerType ?? "custom";
  const serverUrl: string = normalizeServerUrl(
    (source.homeSetUrl.length > 0 ? source.homeSetUrl : source.collectionUrl) || fallback.serverUrl
  );
  return {
    id: fallback.id,
    displayName: source.name || fallback.displayName,
    serverUrl,
    username: fallback.username || source.ownerEmail || "",
    password: fallback.password || "",
    authType: fallback.authType ?? "basic",
    bearerToken: fallback.bearerToken,
    customHeadersJson: fallback.customHeadersJson,
    isActive: fallback.isActive ?? true,
    providerType,
    providerPresetJson: source.providerPresetJson || fallback.providerPresetJson || ""
  };
};

/** 根据发现源信息推断同步策略 */
const detectSyncStrategy = (source: DiscoveredCalendarSource): string => {
  if (source.syncToken.length > 0) {
    return "incremental";
  }
  if (source.ctag.length > 0) {
    return "ctag-based";
  }
  return "full-sync";
};

/** 从 draft + source 构建临时 CalendarEvent 用于 PUT */
const draftToEvent = (draft: CalendarEventDraft, source: CalendarSource): CalendarEvent => {
  const uid: string = `${source.id}_${Date.now()}_${Math.random().toString(36).substring(2, 12)}@caldav`;
  return {
    id: draft.id ?? `draft_${Date.now()}`,
    sourceId: source.id ?? "",
    uid,
    href: "",
    etag: "",
    title: draft.title,
    startAt: draft.startAt,
    endAt: draft.endAt,
    allDay: draft.allDay,
    location: draft.location ?? "",
    notes: draft.notes ?? "",
    reminderMinutes: draft.reminderMinutes ?? 0,
    secondReminderMinutes: draft.secondReminderMinutes ?? 0,
    rrule: draft.rrule ?? "",
    categoryColor: draft.categoryColor ?? source.color,
    backgroundColor: draft.backgroundColor ?? source.backgroundColor ?? source.color,
    borderColor: draft.borderColor ?? source.borderColor ?? source.color,
    textColor: draft.textColor ?? source.textColor ?? "#FFFFFF",
    dragBackgroundColor: draft.dragBackgroundColor ?? "",
    eventCategory: draft.eventCategory ?? "",
    eventKind: draft.eventKind ?? "calendar",
    url: draft.url ?? "",
    attendees: draft.attendees ?? "",
    attendeeJson: draft.attendeeJson ?? "",
    organizerName: draft.organizerName ?? "",
    organizerEmail: draft.organizerEmail ?? "",
    conferenceUrl: draft.conferenceUrl ?? "",
    attachmentUrl: draft.attachmentUrl ?? "",
    attachmentsJson: draft.attachmentsJson ?? "",
    travelMinutes: draft.travelMinutes ?? 0,
    comingDuration: draft.comingDuration ?? 0,
    availability: draft.availability ?? "busy",
    freeBusyTransparent: draft.freeBusyTransparent ?? false,
    privacy: draft.privacy ?? "default",
    timeZone: draft.timeZone ?? "",
    eventStatus: draft.eventStatus ?? "confirmed",
    appointmentStatus: draft.appointmentStatus ?? "available",
    appointmentCapacity: draft.appointmentCapacity ?? 1,
    appointmentBookedCount: draft.appointmentBookedCount ?? 0,
    appointmentMinDurationMinutes: draft.appointmentMinDurationMinutes ?? 0,
    appointmentMaxDurationMinutes: draft.appointmentMaxDurationMinutes ?? 0,
    appointmentBufferBeforeMinutes: draft.appointmentBufferBeforeMinutes ?? 0,
    appointmentBufferAfterMinutes: draft.appointmentBufferAfterMinutes ?? 0,
    appointmentDeadlineMinutes: draft.appointmentDeadlineMinutes ?? 0,
    appointmentPublicUrl: draft.appointmentPublicUrl ?? "",
    appointmentFormJson: draft.appointmentFormJson ?? "",
    appointmentTimezone: draft.appointmentTimezone ?? "",
    appointmentSlotIntervalMinutes: draft.appointmentSlotIntervalMinutes ?? 0,
    appointmentApprovalRequired: draft.appointmentApprovalRequired ?? false,
    bookingJson: draft.bookingJson ?? "",
    bookingContactName: draft.bookingContactName ?? "",
    bookingContactEmail: draft.bookingContactEmail ?? "",
    bookingContactPhone: draft.bookingContactPhone ?? "",
    bookingConfirmationStatus: draft.bookingConfirmationStatus ?? "",
    bookingStatus: draft.bookingStatus ?? "",
    exdate: draft.exdate ?? "",
    rdate: draft.rdate ?? "",
    recurrenceId: draft.recurrenceId ?? "",
    sequence: draft.sequence ?? 0,
    reminderOffsets: draft.reminderOffsets ?? "",
    dueAt: draft.dueAt ?? 0,
    completedAt: draft.completedAt ?? 0,
    priority: draft.priority ?? 0,
    percentComplete: draft.percentComplete ?? 0,
    milestoneStatus: draft.milestoneStatus ?? "",
    dueDateClass: draft.dueDateClass ?? "",
    groupId: draft.groupId ?? "",
    displayMode: draft.displayMode ?? "",
    overlap: draft.overlap ?? false,
    editable: draft.editable ?? true,
    startEditable: draft.startEditable ?? true,
    durationEditable: draft.durationEditable ?? true,
    resourceEditable: draft.resourceEditable ?? true,
    interactive: draft.interactive ?? true,
    eventReadOnly: draft.eventReadOnly ?? false,
    isVisible: draft.isVisible ?? true,
    isPending: draft.isPending ?? false,
    isFocused: draft.isFocused ?? false,
    overlapPosition: draft.overlapPosition ?? 0,
    overlapCount: draft.overlapCount ?? 1,
    classNames: draft.classNames ?? "",
    customStyleJson: draft.customStyleJson ?? "",
    constraintJson: draft.constraintJson ?? "",
    extendedPropsJson: draft.extendedPropsJson ?? "",
    rawPropsJson: draft.rawPropsJson ?? "",
    resourceIdsJson: draft.resourceIdsJson ?? "",
    roomIdsJson: draft.roomIdsJson ?? "",
    resourceStatusJson: draft.resourceStatusJson ?? "",
    alarmAction: draft.alarmAction ?? "",
    snoozeMinutes: draft.snoozeMinutes ?? 0,
    snoozeTimes: draft.snoozeTimes ?? 0,
    allDayReminderAt: draft.allDayReminderAt ?? "",
    alarmActionsJson: draft.alarmActionsJson ?? "",
    lastModified: Date.now(),
    syncStatus: "clean",
    conflictStatus: "none",
    reminderId: 0,
    conflictJson: ""
  };
};

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
