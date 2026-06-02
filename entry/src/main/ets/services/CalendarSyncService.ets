import { CalDavClient, CalDavDiscoveryTrace, CalDavHttpError, DiscoveredCalendarSource, RemoteCalendarEvent, RemoteCalendarListResult } from "./CalDavClient";
import { CalendarSubscriptionClient, SubscriptionFetchResult, SubscriptionHttpError } from "./CalendarSubscriptionClient";
import { CalendarSourceAdapter, AdapterListResult } from "./CalendarSourceAdapter";
import { CalendarSourceAdapterRegistry } from "./CalendarSourceAdapterRegistry";
import { CalendarLocalStore } from "./CalendarLocalStore";
import { CalendarReminderService } from "./CalendarReminderService";
import { buildIcsCalendar, parseIcsEvents, normalizeServerUrl } from "./CalendarFormat";
import {
  inferCalendarProviderType,
  normalizeProviderServerUrl,
  buildProviderPresetJson,
  providerDiscoveryChecklist,
  providerDiagnosticHint,
  providerPresetFor
} from "./CalendarProviderPresets";
import {
// ---- ArkTS spread helper ----
  CalendarAccount,
  CalendarConnectionTestResult,
  CalendarDateMarker,
  CalendarEvent,
  CalendarEventDraft,
  CalendarFreeBusyResult,
  CalendarFreeBusySlot,
  CalendarResource,
  CalendarReminderPreferences,
  CalendarSource,
  CalendarSyncResult,
  CalendarViewConfig
} from "./CalendarTypes";

interface ShareMember {
  readonly email: string;
  readonly role: string;
  readonly addedAt?: number;
  readonly diagnostic?: string;
}

export class CalendarSyncService {
  private readonly store: CalendarLocalStore;
  private readonly reminderService: CalendarReminderService | null;

  constructor(store: CalendarLocalStore, reminderService: CalendarReminderService | null = null) {
    this.store = store;
    this.reminderService = reminderService;
  }

  /* -------- 适配器辅助方法 -------- */

  private adapterForAccount(account: CalendarAccount): CalendarSourceAdapter {
    return CalendarSourceAdapterRegistry.getInstance().getAdapter(account);
  }

  private adapterForSource(source: CalendarSource, fallbackAccount?: CalendarAccount): CalendarSourceAdapter {
    return CalendarSourceAdapterRegistry.getInstance().getAdapterForSource(source, fallbackAccount);
  }

  /** 构造供 listEventsWithStatus 使用的临时 source 对象 */
  private tempSourceForAccount(account: CalendarAccount, collectionUrl: string): CalendarSource {
    return {
      id: "",
      accountId: account.id ?? "",
      name: account.displayName ?? "",
      description: "",
      collectionUrl,
      subscriptionUrl: "",
      principalUrl: "",
      homeSetUrl: "",
      scheduleInboxUrl: "",
      scheduleOutboxUrl: "",
      calendarUserAddressSet: "",
      ownerEmail: account.username,
      color: "#2563EB",
      backgroundColor: "#2563EB",
      borderColor: "#2563EB",
      textColor: "#FFFFFF",
      isVisible: true,
      isDefault: false,
      isReadOnly: false,
      sourceType: "caldav",
      freeBusyTransparent: false,
      displayOrder: 0,
      refreshIntervalMinutes: 15,
      refreshPolicy: "manualAndInterval",
      permissionsJson: "",
      sharePermissionsJson: "",
      shareUsersJson: "",
      shareGroupsJson: "",
      publicShareUrl: "",
      publicShareToken: "",
      supportedReportsJson: "",
      supportedComponentsJson: "",
      discoveryTraceJson: "",
      capabilitySource: "caldav",
      lastDiscoveryError: "",
      providerType: account.providerType ?? inferCalendarProviderType(account.serverUrl),
      providerPresetJson: account.providerPresetJson ?? "",
      syncStrategy: "",
      externalProviderId: "",
      nativeCalendarId: "",
      nativeCalendarSyncState: "",
      widgetConfigJson: "",
      providerAdapterType: "caldav",
      sourceLoadingState: "idle",
      lastLoadedRangeStart: 0,
      lastLoadedRangeEnd: 0,
      subscriptionEtag: "",
      subscriptionLastModified: "",
      ctag: "",
      syncToken: "",
      lastSuccessfulSyncAt: 0,
      lastSyncAt: 0,
      lastSyncHttpStatus: 0,
      retryAfterSeconds: 0,
      lastSyncDiagnosticJson: "",
      lastSyncError: ""
    };
  }

  async loadAccount(): Promise<CalendarAccount | null> {
    return this.store.loadAccount();
  }

  async saveAccount(account: CalendarAccount): Promise<void> {
    this.validateAccount(account);
    const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
    const serverUrl: string = normalizeServerUrl(normalizeProviderServerUrl(providerType, account.serverUrl, account.username));
    await this.store.saveAccount({
      id: account.id,
      displayName: account.displayName,
      providerType,
      providerPresetJson: this.standardProviderPresetJson(account.providerPresetJson ?? "", providerType, serverUrl),
	      serverUrl,
	      username: account.username.trim(),
	      password: account.password,
	      authType: account.authType,
	      bearerToken: account.bearerToken,
	      customHeadersJson: account.customHeadersJson,
	      isActive: account.isActive
	    });
  }

  async listAccounts(): Promise<CalendarAccount[]> {
    return this.store.listAccounts();
  }

  async saveCalDavAccount(account: CalendarAccount): Promise<CalendarAccount> {
    this.validateAccount(account);
    const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
    const serverUrl: string = normalizeServerUrl(normalizeProviderServerUrl(providerType, account.serverUrl, account.username));
    const saved: CalendarAccount = await this.store.saveCalDavAccount({
      id: account.id,
      displayName: account.displayName,
      providerType,
      providerPresetJson: this.standardProviderPresetJson(account.providerPresetJson ?? "", providerType, serverUrl),
	      serverUrl,
	      username: account.username.trim(),
	      password: account.password,
	      authType: account.authType,
	      bearerToken: account.bearerToken,
	      customHeadersJson: account.customHeadersJson,
	      isActive: account.isActive
	    });
    await this.refreshSourcesForAccount(saved);
    return saved;
  }

  async activateAccount(id: string): Promise<void> {
    await this.store.activateAccount(id);
  }

  async removeAccount(id: string): Promise<void> {
    await this.store.removeAccount(id);
  }

  async listSources(): Promise<CalendarSource[]> {
    return this.store.listSources();
  }

  async setDefaultSource(sourceId: string): Promise<void> {
    await this.store.setDefaultSource(sourceId);
  }

	  async updateSourceVisibility(sourceId: string, isVisible: boolean): Promise<void> {
	    await this.store.updateSourceVisibility(sourceId, isVisible);
	  }

  async updateSourceRefreshPolicy(sourceId: string, refreshIntervalMinutes: number, refreshPolicy: string): Promise<void> {
    await this.store.updateSourceRefreshPolicy(sourceId, refreshIntervalMinutes, refreshPolicy);
  }

  async updateSourceMetadata(sourceId: string, name: string, color: string): Promise<void> {
    await this.store.updateSourceMetadata(sourceId, name, color);
  }

  async updateRemoteSourceMetadata(sourceId: string, name: string, color: string): Promise<void> {
    const sources: CalendarSource[] = await this.store.listSources();
    const source: CalendarSource | undefined = sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
    if (source === undefined) {
      throw new Error("日历源不存在");
    }

    if (source.sourceType !== "caldav") {
      await this.store.updateSourceMetadata(sourceId, name, color);
      return;
    }

    const accounts: CalendarAccount[] = await this.store.listAccounts();
    const account: CalendarAccount | null = this.accountForSource(accounts, source);
    if (account === null) {
      throw new Error("日历源缺少关联 CalDAV 账号");
    }

    const remote: DiscoveredCalendarSource = await this.adapterForSource(source, account).updateSourceMetadata(source, name, color) as DiscoveredCalendarSource;
    await this.store.upsertSource({
      id: source.id ?? "",
      accountId: source.accountId,
      name: remote.name.length > 0 ? remote.name : name,
      description: remote.description.length > 0 ? remote.description : source.description ?? "",
      collectionUrl: source.collectionUrl,
      subscriptionUrl: source.subscriptionUrl ?? "",
      principalUrl: remote.principalUrl.length > 0 ? remote.principalUrl : source.principalUrl ?? "",
      homeSetUrl: remote.homeSetUrl.length > 0 ? remote.homeSetUrl : source.homeSetUrl ?? "",
      scheduleInboxUrl: source.scheduleInboxUrl ?? "",
      scheduleOutboxUrl: remote.scheduleOutboxUrl.length > 0 ? remote.scheduleOutboxUrl : source.scheduleOutboxUrl ?? "",
      calendarUserAddressSet: source.calendarUserAddressSet ?? "",
      ownerEmail: source.ownerEmail ?? "",
      color: remote.color.length > 0 ? remote.color : color,
      backgroundColor: remote.backgroundColor.length > 0 ? remote.backgroundColor : color,
      borderColor: remote.borderColor.length > 0 ? remote.borderColor : color,
      textColor: remote.textColor.length > 0 ? remote.textColor : source.textColor ?? "#FFFFFF",
      isVisible: source.isVisible,
      isDefault: source.isDefault,
      isReadOnly: source.isReadOnly,
      sourceType: source.sourceType,
      freeBusyTransparent: source.freeBusyTransparent ?? false,
      displayOrder: source.displayOrder ?? 0,
      refreshIntervalMinutes: source.refreshIntervalMinutes ?? 15,
      refreshPolicy: source.refreshPolicy ?? "manualAndInterval",
      permissionsJson: remote.permissionsJson.length > 0 ? remote.permissionsJson : source.permissionsJson ?? "",
      sharePermissionsJson: source.sharePermissionsJson ?? "",
      shareUsersJson: source.shareUsersJson ?? "",
      shareGroupsJson: source.shareGroupsJson ?? "",
      publicShareUrl: source.publicShareUrl ?? "",
      publicShareToken: source.publicShareToken ?? "",
      supportedReportsJson: remote.supportedReportsJson.length > 0 ? remote.supportedReportsJson : source.supportedReportsJson ?? "",
      supportedComponentsJson: remote.supportedComponentsJson.length > 0 ? remote.supportedComponentsJson : source.supportedComponentsJson ?? "",
      discoveryTraceJson: source.discoveryTraceJson ?? "",
      capabilitySource: remote.capabilitySource ?? source.capabilitySource ?? "",
      lastDiscoveryError: source.lastDiscoveryError ?? "",
      providerType: source.providerType ?? "",
      providerPresetJson: source.providerPresetJson ?? "",
      syncStrategy: source.syncStrategy ?? "full",
      externalProviderId: source.externalProviderId ?? "",
      nativeCalendarId: source.nativeCalendarId ?? "",
      ctag: remote.ctag.length > 0 ? remote.ctag : source.ctag ?? "",
      syncToken: remote.syncToken.length > 0 ? remote.syncToken : source.syncToken ?? ""
    });
  }

  async updateSourceSharePermissions(sourceId: string, sharePermissionsJson: string): Promise<void> {
    const sources: CalendarSource[] = await this.store.listSources();
    const source: CalendarSource | undefined = sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
    if (source === undefined || source.sourceType !== "caldav") {
      await this.store.updateSourceSharePermissions(sourceId, sharePermissionsJson);
      return;
    }

    const accounts: CalendarAccount[] = await this.store.listAccounts();
    const account: CalendarAccount | null = this.accountForSource(accounts, source);
    if (account === null) {
      await this.store.updateSourceSharePermissions(sourceId, this.shareJsonWithDiagnostic(sharePermissionsJson, "日历源缺少关联 CalDAV 账号"));
      return;
    }

    try {
      const members: ShareMember[] = this.parseShareMembers(sharePermissionsJson);
      const client = this.adapterForSource(source, account);
      for (const member of members) {
        await client.grantAccess(source, member.email, member.role);
      }
      await this.store.updateSourceSharePermissions(sourceId, this.shareJsonWithDiagnostic(sharePermissionsJson, "远端授权已提交"));
    } catch (error) {
      await this.store.updateSourceSharePermissions(sourceId, this.shareJsonWithDiagnostic(sharePermissionsJson, `远端授权失败：${this.describeError(error)}`));
    }
  }

  async loadViewConfig(): Promise<CalendarViewConfig> {
    return this.store.loadViewConfig();
  }

  async saveViewConfig(config: CalendarViewConfig): Promise<CalendarViewConfig> {
    return this.store.saveViewConfig(config);
  }

  async listDateMarkers(startAt: number, endAt: number): Promise<CalendarDateMarker[]> {
    return this.store.listDateMarkers(startAt, endAt);
  }

  async upsertDateMarker(marker: CalendarDateMarker): Promise<CalendarDateMarker> {
    return this.store.upsertDateMarker(marker);
  }

  async removeDateMarker(markerId: string): Promise<void> {
    await this.store.removeDateMarker(markerId);
  }

  async listResources(sourceId: string = ""): Promise<CalendarResource[]> {
    return this.store.listResources(sourceId);
  }

  async upsertResource(resource: CalendarResource): Promise<CalendarResource> {
    return this.store.upsertResource(resource);
  }

  async removeResource(resourceId: string): Promise<void> {
    await this.store.removeResource(resourceId);
  }

	  async saveSubscriptionSource(name: string, url: string, color: string = "#2563EB"): Promise<CalendarSource> {
	    const normalizedUrl: string = this.normalizeSubscriptionUrl(url);
	    if (!normalizedUrl.startsWith("http://") && !normalizedUrl.startsWith("https://")) {
	      throw new Error("订阅源需要 http、https 或 webcal 地址");
	    }

	    return this.store.upsertSource({
	      accountId: "",
	      name: name.trim().length > 0 ? name.trim() : "订阅日历",
	      description: "",
	      collectionUrl: normalizedUrl,
	      subscriptionUrl: normalizedUrl,
	      principalUrl: "",
	      homeSetUrl: "",
	      ownerEmail: "",
	      color,
	      backgroundColor: color,
	      borderColor: color,
	      textColor: "#FFFFFF",
	      isVisible: true,
	      isDefault: false,
	      isReadOnly: true,
		      sourceType: "subscription",
		      freeBusyTransparent: true,
		      displayOrder: 0,
		      refreshIntervalMinutes: 60,
		      refreshPolicy: "manualAndInterval",
		      permissionsJson: "read",
		      sharePermissionsJson: "",
		      shareUsersJson: "",
		      shareGroupsJson: "",
			      publicShareUrl: "",
			      publicShareToken: "",
			      supportedReportsJson: "",
			      supportedComponentsJson: "",
			      discoveryTraceJson: "",
			      capabilitySource: "ics-subscription",
			      lastDiscoveryError: "",
			      providerType: "webcal",
		      providerPresetJson: "",
		      syncStrategy: "",
		      externalProviderId: "",
		      nativeCalendarId: "",
		      nativeCalendarSyncState: "",
		      widgetConfigJson: "",
		      providerAdapterType: "subscription",
		      ctag: "",
		      syncToken: "",
		      lastSuccessfulSyncAt: 0,
		      lastSyncAt: 0,
		      lastSyncHttpStatus: 0,
		      retryAfterSeconds: 0,
		      lastSyncDiagnosticJson: "",
		      lastSyncError: ""
		    });
		  }

  async removeSource(sourceId: string): Promise<void> {
    await this.store.removeSource(sourceId);
  }

  async removeRemoteSource(sourceId: string): Promise<void> {
    const sources: CalendarSource[] = await this.store.listSources();
    const source: CalendarSource | undefined = sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
    if (source === undefined) {
      return;
    }

    if (source.sourceType !== "caldav") {
      await this.store.removeSource(sourceId);
      return;
    }

    const accounts: CalendarAccount[] = await this.store.listAccounts();
    const account: CalendarAccount | null = this.accountForSource(accounts, source);
    if (account === null) {
      throw new Error("日历源缺少关联 CalDAV 账号");
    }

    await this.adapterForSource(source, account).deleteSourceCollection(source);
    await this.store.removeSource(sourceId);
  }

  async createRemoteCalDavSource(accountId: string, name: string, color: string = "#2563EB"): Promise<CalendarSource> {
    const accounts: CalendarAccount[] = await this.store.listAccounts();
    const account: CalendarAccount | undefined = accounts.find((item: CalendarAccount) => (item.id ?? "") === accountId);
    if (account === undefined) {
      throw new Error("缺少可创建日历源的 CalDAV 账号");
    }

    const existing: CalendarSource[] = await this.store.listSourcesForAccount(accountId);
    const homeSetUrl: string = this.preferredHomeSetUrl(existing);
    const remote: DiscoveredCalendarSource = await this.adapterForAccount(account).createSourceCollection(account, homeSetUrl, name, color) as DiscoveredCalendarSource;
    const saved: CalendarSource = await this.store.upsertSource({
      accountId,
      name: remote.name,
      description: remote.description,
      collectionUrl: remote.collectionUrl,
      subscriptionUrl: "",
      principalUrl: remote.principalUrl,
      homeSetUrl: remote.homeSetUrl.length > 0 ? remote.homeSetUrl : homeSetUrl,
      scheduleInboxUrl: remote.scheduleInboxUrl,
      scheduleOutboxUrl: remote.scheduleOutboxUrl,
      calendarUserAddressSet: remote.calendarUserAddressSet,
      ownerEmail: remote.ownerEmail.length > 0 ? remote.ownerEmail : account.username,
      color: remote.color.length > 0 ? remote.color : color,
      backgroundColor: remote.backgroundColor.length > 0 ? remote.backgroundColor : color,
      borderColor: remote.borderColor.length > 0 ? remote.borderColor : color,
      textColor: remote.textColor.length > 0 ? remote.textColor : "#FFFFFF",
      isVisible: true,
      isDefault: existing.length === 0,
      isReadOnly: remote.isReadOnly,
      sourceType: "caldav",
      freeBusyTransparent: false,
      displayOrder: existing.length,
      refreshIntervalMinutes: 15,
      refreshPolicy: "manualAndInterval",
      permissionsJson: remote.permissionsJson,
      sharePermissionsJson: "",
      shareUsersJson: "",
      shareGroupsJson: "",
      publicShareUrl: "",
      publicShareToken: "",
      supportedReportsJson: remote.supportedReportsJson,
      supportedComponentsJson: remote.supportedComponentsJson,
      discoveryTraceJson: "",
      capabilitySource: remote.capabilitySource,
      lastDiscoveryError: "",
      providerType: account.providerType ?? inferCalendarProviderType(account.serverUrl),
      providerPresetJson: account.providerPresetJson ?? "",
      syncStrategy: "",
      externalProviderId: "",
      nativeCalendarId: "",
      nativeCalendarSyncState: "",
      widgetConfigJson: "",
      providerAdapterType: "caldav",
	      ctag: remote.ctag,
	      syncToken: remote.syncToken,
	      lastSuccessfulSyncAt: 0,
	      lastSyncAt: 0,
	      lastSyncHttpStatus: 0,
	      retryAfterSeconds: 0,
	      lastSyncDiagnosticJson: "",
	      lastSyncError: ""
	    });
    return saved;
  }

  async refreshSource(sourceId: string): Promise<CalendarSyncResult> {
    const sources: CalendarSource[] = await this.store.listSources();
    const source: CalendarSource | undefined = sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
    if (source === undefined) {
      throw new Error("日历源不存在");
    }

    if (source.sourceType === "subscription") {
      return this.refreshSubscriptionSource(source);
    }

    if (source.sourceType === "caldav") {
      return this.syncCalDavSource(source);
    }

    return { pulled: 0, pushed: 0, deleted: 0, failed: 0 };
  }

  async resolveConflictUseLocal(event: CalendarEvent): Promise<void> {
    await this.store.resolveConflictUseLocal(event);
    await this.syncLocalReminder(event);
  }

  async resolveConflictUseRemote(event: CalendarEvent): Promise<void> {
    await this.store.resolveConflictUseRemote(event);
    const resolved: CalendarEvent | null = await this.store.findEventById(event.id);
    if (resolved !== null) {
      await this.syncLocalReminder(resolved);
    }
  }

	  async importIcs(ics: string, sourceId: string = ""): Promise<number> {
	    const events: CalendarEvent[] = parseIcsEvents(ics, "import://manual", "");
	    let imported: number = 0;
	    for (const event of events) {
	      await this.store.upsertRemoteEvent(event, sourceId);
	      imported += 1;
	    }

	    return imported;
	  }

	  async exportIcs(): Promise<string> {
	    return buildIcsCalendar(await this.listEvents());
	  }

  async listEvents(): Promise<CalendarEvent[]> {
    const events: CalendarEvent[] = (await this.store.listEvents(true))
      .filter((event: CalendarEvent) => event.syncStatus !== "deleted" || (event.conflictStatus ?? "none") !== "none");
    const sources: CalendarSource[] = await this.store.listSources();
    if (sources.length === 0) {
      return events;
    }

    const visibleSources: string[] = sources
      .filter((source: CalendarSource) => source.isVisible)
      .map((source: CalendarSource) => source.id ?? "");
    return events.filter((event: CalendarEvent) => event.sourceId.length === 0 || visibleSources.indexOf(event.sourceId) >= 0);
  }

  async queryFreeBusy(startAt: number, endAt: number, sourceIds: string[] = []): Promise<CalendarFreeBusyResult[]> {
    const accounts: CalendarAccount[] = await this.store.listAccounts();
    const sources: CalendarSource[] = await this.store.listSources();
    const targets: CalendarSource[] = sources.filter((source: CalendarSource) =>
      source.sourceType === "caldav" &&
        source.isVisible &&
        source.freeBusyTransparent !== true &&
        (sourceIds.length === 0 || sourceIds.indexOf(source.id ?? "") >= 0));
    const results: CalendarFreeBusyResult[] = [];

    for (const source of targets) {
      const sourceId: string = source.id ?? "";
      const account: CalendarAccount | null = this.accountForSource(accounts, source);
      if (account === null) {
        results.push({
          sourceId,
          ownerEmail: source.ownerEmail ?? "",
          slots: [],
          failed: true,
          error: "日历源缺少关联 CalDAV 账号"
        });
        continue;
      }

	      try {
	        const slots: CalendarFreeBusySlot[] = await this.adapterForSource(source, account)
	          .queryFreeBusy(source, startAt, endAt);
        results.push({
          sourceId,
          ownerEmail: source.ownerEmail ?? account.username,
          slots,
          failed: false
        });
      } catch (error) {
        results.push({
          sourceId,
          ownerEmail: source.ownerEmail ?? account.username,
          slots: [],
          failed: true,
          error: this.describeError(error)
        });
      }
    }

    return results;
  }

  async testConnection(account: CalendarAccount): Promise<CalendarConnectionTestResult> {
    this.validateAccount(account);
	    const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
	    const serverUrl: string = normalizeServerUrl(normalizeProviderServerUrl(providerType, account.serverUrl, account.username));
	    const preset = providerPresetFor(providerType);
	    const adapter: CalendarSourceAdapter = this.adapterForAccount({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount);
	    const discoveryTrace: CalDavDiscoveryTrace = await adapter.traceDiscovery({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount) as CalDavDiscoveryTrace;
	    let discoveredSources: DiscoveredCalendarSource[] = [];
	    let discoveryError: string = "";
	    try {
	      discoveredSources = await adapter.discoverSources({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount);
	    } catch (error) {
	      discoveryError = this.describeError(error);
	    }
    const collectionUrl: string = discoveredSources.length > 0 ? discoveredSources[0].collectionUrl : (await adapter.discoverSources({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount)).filter(s => s.collectionUrl.length > 0).map(s => s.collectionUrl)[0] ?? "";
    const tempSource: CalendarSource = this.tempSourceForAccount({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount, collectionUrl);
	    const adapterResult: AdapterListResult = await this.adapterForAccount({ serverUrl, username: account.username.trim(), password: account.password, authType: account.authType, bearerToken: account.bearerToken, customHeadersJson: account.customHeadersJson, displayName: account.displayName, providerType, providerPresetJson: account.providerPresetJson } as CalendarAccount).listEventsWithStatus(tempSource);
	    const result: RemoteCalendarListResult = { events: adapterResult.events.map((event: CalendarEvent): RemoteCalendarEvent => ({
  uid: event.uid,
  href: event.href,
  etag: event.etag ?? "",
  ics: ""
})), failed: adapterResult.failed, total: adapterResult.total, deletedHrefs: adapterResult.deletedHrefs, syncToken: adapterResult.syncToken, incremental: adapterResult.incremental, strategy: adapterResult.strategy ?? "full-sync", httpStatus: adapterResult.httpStatus, retryAfterSeconds: adapterResult.retryAfterSeconds, diagnosticJson: adapterResult.diagnosticJson };
	    const firstSource: DiscoveredCalendarSource | undefined = discoveredSources.length > 0 ? discoveredSources[0] : undefined;
    return {
      providerType,
      normalizedServerUrl: serverUrl,
      collectionUrl,
      authHint: preset.authHint,
      discoveryHint: preset.discoveryHint,
      capabilities: this.connectionCapabilities(firstSource),
      diagnosticHint: `${providerDiagnosticHint(providerType, discoveryError)} ${providerDiscoveryChecklist(providerType, serverUrl, account.username)}`,
      discoveryTrace: this.formatDiscoveryTrace(discoveryTrace),
      diagnosticJson: this.connectionDiagnosticJson(providerType, serverUrl, discoveryTrace, discoveredSources, result, discoveryError),
      syncStrategy: result.strategy ?? "",
      sources: discoveredSources.length,
      total: result.total,
      parsed: result.events.length,
      failed: result.failed
    };
  }

  private connectionCapabilities(source: DiscoveredCalendarSource | undefined): string {
    if (source === undefined) {
      return "未发现服务端能力，已尝试直接 collection 读取";
    }

    const parts: string[] = [];
    const reports: string[] = this.parseReportList(source.supportedReportsJson);
    const components: string[] = this.parseComponentList(source.supportedComponentsJson);
    if (reports.indexOf("sync-collection") >= 0) {
      parts.push("增量同步");
    }
    if (reports.indexOf("free-busy-query") >= 0 || source.scheduleOutboxUrl.length > 0) {
      parts.push("忙闲");
    }
    if (components.indexOf("VEVENT") >= 0 || components.length === 0) {
      parts.push("事件");
    }
    if (components.indexOf("VTODO") >= 0) {
      parts.push("任务");
    }
    if (source.isReadOnly) {
      parts.push("只读");
    } else if (this.hasDavPrivilege((source.permissionsJson ?? "").toLowerCase(), "write") ||
      this.hasDavPrivilege((source.permissionsJson ?? "").toLowerCase(), "bind")) {
      parts.push("可写");
    }
    return parts.length > 0 ? parts.join(" · ") : "基础 CalDAV";
  }

  private formatDiscoveryTrace(trace: CalDavDiscoveryTrace): string {
    const direct: string = trace.directCollectionMatched ? `direct=${trace.directCollectionUrl}` : "direct=未命中";
    const options: string = trace.optionsError.length > 0 ?
      `options=${trace.optionsUrl} 错误 ${trace.optionsError}` :
      `options=${trace.optionsUrl} DAV=${trace.davHeader.length > 0 ? trace.davHeader : "无"} Allow=${trace.allowHeader.length > 0 ? trace.allowHeader : "无"}`;
    const roots: string = trace.roots.length > 0 ? `roots=${trace.roots.join(" | ")}` : "roots=无";
    const principals: string = trace.principalUrls.length > 0 ? `principals=${trace.principalUrls.join(" | ")}` : "principals=无";
    const homes: string = trace.homeSetUrls.length > 0 ? `homes=${trace.homeSetUrls.join(" | ")}` : "homes=无";
    const sources: string = trace.sourceUrls.length > 0 ? `sources=${trace.sourceUrls.join(" | ")}` : "sources=无";
    const errors: string = trace.errors.length > 0 ? `errors=${trace.errors.slice(0, 3).join(" | ")}` : "errors=无";
    return `${direct}; ${options}; ${roots}; ${principals}; ${homes}; ${sources}; ${errors}`;
  }

  private connectionDiagnosticJson(
    providerType: string,
    serverUrl: string,
    trace: CalDavDiscoveryTrace,
    sources: DiscoveredCalendarSource[],
    result: RemoteCalendarListResult,
    discoveryError: string
  ): string {
    const diagOptions: Object = JSON.parse(JSON.stringify({
      url: trace.optionsUrl,
      dav: trace.davHeader,
      allow: trace.allowHeader,
      error: trace.optionsError
    }));
    const diagCaps: Object = sources.length > 0 ? JSON.parse(JSON.stringify({
      reports: this.parseReportList(sources[0].supportedReportsJson),
      components: this.parseComponentList(sources[0].supportedComponentsJson),
      readOnly: sources[0].isReadOnly
    })) : JSON.parse("{}");
    return JSON.stringify(JSON.parse(JSON.stringify({
      providerType,
      normalizedServerUrl: serverUrl,
      directCollectionMatched: trace.directCollectionMatched,
      options: diagOptions,
      rootsTried: trace.roots,
      principalUrls: trace.principalUrls,
      homeSetUrls: trace.homeSetUrls,
      sourceUrls: trace.sourceUrls,
      discoveryErrors: trace.errors,
      discoveryError,
      discoveredSources: sources.length,
      firstCollectionUrl: sources.length > 0 ? sources[0].collectionUrl : "",
      capabilities: diagCaps,
      objectTotal: result.total,
      parsedEvents: result.events.length,
      failedObjects: result.failed,
      syncStrategy: result.strategy ?? "",
      checkedAt: Date.now()
    })));
  }

  private sourceDiscoveryTraceJson(
    account: CalendarAccount,
    discovered: DiscoveredCalendarSource[],
    discoveryError: string
  ): string {
    return JSON.stringify({
      providerType: account.providerType ?? inferCalendarProviderType(account.serverUrl),
      normalizedServerUrl: normalizeServerUrl(account.serverUrl),
      discoveredSources: discovered.length,
      sourceUrls: discovered.map((source: DiscoveredCalendarSource) => source.collectionUrl),
      principalUrls: discovered.map((source: DiscoveredCalendarSource) => source.principalUrl).filter((value: string) => value.length > 0),
      homeSetUrls: discovered.map((source: DiscoveredCalendarSource) => source.homeSetUrl).filter((value: string) => value.length > 0),
      discoveryError,
      checkedAt: Date.now()
    });
  }

  private standardProviderPresetJson(existing: string, providerType: string, serverUrl: string): string {
    if (existing.trim().length > 0) {
      try {
        const parsed = JSON.parse(existing) as object;
        parsed["providerType"] = providerType;
        parsed["serverUrl"] = serverUrl;
        parsed["standardDiscovery"] = {
          currentUserPrincipal: true,
          calendarHomeSet: true,
          directCollection: true,
          fallbackGuessPaths: true
        };
        return JSON.stringify(parsed);
      } catch {
        return buildProviderPresetJson(providerType, serverUrl);
      }
    }

    return buildProviderPresetJson(providerType, serverUrl);
  }

  private parseReportList(value: string): string[] {
    return this.parseJsonStringList(value, false);
  }

  private parseComponentList(value: string): string[] {
    return this.parseJsonStringList(value, true);
  }

  private parseJsonStringList(value: string, uppercase: boolean): string[] {
    if (value.trim().length === 0) {
      return [];
    }
    const normalize = (item: string): string => uppercase ? `${item}`.toUpperCase() : `${item}`.toLowerCase();
    try {
      const parsed = JSON.parse(value) as string[];
      return Array.isArray(parsed) ? parsed.map((item: string) => normalize(item)) : [];
    } catch {
      return value.split(/[,\n;]/).map((item: string) => normalize(item.trim())).filter((item: string) => item.length > 0);
    }
  }

  private parseShareMembers(value: string): ShareMember[] {
    if (value.trim().length === 0) {
      return [];
    }

    try {
      const parsed = JSON.parse(value) as ShareMember[];
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed
        .filter((item: ShareMember) => item.email !== undefined && item.email.trim().length > 0)
        .map((item: ShareMember) => {
          return {
            email: item.email.trim(),
            role: item.role === "write" ? "write" : "read",
            addedAt: item.addedAt ?? Date.now(),
            diagnostic: item.diagnostic ?? ""
          } as ShareMember;
        });
    } catch {
      return [];
    }
  }

  private shareJsonWithDiagnostic(value: string, diagnostic: string): string {
    const members: ShareMember[] = this.parseShareMembers(value);
    return JSON.stringify(members.map((member: ShareMember) => {
      return {
        email: member.email,
        role: member.role,
        addedAt: member.addedAt,
        diagnostic
      } as ShareMember;
    }));
  }

  async createEvent(draft: CalendarEventDraft): Promise<CalendarEvent> {
    await this.ensureDraftComponentSupported(draft);
    await this.ensureDraftCanCreate(draft);
    const event: CalendarEvent = await this.store.createDraft(draft);
    await this.syncLocalReminder(event);
    return event;
  }

	  async updateEvent(event: CalendarEvent, draft: CalendarEventDraft): Promise<CalendarEvent> {
    await this.ensureDraftComponentSupported(draft);
    await this.ensureEventCanUpdate(event);
	    const updated: CalendarEvent = await this.store.updateLocalEvent(event, draft);
	    await this.syncLocalReminder(updated);
	    return updated;
	  }

	  async saveLocalEvent(event: CalendarEvent): Promise<void> {
	    await this.store.saveLocalEvent(event);
	    await this.syncLocalReminder(event);
	  }

  async deleteEvent(event: CalendarEvent): Promise<void> {
    await this.ensureEventCanDelete(event);
    await this.cancelLocalReminder(event);
    await this.store.markDeleted(event);
  }

  async sync(): Promise<CalendarSyncResult> {
    const accounts: CalendarAccount[] = await this.store.listAccounts();
    if (accounts.length === 0) {
      throw new Error("请先配置 CalDAV 地址和账号");
    }

    let pushed: number = 0;
    let deleted: number = 0;
    let failed: number = 0;
    let pulled: number = 0;

    for (const account of accounts) {
      try {
        this.validateAccount(account);
        await this.refreshSourcesForAccount(account);
      } catch (error) {
        failed += 1;
        console.error(`Refresh CalDAV sources failed: account=${account.id ?? account.serverUrl}, reason=${this.describeError(error)}`);
      }
    }

	    const sources: CalendarSource[] = await this.store.listSources();
	    for (const source of sources) {
	      if (source.sourceType === "subscription" && source.isVisible) {
	        if (!this.shouldRefreshSource(source, Date.now())) {
	          continue;
	        }

	        try {
	          await this.store.markSourceLoading(source.id ?? "", "loading");
	          const result: SubscriptionFetchResult = await new CalendarSubscriptionClient().fetch(
	            source.subscriptionUrl ?? source.collectionUrl,
	            source.subscriptionEtag ?? "",
	            source.subscriptionLastModified ?? ""
	          );
	          const remoteIds: string[] = [];
		          const sourceId: string = source.id ?? "";
		          if (result.notModified === true) {
		            await this.store.saveSubscriptionSyncState(
		              sourceId,
		              result.etag,
		              result.lastModified,
		              "",
		              result.httpStatus ?? 0,
		              result.retryAfterSeconds ?? 0,
		              result.diagnosticJson ?? ""
		            );
		            continue;
		          }
	          for (const event of result.events) {
            await this.store.upsertRemoteEvent(event, sourceId);
            remoteIds.push(event.id);
            pulled += 1;
          }
          deleted += await this.store.removeCleanEventsMissingFromRemote(remoteIds, sourceId);
	          await this.store.saveSubscriptionSyncState(
	            sourceId,
	            result.etag,
	            result.lastModified,
	            "",
	            result.httpStatus ?? 0,
	            result.retryAfterSeconds ?? 0,
	            result.diagnosticJson ?? ""
	          );
	        } catch (error) {
	          failed += 1;
	          await this.store.saveSubscriptionSyncState(
	            source.id ?? "",
	            source.subscriptionEtag ?? "",
	            source.subscriptionLastModified ?? "",
	            this.describeError(error),
	            this.httpStatusFromError(error),
	            this.retryAfterFromError(error),
	            this.diagnosticJsonFromError(error, "ics-subscription")
	          );
	          console.error(`Pull subscription failed: source=${source.id ?? source.collectionUrl}, reason=${this.describeError(error)}`);
	        }
        continue;
      }

      if (source.sourceType !== "caldav" || !source.isVisible) {
        continue;
      }
	      const account: CalendarAccount | null = this.accountForSource(accounts, source);
	      if (account === null) {
	        failed += 1;
	        await this.store.saveSourceSyncState(
	          source.id ?? "",
	          source.syncToken ?? "",
	          source.ctag ?? "",
	          "日历源缺少关联 CalDAV 账号",
	          source.syncStrategy ?? "",
	          0,
	          0,
	          this.sourceDiagnosticJson(source, "missing-account", "日历源缺少关联 CalDAV 账号")
	        );
	        continue;
	      }

	      const adapter = this.adapterForSource(source, account);
	      const sourceId: string = source.id ?? "";
	      const shouldPullRemote: boolean = this.shouldRefreshSource(source, Date.now());

      const dirtyEvents: CalendarEvent[] = await this.store.listDirtyEvents(sourceId);
      let skippedByPermission: number = 0;
      for (const event of dirtyEvents) {
        if (!this.canPushEventToSource(source, event)) {
          skippedByPermission += 1;
          continue;
        }
        const ok: boolean = await this.pushDirtyEvent(adapter, source, event, sourceId);
        pushed += ok ? 1 : 0;
        failed += ok ? 0 : 1;
      }

      const deletedEventsForPush: CalendarEvent[] = await this.store.listDeletedEvents(sourceId);
      if (this.canDeleteFromSource(source)) {
        const deletedEvents: CalendarEvent[] = deletedEventsForPush;
        for (const event of deletedEvents) {
          const ok: boolean = await this.pushDeletedEvent(adapter, source, event, sourceId);
          deleted += ok ? 1 : 0;
          failed += ok ? 0 : 1;
        }
      } else {
        skippedByPermission += deletedEventsForPush.length;
      }

	      if (!shouldPullRemote) {
	        continue;
	      }

	      const remoteIds: string[] = [];
      const protectedLocalIds: string[] = this.localPendingIds(
        await this.store.listDirtyEvents(sourceId),
        await this.store.listDeletedEvents(sourceId)
      );
      protectedLocalIds.forEach((id: string) => {
        if (remoteIds.indexOf(id) < 0) {
          remoteIds.push(id);
        }
      });

	      try {
	        await this.store.markSourceLoading(sourceId, "loading");
const remoteResult: AdapterListResult = await this.pullRemoteChanges(adapter, source);
        for (const remote of remoteResult.events) {
          try {
            await this.store.upsertRemoteEvent(remote, sourceId);
            await this.syncLocalReminder(this.eventWithSource(remote, sourceId));
            if (remoteIds.indexOf(remote.id) < 0) {
              remoteIds.push(remote.id);
            }
            pulled += 1;
          } catch (error) {
            failed += 1;
            console.error(`Upsert remote event failed: id=${remote.id}, uid=${remote.uid}, href=${remote.href}, source=${sourceId}, reason=${this.describeError(error)}`);
          }
        }

        if (remoteResult.failed > 0) {
          failed += remoteResult.failed;
          await this.store.saveSourceSyncState(
            sourceId,
            source.syncToken ?? "",
	            source.ctag ?? "",
	            this.pullErrorSummary(remoteResult),
	            remoteResult.strategy ?? source.syncStrategy ?? "",
	            remoteResult.httpStatus ?? 0,
	            remoteResult.retryAfterSeconds ?? 0,
	            remoteResult.diagnosticJson ?? ""
	          );
          console.error(`Pull events partially failed: source=${sourceId}, failed=${remoteResult.failed}, total=${remoteResult.total}; skipped cleanup`);
        } else {
          if (remoteResult.incremental === true) {
            deleted += await this.removeDeletedRemoteHrefs(remoteResult.deletedHrefs ?? [], sourceId);
          } else {
            deleted += await this.store.removeCleanEventsMissingFromRemote(remoteIds, sourceId);
          }
          await this.store.saveSourceSyncState(
            sourceId,
	            remoteResult.syncToken ?? source.syncToken ?? "",
	            source.ctag ?? "",
	            skippedByPermission > 0 ? `跳过 ${skippedByPermission} 个无权限推送项` : "",
	            remoteResult.strategy ?? source.syncStrategy ?? "",
	            remoteResult.httpStatus ?? 0,
	            remoteResult.retryAfterSeconds ?? 0,
	            remoteResult.diagnosticJson ?? ""
	          );
	        }
	      } catch (error) {
	        failed += 1;
	        await this.store.saveSourceSyncState(
	          sourceId,
	          source.syncToken ?? "",
	          source.ctag ?? "",
	          this.describeError(error),
	          source.syncStrategy ?? "",
	          this.httpStatusFromError(error),
	          this.retryAfterFromError(error),
	          this.diagnosticJsonFromError(error, "caldav")
	        );
	        console.error(`Pull events failed: source=${sourceId}, reason=${this.describeError(error)}; skipped cleanup`);
	      }
    }

	    return {
      pulled,
      pushed,
      deleted,
      failed
    };
	  }

	  private async pullRemoteChanges(adapter: CalendarSourceAdapter, source: CalendarSource): Promise<AdapterListResult> {
	    const token: string = source.syncToken ?? "";
	    if (token.length === 0) {
	      return adapter.listEventsWithStatus(source);
	    }

	    try {
	      return await adapter.listEventsIncremental(source, token);
	    } catch (error) {
	      if (!this.shouldFallbackFullSync(error)) {
	        throw error instanceof Error ? error : new Error(String(error));
	      }
	      console.error(`CalDAV incremental sync-token invalid, fallback to full pull: source=${source.id ?? source.collectionUrl}, reason=${this.describeError(error)}`);
	      const full: AdapterListResult = await adapter.listEventsWithStatus(source);
	      return {
	        events: full.events,
	        icsList: full.icsList,
	        failed: full.failed,
	        total: full.total,
	        deletedHrefs: full.deletedHrefs,
	        syncToken: full.syncToken ?? "",
	        incremental: false,
	        httpStatus: full.httpStatus,
	        retryAfterSeconds: full.retryAfterSeconds,
	        diagnosticJson: full.diagnosticJson,
	        strategy: `sync-collection-token-reset+${full.strategy ?? "full"}`
	      } as AdapterListResult;
	    }
	  }

  private pullErrorSummary(result: AdapterListResult): string {
    const strategy: string = (result.strategy ?? "").length > 0 ? `，策略 ${result.strategy ?? ""}` : "";
    return `拉取失败 ${result.failed}/${result.total}${strategy}`;
  }

  private shouldFallbackFullSync(error: Error | string): boolean {
    if (error instanceof CalDavHttpError) {
      return error.status === 400 || error.status === 403 || error.status === 404 || error.status === 409;
    }

    const reason: string = this.describeError(error).toLowerCase();
    return reason.indexOf("sync-token") >= 0 ||
      reason.indexOf("valid-sync-token") >= 0 ||
      reason.indexOf("invalid-sync-token") >= 0 ||
      reason.indexOf("返回 400") >= 0 ||
      reason.indexOf("返回 403") >= 0 ||
      reason.indexOf("返回 404") >= 0 ||
      reason.indexOf("返回 409") >= 0;
  }

  private async refreshSubscriptionSource(source: CalendarSource): Promise<CalendarSyncResult> {
    let pulled: number = 0;
    let deleted: number = 0;
    const sourceId: string = source.id ?? "";
    try {
      await this.store.markSourceLoading(sourceId, "loading");
      const result: SubscriptionFetchResult = await new CalendarSubscriptionClient().fetch(
        source.subscriptionUrl ?? source.collectionUrl,
        source.subscriptionEtag ?? "",
        source.subscriptionLastModified ?? ""
      );
	      const remoteIds: string[] = [];
	      if (result.notModified === true) {
	        await this.store.saveSubscriptionSyncState(
	          sourceId,
	          result.etag,
	          result.lastModified,
	          "",
	          result.httpStatus ?? 0,
	          result.retryAfterSeconds ?? 0,
	          result.diagnosticJson ?? ""
	        );
	        return { pulled: 0, pushed: 0, deleted: 0, failed: 0 };
	      }
      for (const event of result.events) {
        await this.store.upsertRemoteEvent(event, sourceId);
        remoteIds.push(event.id);
        pulled += 1;
	      }
	      deleted = await this.store.removeCleanEventsMissingFromRemote(remoteIds, sourceId);
	      await this.store.saveSubscriptionSyncState(
	        sourceId,
	        result.etag,
	        result.lastModified,
	        "",
	        result.httpStatus ?? 0,
	        result.retryAfterSeconds ?? 0,
	        result.diagnosticJson ?? ""
	      );
	      return { pulled, pushed: 0, deleted, failed: 0 };
	    } catch (error) {
	      await this.store.saveSubscriptionSyncState(
	        sourceId,
	        source.subscriptionEtag ?? "",
	        source.subscriptionLastModified ?? "",
	        this.describeError(error),
	        this.httpStatusFromError(error),
	        this.retryAfterFromError(error),
	        this.diagnosticJsonFromError(error, "ics-subscription")
	      );
	      return { pulled, pushed: 0, deleted, failed: 1 };
	    }
	  }

  private async syncCalDavSource(source: CalendarSource): Promise<CalendarSyncResult> {
    const accounts: CalendarAccount[] = await this.store.listAccounts();
	    const account: CalendarAccount | null = this.accountForSource(accounts, source);
	    if (account === null) {
	      await this.store.saveSourceSyncState(
	        source.id ?? "",
	        source.syncToken ?? "",
	        source.ctag ?? "",
	        "日历源缺少关联 CalDAV 账号",
	        source.syncStrategy ?? "",
	        0,
	        0,
	        this.sourceDiagnosticJson(source, "missing-account", "日历源缺少关联 CalDAV 账号")
	      );
	      throw new Error("日历源缺少关联 CalDAV 账号");
	    }

    const adapter = this.adapterForSource(source, account);
    const sourceId: string = source.id ?? "";
    let pulled: number = 0;
    let pushed: number = 0;
    let deleted: number = 0;
    let failed: number = 0;
    await this.store.markSourceLoading(sourceId, "loading");

    const dirtyEvents: CalendarEvent[] = await this.store.listDirtyEvents(sourceId);
    let skippedByPermission: number = 0;
    for (const event of dirtyEvents) {
      if (!this.canPushEventToSource(source, event)) {
        skippedByPermission += 1;
        continue;
      }
      const ok: boolean = await this.pushDirtyEvent(adapter, source, event, sourceId);
      pushed += ok ? 1 : 0;
      failed += ok ? 0 : 1;
    }

    const deletedEventsForPush: CalendarEvent[] = await this.store.listDeletedEvents(sourceId);
    if (this.canDeleteFromSource(source)) {
      const deletedEvents: CalendarEvent[] = deletedEventsForPush;
      for (const event of deletedEvents) {
        const ok: boolean = await this.pushDeletedEvent(adapter, source, event, sourceId);
        deleted += ok ? 1 : 0;
        failed += ok ? 0 : 1;
      }
    } else {
      skippedByPermission += deletedEventsForPush.length;
    }

    try {
const remoteResult: AdapterListResult = await this.pullRemoteChanges(adapter, source);
      const remoteIds: string[] = this.localPendingIds(
        await this.store.listDirtyEvents(sourceId),
        await this.store.listDeletedEvents(sourceId)
      );

      for (const remote of remoteResult.events) {
        await this.store.upsertRemoteEvent(remote, sourceId);
        await this.syncLocalReminder(this.eventWithSource(remote, sourceId));
        if (remoteIds.indexOf(remote.id) < 0) {
          remoteIds.push(remote.id);
        }
        pulled += 1;
      }

      if (remoteResult.failed > 0) {
        failed += remoteResult.failed;
	        await this.store.saveSourceSyncState(
	          sourceId,
	          source.syncToken ?? "",
	          source.ctag ?? "",
	          this.pullErrorSummary(remoteResult),
	          remoteResult.strategy ?? source.syncStrategy ?? "",
	          remoteResult.httpStatus ?? 0,
	          remoteResult.retryAfterSeconds ?? 0,
	          remoteResult.diagnosticJson ?? ""
	        );
      } else {
        if (remoteResult.incremental === true) {
          deleted += await this.removeDeletedRemoteHrefs(remoteResult.deletedHrefs ?? [], sourceId);
        } else {
          deleted += await this.store.removeCleanEventsMissingFromRemote(remoteIds, sourceId);
        }
	        await this.store.saveSourceSyncState(
	          sourceId,
	          remoteResult.syncToken ?? source.syncToken ?? "",
	          source.ctag ?? "",
	          skippedByPermission > 0 ? `跳过 ${skippedByPermission} 个无权限推送项` : "",
	          remoteResult.strategy ?? source.syncStrategy ?? "",
	          remoteResult.httpStatus ?? 0,
	          remoteResult.retryAfterSeconds ?? 0,
	          remoteResult.diagnosticJson ?? ""
	        );
	      }
	    } catch (error) {
	      failed += 1;
	      await this.store.saveSourceSyncState(
	        sourceId,
	        source.syncToken ?? "",
	        source.ctag ?? "",
	        this.describeError(error),
	        source.syncStrategy ?? "",
	        this.httpStatusFromError(error),
	        this.retryAfterFromError(error),
	        this.diagnosticJsonFromError(error, "caldav")
	      );
	    }

    return { pulled, pushed, deleted, failed };
  }

	  private async removeDeletedRemoteHrefs(hrefs: string[], sourceId: string): Promise<number> {
	    if (hrefs.length === 0) {
	      return 0;
	    }

	    const events: CalendarEvent[] = await this.store.listEvents(false);
	    let removed: number = 0;
	    for (const href of hrefs) {
	      const found: CalendarEvent | undefined = events.find((event: CalendarEvent) =>
	        event.sourceId === sourceId && event.href === href && event.syncStatus === "clean");
	      if (found !== undefined) {
	        await this.store.removeEvent(found.id);
	        removed += 1;
	      }
	    }

	    return removed;
	  }

  private async pushDirtyEvent(adapter: CalendarSourceAdapter, source: CalendarSource, event: CalendarEvent, sourceId: string): Promise<boolean> {
    try {
      const uploaded = await adapter.updateEvent(source, event);
      await this.store.saveSyncedEvent(event, uploaded.href, uploaded.etag);
      return true;
    } catch (error) {
      const reason: string = this.describeError(error);
      await this.recordPushConflictIfNeeded(adapter, source, event, sourceId, reason);
      console.error(`Push event failed: id=${event.id}, uid=${event.uid}, title=${event.title}, source=${sourceId}, reason=${reason}`);
      return false;
    }
  }

  private async pushDeletedEvent(adapter: CalendarSourceAdapter, source: CalendarSource, event: CalendarEvent, sourceId: string): Promise<boolean> {
    try {
      await adapter.deleteEvent(source, event);
      await this.store.removeEvent(event.id);
      return true;
    } catch (error) {
      const reason: string = this.describeError(error);
      await this.recordPushConflictIfNeeded(adapter, source, event, sourceId, reason);
      console.error(`Delete event failed: id=${event.id}, uid=${event.uid}, href=${event.href}, source=${sourceId}, reason=${reason}`);
      return false;
    }
  }

  private async recordPushConflictIfNeeded(
    adapter: CalendarSourceAdapter,
    source: CalendarSource,
    event: CalendarEvent,
    sourceId: string,
    reason: string
  ): Promise<void> {
    if (!this.isCalDavConflictError(reason)) {
      return;
    }

    const remote: CalendarEvent | null = await adapter.getCurrentEvent(source, event);
    if (remote === null) {
      await this.store.markConflict(event, this.conflictDiagnosticEvent(event, sourceId, reason), "localDirtyRemoteChanged");
      return;
    }

    await this.store.markConflict(event, this.eventWithSource(remote, sourceId), "localDirtyRemoteChanged");
  }

  private conflictDiagnosticEvent(event: CalendarEvent, sourceId: string, reason: string): CalendarEvent {
    const diagnosticRaw: string = JSON.stringify({
      caldavPushConflict: true,
      detectedAt: Date.now(),
      reason
    });
    return {
      id: event.id,
      uid: event.uid,
      href: event.href,
      etag: event.etag,
      sourceId: sourceId,
      title: event.title,
      startAt: event.startAt,
      endAt: event.endAt,
      allDay: event.allDay,
      location: event.location,
      notes: event.notes,
      eventSourceId: event.eventSourceId ?? "",
      reminderMinutes: event.reminderMinutes ?? 0,
      secondReminderMinutes: event.secondReminderMinutes ?? 0,
      syncStatus: "clean",
      lastModified: Date.now(),
      rrule: event.rrule ?? "",
      categoryColor: event.categoryColor ?? "",
      backgroundColor: event.backgroundColor ?? "",
      borderColor: event.borderColor ?? "",
      textColor: event.textColor ?? "",
      dragBackgroundColor: event.dragBackgroundColor ?? "",
      eventCategory: event.eventCategory ?? "",
      eventKind: event.eventKind ?? "calendar",
      url: event.url ?? "",
      attendees: event.attendees ?? "",
      attendeeJson: event.attendeeJson ?? "",
      organizerName: event.organizerName ?? "",
      organizerEmail: event.organizerEmail ?? "",
      conferenceUrl: event.conferenceUrl ?? "",
      attachmentUrl: event.attachmentUrl ?? "",
      attachmentsJson: event.attachmentsJson ?? "",
      travelMinutes: event.travelMinutes ?? 0,
      comingDuration: event.comingDuration ?? 0,
      availability: event.availability ?? "busy",
      freeBusyTransparent: event.freeBusyTransparent ?? false,
      rawPropsJson: this.mergeRawPropsJson(event.rawPropsJson ?? "", diagnosticRaw),
      conflictStatus: "none",
      conflictJson: ""
    } as CalendarEvent;
  }


  private mergeRawPropsJson(existingJson: string, diagnosticJson: string): string {
    const existing: string = existingJson.trim();
    if (existing.length === 0) {
      return diagnosticJson;
    }

    return JSON.stringify({
      preservedRawProps: existing,
      caldavDiagnostic: diagnosticJson
    });
  }

  private isCalDavConflictError(reason: string): boolean {
    const lower: string = reason.toLowerCase();
    return lower.indexOf(" 409") >= 0 ||
      lower.indexOf("返回 409") >= 0 ||
      lower.indexOf(" 412") >= 0 ||
      lower.indexOf("返回 412") >= 0 ||
      lower.indexOf("conflict") >= 0 ||
      lower.indexOf("precondition") >= 0 ||
      lower.indexOf("if-match") >= 0 ||
      lower.indexOf("etag") >= 0;
  }

	  private async refreshSourcesForAccount(account: CalendarAccount): Promise<CalendarSource[]> {
    const accountId: string = account.id ?? "";
    if (accountId.length === 0) {
      return [];
    }

	    const adapter = this.adapterForAccount(account);
	    let discovered: DiscoveredCalendarSource[] = [];
	    let discoveryError: string = "";
	    try {
	      discovered = await adapter.discoverSources(account);
	    } catch (error) {
	      discoveryError = this.describeError(error);
	    }
    const existing: CalendarSource[] = await this.store.listSourcesForAccount(accountId);
    const saved: CalendarSource[] = [];
    const discoveryTraceJson: string = this.sourceDiscoveryTraceJson(account, discovered, discoveryError);

    if (discovered.length === 0) {
      const existingDefault: CalendarSource | undefined = existing.length > 0 ? existing[0] : undefined;
      saved.push(await this.store.upsertSource({
        id: existingDefault?.id,
        accountId,
        name: existingDefault?.name ?? account.displayName ?? "CalDAV 日历",
        description: existingDefault?.description ?? "",
        collectionUrl: existingDefault?.collectionUrl ?? normalizeServerUrl(account.serverUrl),
        subscriptionUrl: existingDefault?.subscriptionUrl ?? "",
        principalUrl: existingDefault?.principalUrl ?? "",
	        homeSetUrl: existingDefault?.homeSetUrl ?? "",
	        scheduleInboxUrl: existingDefault?.scheduleInboxUrl ?? "",
	        scheduleOutboxUrl: existingDefault?.scheduleOutboxUrl ?? "",
	        calendarUserAddressSet: existingDefault?.calendarUserAddressSet ?? "",
	        ownerEmail: existingDefault?.ownerEmail ?? (account.username.indexOf("@") > 0 ? account.username : ""),
        color: existingDefault?.color ?? "#2563EB",
        backgroundColor: existingDefault?.backgroundColor ?? existingDefault?.color ?? "#2563EB",
        borderColor: existingDefault?.borderColor ?? existingDefault?.color ?? "#2563EB",
        textColor: existingDefault?.textColor ?? "#FFFFFF",
        isVisible: existingDefault?.isVisible ?? true,
        isDefault: existingDefault?.isDefault ?? account.isActive === true,
        isReadOnly: existingDefault?.isReadOnly ?? false,
        sourceType: "caldav",
        freeBusyTransparent: existingDefault?.freeBusyTransparent ?? false,
        displayOrder: existingDefault?.displayOrder ?? 0,
        refreshIntervalMinutes: existingDefault?.refreshIntervalMinutes ?? 15,
        refreshPolicy: existingDefault?.refreshPolicy ?? "manualAndInterval",
	        permissionsJson: existingDefault?.permissionsJson ?? "",
	        sharePermissionsJson: existingDefault?.sharePermissionsJson ?? "",
	        shareUsersJson: existingDefault?.shareUsersJson ?? "",
	        shareGroupsJson: existingDefault?.shareGroupsJson ?? "",
	        publicShareUrl: existingDefault?.publicShareUrl ?? "",
	        publicShareToken: existingDefault?.publicShareToken ?? "",
	        supportedReportsJson: existingDefault?.supportedReportsJson ?? "",
	        supportedComponentsJson: existingDefault?.supportedComponentsJson ?? "",
	        discoveryTraceJson,
	        capabilitySource: existingDefault?.capabilitySource ?? "not-discovered",
	        lastDiscoveryError: discoveryError.length > 0 ? discoveryError : "未发现服务端日历集合，保留直接 collection 配置",
        providerType: existingDefault?.providerType ?? inferCalendarProviderType(account.serverUrl),
        providerPresetJson: existingDefault?.providerPresetJson ?? account.providerPresetJson ?? "",
        syncStrategy: existingDefault?.syncStrategy ?? "",
        externalProviderId: existingDefault?.externalProviderId ?? "",
        nativeCalendarId: existingDefault?.nativeCalendarId ?? "",
        nativeCalendarSyncState: existingDefault?.nativeCalendarSyncState ?? "",
        widgetConfigJson: existingDefault?.widgetConfigJson ?? "",
        providerAdapterType: existingDefault?.providerAdapterType ?? "",
        ctag: existingDefault?.ctag ?? "",
        syncToken: existingDefault?.syncToken ?? "",
        lastSuccessfulSyncAt: existingDefault?.lastSuccessfulSyncAt ?? 0,
        lastSyncAt: existingDefault?.lastSyncAt ?? 0,
        lastSyncError: existingDefault?.lastSyncError ?? ""
      }));
      return saved;
    }

    for (let index = 0; index < discovered.length; index += 1) {
      const remote: DiscoveredCalendarSource = discovered[index];
      const matched: CalendarSource | undefined = existing.find((source: CalendarSource) =>
        this.sameCollection(source.collectionUrl, remote.collectionUrl));
      const source: CalendarSource = await this.store.upsertSource({
        id: matched?.id,
        accountId,
        name: remote.name,
        description: remote.description.length > 0 ? remote.description : matched?.description ?? "",
        collectionUrl: remote.collectionUrl,
        subscriptionUrl: matched?.subscriptionUrl ?? "",
	        principalUrl: remote.principalUrl.length > 0 ? remote.principalUrl : matched?.principalUrl ?? "",
	        homeSetUrl: remote.homeSetUrl.length > 0 ? remote.homeSetUrl : matched?.homeSetUrl ?? "",
	        scheduleInboxUrl: remote.scheduleInboxUrl.length > 0 ? remote.scheduleInboxUrl : matched?.scheduleInboxUrl ?? "",
	        scheduleOutboxUrl: remote.scheduleOutboxUrl.length > 0 ? remote.scheduleOutboxUrl : matched?.scheduleOutboxUrl ?? "",
	        calendarUserAddressSet: remote.calendarUserAddressSet.length > 0 ? remote.calendarUserAddressSet : matched?.calendarUserAddressSet ?? "",
	        ownerEmail: remote.ownerEmail.length > 0 ? remote.ownerEmail : matched?.ownerEmail ?? "",
        color: remote.color,
        backgroundColor: remote.backgroundColor,
        borderColor: remote.borderColor,
        textColor: remote.textColor.length > 0 ? remote.textColor : matched?.textColor ?? "#FFFFFF",
        isVisible: matched?.isVisible ?? true,
        isDefault: matched?.isDefault ?? (account.isActive === true && index === 0),
        isReadOnly: remote.isReadOnly,
        sourceType: "caldav",
        freeBusyTransparent: matched?.freeBusyTransparent ?? false,
        displayOrder: matched?.displayOrder ?? index,
        refreshIntervalMinutes: matched?.refreshIntervalMinutes ?? 15,
        refreshPolicy: matched?.refreshPolicy ?? "manualAndInterval",
	        permissionsJson: remote.permissionsJson.length > 0 ? remote.permissionsJson : matched?.permissionsJson ?? "",
	        sharePermissionsJson: matched?.sharePermissionsJson ?? "",
	        shareUsersJson: matched?.shareUsersJson ?? "",
	        shareGroupsJson: matched?.shareGroupsJson ?? "",
	        publicShareUrl: matched?.publicShareUrl ?? "",
	        publicShareToken: matched?.publicShareToken ?? "",
	        supportedReportsJson: remote.supportedReportsJson.length > 0 ? remote.supportedReportsJson : matched?.supportedReportsJson ?? "",
	        supportedComponentsJson: remote.supportedComponentsJson.length > 0 ? remote.supportedComponentsJson : matched?.supportedComponentsJson ?? "",
	        discoveryTraceJson,
	        capabilitySource: remote.capabilitySource.length > 0 ? remote.capabilitySource : matched?.capabilitySource ?? "",
	        lastDiscoveryError: discoveryError,
        providerType: matched?.providerType ?? inferCalendarProviderType(account.serverUrl),
        providerPresetJson: matched?.providerPresetJson ?? account.providerPresetJson ?? "",
        syncStrategy: matched?.syncStrategy ?? "",
        externalProviderId: matched?.externalProviderId ?? "",
        nativeCalendarId: matched?.nativeCalendarId ?? "",
        nativeCalendarSyncState: matched?.nativeCalendarSyncState ?? "",
        widgetConfigJson: matched?.widgetConfigJson ?? "",
        providerAdapterType: matched?.providerAdapterType ?? "",
        ctag: remote.ctag,
        syncToken: remote.syncToken,
        lastSuccessfulSyncAt: matched?.lastSuccessfulSyncAt ?? 0,
        lastSyncAt: matched?.lastSyncAt ?? 0,
        lastSyncError: matched?.lastSyncError ?? ""
      });
      saved.push(source);
    }

    return saved;
  }

  private accountForSource(accounts: CalendarAccount[], source: CalendarSource): CalendarAccount | null {
    const found: CalendarAccount | undefined = accounts.find((account: CalendarAccount) => (account.id ?? "") === source.accountId);
    return found ?? null;
  }

  private preferredHomeSetUrl(sources: CalendarSource[]): string {
    const found: CalendarSource | undefined = sources.find((source: CalendarSource) => (source.homeSetUrl ?? "").length > 0);
    return found?.homeSetUrl ?? "";
  }

  private sameCollection(left: string, right: string): boolean {
    const normalize = (value: string): string => {
      const trimmed: string = value.trim();
      return trimmed.endsWith("/") ? trimmed : `${trimmed}/`;
    };
    return normalize(left) === normalize(right);
  }

  private freeBusyQueryUrl(source: CalendarSource): string {
    if ((source.scheduleOutboxUrl ?? "").length > 0) {
      return source.scheduleOutboxUrl ?? "";
    }
    if ((source.principalUrl ?? "").length > 0) {
      return source.principalUrl ?? "";
    }
    return source.collectionUrl;
  }

  private eventWithSource(event: CalendarEvent, sourceId: string): CalendarEvent {
	    return {
	      id: event.id,
	      sourceId,
	      eventSourceId: event.eventSourceId ?? sourceId,
      uid: event.uid,
      href: event.href,
      etag: event.etag,
      title: event.title,
      startAt: event.startAt,
      endAt: event.endAt,
      allDay: event.allDay,
      location: event.location,
      notes: event.notes,
      reminderMinutes: event.reminderMinutes,
      secondReminderMinutes: event.secondReminderMinutes,
      rrule: event.rrule,
      categoryColor: event.categoryColor,
      backgroundColor: event.backgroundColor,
      borderColor: event.borderColor,
      textColor: event.textColor,
      dragBackgroundColor: event.dragBackgroundColor,
      eventCategory: event.eventCategory,
      eventKind: event.eventKind,
      url: event.url,
      attendees: event.attendees,
      attendeeJson: event.attendeeJson,
      organizerName: event.organizerName,
      organizerEmail: event.organizerEmail,
      conferenceUrl: event.conferenceUrl,
      attachmentUrl: event.attachmentUrl,
      attachmentsJson: event.attachmentsJson,
      travelMinutes: event.travelMinutes,
	      comingDuration: event.comingDuration,
	      availability: event.availability,
	      freeBusyTransparent: event.freeBusyTransparent,
	      privacy: event.privacy,
      timeZone: event.timeZone,
      eventStatus: event.eventStatus,
      appointmentStatus: event.appointmentStatus,
      appointmentCapacity: event.appointmentCapacity,
      appointmentBookedCount: event.appointmentBookedCount,
      appointmentMinDurationMinutes: event.appointmentMinDurationMinutes,
      appointmentMaxDurationMinutes: event.appointmentMaxDurationMinutes,
      appointmentBufferBeforeMinutes: event.appointmentBufferBeforeMinutes,
      appointmentBufferAfterMinutes: event.appointmentBufferAfterMinutes,
      appointmentDeadlineMinutes: event.appointmentDeadlineMinutes,
      appointmentPublicUrl: event.appointmentPublicUrl,
      appointmentFormJson: event.appointmentFormJson,
      appointmentTimezone: event.appointmentTimezone,
      appointmentSlotIntervalMinutes: event.appointmentSlotIntervalMinutes,
      appointmentApprovalRequired: event.appointmentApprovalRequired,
      bookingJson: event.bookingJson,
      bookingContactName: event.bookingContactName,
      bookingContactEmail: event.bookingContactEmail,
      bookingContactPhone: event.bookingContactPhone,
      bookingConfirmationStatus: event.bookingConfirmationStatus,
      bookingStatus: event.bookingStatus,
      exdate: event.exdate,
      rdate: event.rdate,
      recurrenceId: event.recurrenceId,
      sequence: event.sequence,
      reminderOffsets: event.reminderOffsets,
      dueAt: event.dueAt,
      completedAt: event.completedAt,
      priority: event.priority,
      percentComplete: event.percentComplete,
      milestoneStatus: event.milestoneStatus,
      dueDateClass: event.dueDateClass,
      groupId: event.groupId,
      displayMode: event.displayMode,
      overlap: event.overlap,
      editable: event.editable,
      startEditable: event.startEditable,
      durationEditable: event.durationEditable,
      resourceEditable: event.resourceEditable,
      interactive: event.interactive,
      eventReadOnly: event.eventReadOnly,
      isVisible: event.isVisible,
      isPending: event.isPending,
      isFocused: event.isFocused,
      overlapPosition: event.overlapPosition,
      overlapCount: event.overlapCount,
      classNames: event.classNames,
      customStyleJson: event.customStyleJson,
      constraintJson: event.constraintJson,
      extendedPropsJson: event.extendedPropsJson,
      rawPropsJson: event.rawPropsJson,
      resourceIdsJson: event.resourceIdsJson,
      roomIdsJson: event.roomIdsJson,
      resourceStatusJson: event.resourceStatusJson,
      alarmAction: event.alarmAction,
      snoozeMinutes: event.snoozeMinutes,
      snoozeTimes: event.snoozeTimes,
      allDayReminderAt: event.allDayReminderAt,
      alarmActionsJson: event.alarmActionsJson,
      conflictStatus: event.conflictStatus,
      conflictJson: event.conflictJson,
      reminderId: event.reminderId,
      lastModified: event.lastModified,
      syncStatus: event.syncStatus
    };
  }

  private localPendingIds(dirtyEvents: CalendarEvent[], deletedEvents: CalendarEvent[]): string[] {
    const ids: string[] = [];
    dirtyEvents.forEach((event: CalendarEvent) => {
      if (ids.indexOf(event.id) < 0) {
        ids.push(event.id);
      }
    });
    deletedEvents.forEach((event: CalendarEvent) => {
      if (ids.indexOf(event.id) < 0) {
        ids.push(event.id);
      }
    });
    return ids;
  }

  private async ensureDraftComponentSupported(draft: CalendarEventDraft): Promise<void> {
    const source: CalendarSource | undefined = await this.sourceForId(draft.sourceId ?? "");
    if (source === undefined || source.sourceType !== "caldav") {
      return;
    }

    const components: string[] = this.parseComponentList(source.supportedComponentsJson ?? "");
    if (components.length === 0) {
      return;
    }

    const required: string = (draft.eventKind ?? "calendar") === "task" ? "VTODO" : "VEVENT";
    if (components.indexOf(required) >= 0) {
      return;
    }

    throw new Error(`${source.name} 不支持 ${required === "VTODO" ? "任务 VTODO" : "事件 VEVENT"}，请选择支持该组件的日历源`);
  }

  private async ensureDraftCanCreate(draft: CalendarEventDraft): Promise<void> {
    const source: CalendarSource | undefined = await this.sourceForId(draft.sourceId ?? "");
    if (source === undefined || source.sourceType !== "caldav") {
      return;
    }

    if (!this.canCreateInSource(source)) {
      throw new Error(`${source.name} 没有新建日程权限，需要 DAV bind 或 write 权限`);
    }
  }

  private async ensureEventCanUpdate(event: CalendarEvent): Promise<void> {
    const source: CalendarSource | undefined = await this.sourceForId(event.sourceId);
    if (source === undefined || source.sourceType !== "caldav") {
      return;
    }

    if (!this.canUpdateInSource(source)) {
      throw new Error(`${source.name} 没有更新日程权限，需要 DAV write-content 或 write 权限`);
    }
  }

  private async ensureEventCanDelete(event: CalendarEvent): Promise<void> {
    const source: CalendarSource | undefined = await this.sourceForId(event.sourceId);
    if (source === undefined || source.sourceType !== "caldav") {
      return;
    }

    if (!this.canDeleteFromSource(source)) {
      throw new Error(`${source.name} 没有删除日程权限，需要 DAV unbind 或 write 权限`);
    }
  }

  private async sourceForId(sourceId: string): Promise<CalendarSource | undefined> {
    if (sourceId.length === 0) {
      return undefined;
    }

    const sources: CalendarSource[] = await this.store.listSources();
    return sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
  }

  private validateAccount(account: CalendarAccount): void {
    if (account.serverUrl.trim().length === 0) {
      throw new Error("请填写 CalDAV 地址");
    }

		    const authType: string = account.authType ?? "basic";
	    if (authType === "basic" && account.username.trim().length === 0) {
	      throw new Error("请填写 CalDAV 用户名或邮箱");
	    }

		    if (authType === "basic" && account.password.length === 0) {
		      throw new Error("请填写 CalDAV 密码或应用专用密码");
		    }

		    if (authType === "bearer" && (account.bearerToken ?? account.password).length === 0) {
		      throw new Error("请填写 Bearer 访问令牌");
		    }

	    const customHeadersJson: string = account.customHeadersJson ?? "";
	    if (customHeadersJson.trim().length > 0) {
	      try {
	        const parsed = JSON.parse(customHeadersJson) as object;
	        if (Array.isArray(parsed)) {
	          throw new Error("headers must be object");
	        }
	      } catch {
	        throw new Error("额外请求头必须是 JSON 对象");
	      }
	    }
	  }

  private normalizeSubscriptionUrl(url: string): string {
    const trimmed: string = url.trim();
    if (trimmed.toLowerCase().startsWith("webcal://")) {
      return `https://${trimmed.substring("webcal://".length)}`;
    }

    return trimmed;
  }

	  private shouldRefreshSource(source: CalendarSource, now: number): boolean {
    if (!source.isVisible) {
      return false;
    }

    const policy: string = source.refreshPolicy ?? "manualAndInterval";
    if (policy === "manualOnly") {
      return false;
    }

    const intervalMinutes: number = source.refreshIntervalMinutes ?? 15;
    if (intervalMinutes <= 0) {
      return true;
    }

	    const lastSyncAt: number = source.lastSyncAt ?? 0;
	    return lastSyncAt <= 0 || now - lastSyncAt >= intervalMinutes * 60 * 1000;
	  }

	  private canWriteSource(source: CalendarSource): boolean {
	    if (source.sourceType !== "caldav" || source.isReadOnly) {
	      return false;
	    }

	    const permissions: string = (source.permissionsJson ?? "").toLowerCase();
	    if (permissions.length === 0) {
	      return true;
	    }

	    return this.hasDavPrivilege(permissions, "write") ||
        this.hasDavPrivilege(permissions, "write-content") ||
        this.hasDavPrivilege(permissions, "bind") ||
	      this.hasDavPrivilege(permissions, "unbind");
	  }

  private canCreateInSource(source: CalendarSource): boolean {
    return this.canWriteWithPrivileges(source, ["write", "bind"]);
  }

  private canUpdateInSource(source: CalendarSource): boolean {
    return this.canWriteWithPrivileges(source, ["write", "write-content"]);
  }

  private canDeleteFromSource(source: CalendarSource): boolean {
    return this.canWriteWithPrivileges(source, ["write", "unbind"]);
  }

  private canPushEventToSource(source: CalendarSource, event: CalendarEvent): boolean {
    return event.href.length > 0 ? this.canUpdateInSource(source) : this.canCreateInSource(source);
  }

  private canWriteWithPrivileges(source: CalendarSource, required: string[]): boolean {
    if (source.sourceType !== "caldav" || source.isReadOnly) {
      return false;
    }

    const permissions: string = (source.permissionsJson ?? "").toLowerCase();
    if (permissions.length === 0) {
      return true;
    }

    return required.find((privilege: string) => this.hasDavPrivilege(permissions, privilege)) !== undefined;
  }

  private hasDavPrivilege(permissions: string, privilege: string): boolean {
    return permissions.split(/[,\s]+/).indexOf(privilege) >= 0;
  }

	  private async syncLocalReminder(event: CalendarEvent): Promise<void> {
    if (this.reminderService === null) {
      return;
    }

    try {
      const viewConfig: CalendarViewConfig = await this.store.loadViewConfig();
      const preferences: CalendarReminderPreferences = {
        defaultReminderMinutes: viewConfig.defaultReminderMinutes ?? 15,
        reminderSound: viewConfig.reminderSound ?? "default",
        reminderVibrate: viewConfig.reminderVibrate !== false,
        snoozeMinutes: event.snoozeMinutes ?? 0,
        snoozeTimes: event.snoozeTimes ?? 0
      };
      const reminderId: number = await this.reminderService.syncReminder(event, preferences);
      await this.store.updateReminderId(event.id, reminderId);
    } catch (error) {
      console.error(`Sync local reminder failed: id=${event.id}, title=${event.title}, reason=${this.describeError(error)}`);
    }
  }

  private async cancelLocalReminder(event: CalendarEvent): Promise<void> {
    if (this.reminderService === null || (event.reminderId ?? 0) <= 0) {
      return;
    }

    await this.reminderService.cancelReminder(event.reminderId ?? 0);
    await this.store.updateReminderId(event.id, 0);
  }

  private describeError(error: Object): string {
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
  }

  private httpStatusFromError(error: Object): number {
    if (error instanceof CalDavHttpError || error instanceof SubscriptionHttpError) {
      return error.status;
    }

    const match: RegExpMatchArray | null = this.describeError(error).match(/返回\s+(\d{3})|HTTP\s+(\d{3})|status[=:]\s*(\d{3})/i);
    if (match === null) {
      return 0;
    }

    const value: string = match[1] ?? match[2] ?? match[3] ?? "";
    const parsed: number = Number(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  private retryAfterFromError(error: Object): number {
    if (error instanceof CalDavHttpError || error instanceof SubscriptionHttpError) {
      return error.retryAfterSeconds;
    }

    const match: RegExpMatchArray | null = this.describeError(error).match(/retry-after[=:]\s*(\d+)/i);
    if (match === null) {
      return 0;
    }

    const parsed: number = Number(match[1]);
    return Number.isNaN(parsed) ? 0 : Math.max(0, Math.floor(parsed));
  }

  private diagnosticJsonFromError(error: Object, protocol: string): string {
    if (error instanceof CalDavHttpError || error instanceof SubscriptionHttpError) {
      return error.toDiagnosticJson();
    }

    return JSON.stringify({
      protocol,
      httpStatus: this.httpStatusFromError(error),
      retryAfterSeconds: this.retryAfterFromError(error),
      error: this.describeError(error),
      checkedAt: Date.now()
    });
  }

  private sourceDiagnosticJson(source: CalendarSource, code: string, message: string): string {
    return JSON.stringify({
      protocol: source.sourceType === "subscription" ? "ics-subscription" : "caldav",
      code,
      message,
      sourceId: source.id ?? "",
      accountId: source.accountId,
      collectionUrl: source.collectionUrl,
      providerType: source.providerType ?? "",
      syncStrategy: source.syncStrategy ?? "",
      checkedAt: Date.now()
    });
  }
}
