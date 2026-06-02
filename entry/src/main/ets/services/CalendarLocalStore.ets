import { common } from "@kit.AbilityKit";
import { relationalStore } from "@kit.ArkData";
import {
  CalendarAccount,
  CalendarConflictStatus,
  CalendarDateMarker,
  CalendarDateMarkingType,
  CalendarEvent,
  CalendarEventDraft,
  CalendarResource,
  CalendarResourceType,
  CalendarSource,
  CalendarSyncStatus,
  CalendarViewConfig
} from "./CalendarTypes";
import { createEventUid, createLocalId, normalizeCollectionUrl } from "./CalendarFormat";
import { inferCalendarProviderType } from "./CalendarProviderPresets";

const DATABASE_NAME: string = "calendar.db";
const ACCOUNT_TABLE: string = "caldav_accounts";
// ---- ArkTS spread helper ----
const CALDAV_ACCOUNT_TABLE: string = "caldav_accounts";
const SOURCE_TABLE: string = "calendar_sources";
const EVENT_TABLE: string = "calendar_events";
const VIEW_CONFIG_TABLE: string = "calendar_view_config";
const DATE_MARKER_TABLE: string = "calendar_date_markers";
const RESOURCE_TABLE: string = "calendar_resources";

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DATABASE_NAME,
  securityLevel: relationalStore.SecurityLevel.S3,
  encrypt: true
};

const ACCOUNT_COLUMNS: string[] = ["server_url", "username", "password"];
const CALDAV_ACCOUNT_COLUMNS: string[] = [
  "id",
  "display_name",
  "provider_type",
  "provider_preset_json",
  "server_url",
  "username",
  "password",
  "auth_type",
  "bearer_token",
  "custom_headers_json",
  "is_active"
];
const SOURCE_COLUMNS: string[] = [
  "id",
  "account_id",
  "name",
  "description",
  "collection_url",
  "subscription_url",
  "principal_url",
  "home_set_url",
  "schedule_inbox_url",
  "schedule_outbox_url",
  "calendar_user_address_set",
  "owner_email",
  "color",
  "background_color",
  "border_color",
  "text_color",
  "is_visible",
  "is_default",
  "is_read_only",
  "source_type",
  "free_busy_transparent",
  "display_order",
  "refresh_interval_minutes",
  "refresh_policy",
  "permissions_json",
  "share_permissions_json",
  "share_users_json",
  "share_groups_json",
  "public_share_url",
  "public_share_token",
  "supported_reports_json",
  "supported_components_json",
  "discovery_trace_json",
  "capability_source",
  "last_discovery_error",
  "provider_type",
  "provider_preset_json",
  "sync_strategy",
  "external_provider_id",
  "native_calendar_id",
  "native_calendar_sync_state",
  "widget_config_json",
  "provider_adapter_type",
  "source_loading_state",
  "last_loaded_range_start",
  "last_loaded_range_end",
  "subscription_etag",
  "subscription_last_modified",
  "ctag",
  "sync_token",
  "last_successful_sync_at",
  "last_sync_at",
  "last_sync_http_status",
  "retry_after_seconds",
  "last_sync_diagnostic_json",
  "last_sync_error"
];
const EVENT_COLUMNS: string[] = [
  "id",
  "source_id",
  "event_source_id",
  "uid",
  "href",
  "etag",
  "title",
  "start_at",
  "end_at",
  "all_day",
  "location",
  "notes",
  "reminder_minutes",
  "second_reminder_minutes",
  "rrule",
  "category_color",
  "background_color",
  "border_color",
  "text_color",
  "drag_background_color",
  "event_category",
  "event_kind",
  "url",
  "attendees",
  "attendee_json",
  "organizer_name",
  "organizer_email",
  "conference_url",
  "attachment_url",
  "attachments_json",
  "travel_minutes",
  "coming_duration",
  "availability",
  "free_busy_transparent",
  "privacy",
  "time_zone",
  "event_status",
  "appointment_status",
  "appointment_capacity",
  "appointment_booked_count",
  "appointment_min_duration_minutes",
  "appointment_max_duration_minutes",
  "appointment_buffer_before_minutes",
  "appointment_buffer_after_minutes",
  "appointment_deadline_minutes",
  "appointment_public_url",
  "appointment_form_json",
  "appointment_timezone",
  "appointment_slot_interval_minutes",
  "appointment_approval_required",
  "booking_json",
  "booking_contact_name",
  "booking_contact_email",
  "booking_contact_phone",
  "booking_confirmation_status",
  "booking_status",
  "exdate",
  "rdate",
  "recurrence_id",
  "sequence",
  "reminder_offsets",
  "due_at",
  "completed_at",
  "priority",
  "percent_complete",
  "milestone_status",
  "due_date_class",
  "group_id",
  "display_mode",
  "overlap",
  "editable",
  "start_editable",
  "duration_editable",
  "resource_editable",
  "interactive",
  "event_read_only",
  "is_visible",
  "is_pending",
  "is_focused",
  "overlap_position",
  "overlap_count",
  "class_names",
  "custom_style_json",
  "constraint_json",
  "extended_props_json",
  "raw_props_json",
  "resource_ids_json",
  "room_ids_json",
  "resource_status_json",
  "alarm_action",
  "snooze_minutes",
  "snooze_times",
  "all_day_reminder_at",
  "alarm_actions_json",
  "reminder_id",
  "conflict_status",
  "conflict_json",
  "last_modified",
  "sync_status"
];
const VIEW_CONFIG_COLUMNS: string[] = [
  "id",
  "default_view",
  "week_starts_on",
  "week_ends_on",
  "min_hour",
  "max_hour",
  "time_slot_minutes",
  "max_visible_events_per_day",
  "overlap_offset",
  "swipe_enabled",
  "show_week_numbers",
  "show_six_weeks",
  "show_adjacent_months",
  "now_indicator_visible",
  "scroll_offset_minutes",
  "hour_row_height",
  "event_min_height_for_month_view",
  "show_all_day_event_cell",
  "timeslots",
  "month_more_label",
  "event_order",
  "locale",
  "hour_format",
  "time_zone",
  "enabled_views_json",
  "agenda_empty_text",
  "agenda_group_mode",
  "agenda_show_past_days",
  "agenda_past_scroll_range",
  "agenda_future_scroll_range",
  "agenda_show_only_selected_day_items",
  "theme_mode",
  "default_reminder_minutes",
  "reminder_sound",
  "reminder_vibrate",
  "event_kind_filter",
  "source_filter_json",
  "hide_cancelled_events",
  "show_incomplete_tasks_only",
  "business_hours_json",
  "min_selectable_date",
  "max_selectable_date",
  "disabled_days_indexes_json",
  "display_loading_indicator",
  "loaded_date_ranges_json"
];
const DATE_MARKER_COLUMNS: string[] = [
  "id",
  "marker_date",
  "marking_type",
  "title",
  "color",
  "selected",
  "disabled",
  "disable_touch_event",
  "dot_colors_json",
  "multi_period_json",
  "period_start",
  "period_end",
  "period_color",
  "selected_color",
  "selected_dot_color",
  "accessibility_label",
  "custom_mark_json"
];
const RESOURCE_COLUMNS: string[] = [
  "id",
  "source_id",
  "resource_type",
  "name",
  "email",
  "external_id",
  "parent_resource_id",
  "resource_group_id",
  "capacity",
  "location",
  "color",
  "is_bookable",
  "is_visible",
  "availability_json",
  "conflict_policy",
  "auto_accept",
  "backend_id",
  "event_constraint_json",
  "event_allow_json",
  "event_class_names",
  "permissions_json",
  "raw_props_json",
  "last_sync_at"
];

const CREATE_ACCOUNT_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS caldav_account (
  singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
  server_url TEXT NOT NULL,
  username TEXT NOT NULL,
  password TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)`;

const CREATE_CALDAV_ACCOUNT_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS caldav_accounts (
  id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  provider_type TEXT NOT NULL DEFAULT 'custom',
  provider_preset_json TEXT NOT NULL DEFAULT '',
  server_url TEXT NOT NULL,
  username TEXT NOT NULL,
  password TEXT NOT NULL,
  auth_type TEXT NOT NULL DEFAULT 'basic',
  bearer_token TEXT NOT NULL DEFAULT '',
  custom_headers_json TEXT NOT NULL DEFAULT '',
  is_active INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
)`;

const CREATE_SOURCE_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS calendar_sources (
  id TEXT PRIMARY KEY,
  account_id TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  collection_url TEXT NOT NULL,
  subscription_url TEXT NOT NULL DEFAULT '',
  principal_url TEXT NOT NULL DEFAULT '',
  home_set_url TEXT NOT NULL DEFAULT '',
  schedule_inbox_url TEXT NOT NULL DEFAULT '',
  schedule_outbox_url TEXT NOT NULL DEFAULT '',
  calendar_user_address_set TEXT NOT NULL DEFAULT '',
  owner_email TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#2563EB',
  background_color TEXT NOT NULL DEFAULT '#2563EB',
  border_color TEXT NOT NULL DEFAULT '#2563EB',
  text_color TEXT NOT NULL DEFAULT '#FFFFFF',
  is_visible INTEGER NOT NULL DEFAULT 1,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_read_only INTEGER NOT NULL DEFAULT 0,
  source_type TEXT NOT NULL DEFAULT 'caldav',
  free_busy_transparent INTEGER NOT NULL DEFAULT 0,
  display_order INTEGER NOT NULL DEFAULT 0,
  refresh_interval_minutes INTEGER NOT NULL DEFAULT 15,
  refresh_policy TEXT NOT NULL DEFAULT 'manualAndInterval',
  permissions_json TEXT NOT NULL DEFAULT '',
  share_permissions_json TEXT NOT NULL DEFAULT '',
  share_users_json TEXT NOT NULL DEFAULT '',
  share_groups_json TEXT NOT NULL DEFAULT '',
  public_share_url TEXT NOT NULL DEFAULT '',
  public_share_token TEXT NOT NULL DEFAULT '',
  supported_reports_json TEXT NOT NULL DEFAULT '',
  supported_components_json TEXT NOT NULL DEFAULT '',
  discovery_trace_json TEXT NOT NULL DEFAULT '',
  capability_source TEXT NOT NULL DEFAULT '',
  last_discovery_error TEXT NOT NULL DEFAULT '',
  provider_type TEXT NOT NULL DEFAULT 'custom',
  provider_preset_json TEXT NOT NULL DEFAULT '',
  sync_strategy TEXT NOT NULL DEFAULT '',
  external_provider_id TEXT NOT NULL DEFAULT '',
  native_calendar_id TEXT NOT NULL DEFAULT '',
  native_calendar_sync_state TEXT NOT NULL DEFAULT '',
  widget_config_json TEXT NOT NULL DEFAULT '',
  provider_adapter_type TEXT NOT NULL DEFAULT '',
  source_loading_state TEXT NOT NULL DEFAULT 'idle',
  last_loaded_range_start INTEGER NOT NULL DEFAULT 0,
  last_loaded_range_end INTEGER NOT NULL DEFAULT 0,
  subscription_etag TEXT NOT NULL DEFAULT '',
  subscription_last_modified TEXT NOT NULL DEFAULT '',
  ctag TEXT NOT NULL DEFAULT '',
  sync_token TEXT NOT NULL DEFAULT '',
  last_successful_sync_at INTEGER NOT NULL DEFAULT 0,
  last_sync_at INTEGER NOT NULL DEFAULT 0,
  last_sync_http_status INTEGER NOT NULL DEFAULT 0,
  retry_after_seconds INTEGER NOT NULL DEFAULT 0,
  last_sync_diagnostic_json TEXT NOT NULL DEFAULT '',
  last_sync_error TEXT NOT NULL DEFAULT '',
  updated_at INTEGER NOT NULL
)`;

const CREATE_EVENT_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS calendar_events (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL DEFAULT '',
  event_source_id TEXT NOT NULL DEFAULT '',
  uid TEXT NOT NULL,
  href TEXT NOT NULL,
  etag TEXT NOT NULL,
  title TEXT NOT NULL,
  start_at INTEGER NOT NULL,
  end_at INTEGER NOT NULL,
  all_day INTEGER NOT NULL,
  location TEXT NOT NULL,
  notes TEXT NOT NULL,
  reminder_minutes INTEGER NOT NULL DEFAULT 0,
  second_reminder_minutes INTEGER NOT NULL DEFAULT 0,
  rrule TEXT NOT NULL DEFAULT '',
  category_color TEXT NOT NULL DEFAULT '#2563EB',
  background_color TEXT NOT NULL DEFAULT '',
  border_color TEXT NOT NULL DEFAULT '',
  text_color TEXT NOT NULL DEFAULT '',
  drag_background_color TEXT NOT NULL DEFAULT '',
  event_category TEXT NOT NULL DEFAULT '',
  event_kind TEXT NOT NULL DEFAULT 'calendar',
  url TEXT NOT NULL DEFAULT '',
  attendees TEXT NOT NULL DEFAULT '',
  attendee_json TEXT NOT NULL DEFAULT '',
  organizer_name TEXT NOT NULL DEFAULT '',
  organizer_email TEXT NOT NULL DEFAULT '',
  conference_url TEXT NOT NULL DEFAULT '',
  attachment_url TEXT NOT NULL DEFAULT '',
  attachments_json TEXT NOT NULL DEFAULT '',
  travel_minutes INTEGER NOT NULL DEFAULT 0,
  coming_duration INTEGER NOT NULL DEFAULT 0,
  availability TEXT NOT NULL DEFAULT 'busy',
  free_busy_transparent INTEGER NOT NULL DEFAULT 0,
  privacy TEXT NOT NULL DEFAULT 'default',
  time_zone TEXT NOT NULL DEFAULT '',
  event_status TEXT NOT NULL DEFAULT 'confirmed',
  appointment_status TEXT NOT NULL DEFAULT 'available',
  appointment_capacity INTEGER NOT NULL DEFAULT 1,
  appointment_booked_count INTEGER NOT NULL DEFAULT 0,
  appointment_min_duration_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_max_duration_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_buffer_before_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_buffer_after_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_deadline_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_public_url TEXT NOT NULL DEFAULT '',
  appointment_form_json TEXT NOT NULL DEFAULT '',
  appointment_timezone TEXT NOT NULL DEFAULT '',
  appointment_slot_interval_minutes INTEGER NOT NULL DEFAULT 0,
  appointment_approval_required INTEGER NOT NULL DEFAULT 0,
  booking_json TEXT NOT NULL DEFAULT '',
  booking_contact_name TEXT NOT NULL DEFAULT '',
  booking_contact_email TEXT NOT NULL DEFAULT '',
  booking_contact_phone TEXT NOT NULL DEFAULT '',
  booking_confirmation_status TEXT NOT NULL DEFAULT '',
  booking_status TEXT NOT NULL DEFAULT '',
  exdate TEXT NOT NULL DEFAULT '',
  rdate TEXT NOT NULL DEFAULT '',
  recurrence_id TEXT NOT NULL DEFAULT '',
  sequence INTEGER NOT NULL DEFAULT 0,
  reminder_offsets TEXT NOT NULL DEFAULT '',
  due_at INTEGER NOT NULL DEFAULT 0,
  completed_at INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 0,
  percent_complete INTEGER NOT NULL DEFAULT 0,
  milestone_status TEXT NOT NULL DEFAULT '',
  due_date_class TEXT NOT NULL DEFAULT '',
  group_id TEXT NOT NULL DEFAULT '',
  display_mode TEXT NOT NULL DEFAULT '',
  overlap INTEGER NOT NULL DEFAULT 1,
  editable INTEGER NOT NULL DEFAULT 1,
  start_editable INTEGER NOT NULL DEFAULT 1,
  duration_editable INTEGER NOT NULL DEFAULT 1,
  resource_editable INTEGER NOT NULL DEFAULT 1,
  interactive INTEGER NOT NULL DEFAULT 1,
  event_read_only INTEGER NOT NULL DEFAULT 0,
  is_visible INTEGER NOT NULL DEFAULT 1,
  is_pending INTEGER NOT NULL DEFAULT 0,
  is_focused INTEGER NOT NULL DEFAULT 0,
  overlap_position INTEGER NOT NULL DEFAULT 0,
  overlap_count INTEGER NOT NULL DEFAULT 1,
  class_names TEXT NOT NULL DEFAULT '',
  custom_style_json TEXT NOT NULL DEFAULT '',
  constraint_json TEXT NOT NULL DEFAULT '',
  extended_props_json TEXT NOT NULL DEFAULT '',
  raw_props_json TEXT NOT NULL DEFAULT '',
  resource_ids_json TEXT NOT NULL DEFAULT '',
  room_ids_json TEXT NOT NULL DEFAULT '',
  resource_status_json TEXT NOT NULL DEFAULT '',
  alarm_action TEXT NOT NULL DEFAULT '',
  snooze_minutes INTEGER NOT NULL DEFAULT 0,
  snooze_times INTEGER NOT NULL DEFAULT 0,
  all_day_reminder_at TEXT NOT NULL DEFAULT '',
  alarm_actions_json TEXT NOT NULL DEFAULT '',
  reminder_id INTEGER NOT NULL DEFAULT 0,
  conflict_status TEXT NOT NULL DEFAULT 'none',
  conflict_json TEXT NOT NULL DEFAULT '',
  last_modified INTEGER NOT NULL,
  sync_status TEXT NOT NULL,
  updated_at INTEGER NOT NULL
)`;

const CREATE_VIEW_CONFIG_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS calendar_view_config (
  id TEXT PRIMARY KEY,
  default_view TEXT NOT NULL DEFAULT 'day',
  week_starts_on INTEGER NOT NULL DEFAULT 1,
  week_ends_on INTEGER NOT NULL DEFAULT 0,
  min_hour INTEGER NOT NULL DEFAULT 8,
  max_hour INTEGER NOT NULL DEFAULT 21,
  time_slot_minutes INTEGER NOT NULL DEFAULT 60,
  max_visible_events_per_day INTEGER NOT NULL DEFAULT 3,
  overlap_offset INTEGER NOT NULL DEFAULT 6,
  swipe_enabled INTEGER NOT NULL DEFAULT 1,
  show_week_numbers INTEGER NOT NULL DEFAULT 0,
  show_six_weeks INTEGER NOT NULL DEFAULT 1,
  show_adjacent_months INTEGER NOT NULL DEFAULT 1,
  now_indicator_visible INTEGER NOT NULL DEFAULT 1,
  scroll_offset_minutes INTEGER NOT NULL DEFAULT 480,
  hour_row_height INTEGER NOT NULL DEFAULT 56,
  event_min_height_for_month_view INTEGER NOT NULL DEFAULT 18,
  show_all_day_event_cell INTEGER NOT NULL DEFAULT 1,
  timeslots INTEGER NOT NULL DEFAULT 1,
  month_more_label TEXT NOT NULL DEFAULT '更多',
  event_order TEXT NOT NULL DEFAULT 'start,title',
  locale TEXT NOT NULL DEFAULT 'zh-CN',
  hour_format TEXT NOT NULL DEFAULT '24h',
  time_zone TEXT NOT NULL DEFAULT 'Asia/Shanghai',
  enabled_views_json TEXT NOT NULL DEFAULT '',
  agenda_empty_text TEXT NOT NULL DEFAULT '当天没有日程',
  agenda_group_mode TEXT NOT NULL DEFAULT 'day',
  agenda_show_past_days INTEGER NOT NULL DEFAULT 0,
  agenda_past_scroll_range INTEGER NOT NULL DEFAULT 6,
  agenda_future_scroll_range INTEGER NOT NULL DEFAULT 12,
  agenda_show_only_selected_day_items INTEGER NOT NULL DEFAULT 0,
  theme_mode TEXT NOT NULL DEFAULT 'system',
  default_reminder_minutes INTEGER NOT NULL DEFAULT 15,
  reminder_sound TEXT NOT NULL DEFAULT 'default',
  reminder_vibrate INTEGER NOT NULL DEFAULT 1,
  event_kind_filter TEXT NOT NULL DEFAULT 'all',
  source_filter_json TEXT NOT NULL DEFAULT '',
  hide_cancelled_events INTEGER NOT NULL DEFAULT 0,
  show_incomplete_tasks_only INTEGER NOT NULL DEFAULT 0,
  business_hours_json TEXT NOT NULL DEFAULT '',
  min_selectable_date INTEGER NOT NULL DEFAULT 0,
  max_selectable_date INTEGER NOT NULL DEFAULT 0,
  disabled_days_indexes_json TEXT NOT NULL DEFAULT '',
  display_loading_indicator INTEGER NOT NULL DEFAULT 0,
  loaded_date_ranges_json TEXT NOT NULL DEFAULT '',
  updated_at INTEGER NOT NULL
)`;

const CREATE_DATE_MARKER_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS calendar_date_markers (
  id TEXT PRIMARY KEY,
  marker_date INTEGER NOT NULL,
  marking_type TEXT NOT NULL DEFAULT 'dot',
  title TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#2563EB',
  selected INTEGER NOT NULL DEFAULT 0,
  disabled INTEGER NOT NULL DEFAULT 0,
  disable_touch_event INTEGER NOT NULL DEFAULT 0,
  dot_colors_json TEXT NOT NULL DEFAULT '',
  multi_period_json TEXT NOT NULL DEFAULT '',
  period_start INTEGER NOT NULL DEFAULT 0,
  period_end INTEGER NOT NULL DEFAULT 0,
  period_color TEXT NOT NULL DEFAULT '',
  selected_color TEXT NOT NULL DEFAULT '',
  selected_dot_color TEXT NOT NULL DEFAULT '',
  accessibility_label TEXT NOT NULL DEFAULT '',
  custom_mark_json TEXT NOT NULL DEFAULT '',
  updated_at INTEGER NOT NULL
)`;

const CREATE_RESOURCE_TABLE_SQL: string = `
CREATE TABLE IF NOT EXISTS calendar_resources (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL DEFAULT '',
  resource_type TEXT NOT NULL DEFAULT 'resource',
  name TEXT NOT NULL,
  email TEXT NOT NULL DEFAULT '',
  external_id TEXT NOT NULL DEFAULT '',
  parent_resource_id TEXT NOT NULL DEFAULT '',
  resource_group_id TEXT NOT NULL DEFAULT '',
  capacity INTEGER NOT NULL DEFAULT 0,
  location TEXT NOT NULL DEFAULT '',
  color TEXT NOT NULL DEFAULT '#2563EB',
  is_bookable INTEGER NOT NULL DEFAULT 1,
  is_visible INTEGER NOT NULL DEFAULT 1,
  availability_json TEXT NOT NULL DEFAULT '',
  conflict_policy TEXT NOT NULL DEFAULT 'deny',
  auto_accept INTEGER NOT NULL DEFAULT 0,
  backend_id TEXT NOT NULL DEFAULT '',
  event_constraint_json TEXT NOT NULL DEFAULT '',
  event_allow_json TEXT NOT NULL DEFAULT '',
  event_class_names TEXT NOT NULL DEFAULT '',
  permissions_json TEXT NOT NULL DEFAULT '',
  raw_props_json TEXT NOT NULL DEFAULT '',
  last_sync_at INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
)`;

export class CalendarLocalStore {
  private readonly context: common.Context;
  private store: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  constructor(context: common.Context) {
    this.context = context;
  }

  async init(): Promise<void> {
    if (this.initPromise !== null) {
      return this.initPromise;
    }

    this.initPromise = this.openAndMigrate();
    return this.initPromise;
  }

  async loadAccount(): Promise<CalendarAccount | null> {
    const accounts: CalendarAccount[] = await this.listAccounts();
    const active: CalendarAccount[] = accounts.filter((account: CalendarAccount) => account.isActive === true);
    if (active.length > 0) {
      return active[0];
    }

    if (accounts.length > 0) {
      return accounts[0];
    }

    return null;
  }

  async saveAccount(account: CalendarAccount): Promise<void> {
    await this.saveCalDavAccount({
      id: account.id,
      displayName: account.displayName,
      providerType: account.providerType,
	      providerPresetJson: account.providerPresetJson,
	      serverUrl: account.serverUrl,
	      username: account.username,
	      password: account.password,
	      authType: account.authType,
	      bearerToken: account.bearerToken,
	      customHeadersJson: account.customHeadersJson,
	      isActive: true
	    });
  }

  async listAccounts(): Promise<CalendarAccount[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(CALDAV_ACCOUNT_TABLE);
    predicates.orderByDesc("is_active");
    predicates.orderByDesc("updated_at");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, CALDAV_ACCOUNT_COLUMNS);

    try {
      const items: CalendarAccount[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readAccount(resultSet));
      }

      return items;
    } finally {
      resultSet.close();
    }
  }

  async saveCalDavAccount(account: CalendarAccount): Promise<CalendarAccount> {
    await this.init();
    const store: relationalStore.RdbStore = this.requireStore();
    const id: string = account.id !== undefined && account.id.length > 0 ? account.id : createLocalId("caldav");
    const active: boolean = account.isActive !== false;

    if (active) {
      await store.executeSql(`UPDATE ${CALDAV_ACCOUNT_TABLE} SET is_active = 0`);
    }

    await store.executeSql(`DELETE FROM ${CALDAV_ACCOUNT_TABLE} WHERE id = '${escapeSql(id)}'`);
    const saved: CalendarAccount = {
      id,
      displayName: this.accountDisplayName(account),
      providerType: account.providerType ?? inferCalendarProviderType(account.serverUrl),
      providerPresetJson: account.providerPresetJson ?? "",
	      serverUrl: account.serverUrl,
	      username: account.username,
	      password: account.password,
	      authType: this.normalizeAuthType(account.authType),
	      bearerToken: account.bearerToken ?? "",
	      customHeadersJson: account.customHeadersJson ?? "",
	      isActive: active
	    };

    await store.insert(CALDAV_ACCOUNT_TABLE, {
      id: saved.id,
      display_name: saved.displayName,
      provider_type: saved.providerType ?? "custom",
      provider_preset_json: saved.providerPresetJson ?? "",
	      server_url: saved.serverUrl,
	      username: saved.username,
	      password: saved.password,
	      auth_type: saved.authType ?? "basic",
	      bearer_token: saved.bearerToken ?? "",
	      custom_headers_json: saved.customHeadersJson ?? "",
	      is_active: saved.isActive ? 1 : 0,
	      updated_at: Date.now()
	    });
    return saved;
  }

  async listSources(): Promise<CalendarSource[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(SOURCE_TABLE);
    predicates.orderByDesc("is_default");
    predicates.orderByAsc("name");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, SOURCE_COLUMNS);

    try {
      const items: CalendarSource[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readSource(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async listSourcesForAccount(accountId: string): Promise<CalendarSource[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(SOURCE_TABLE);
    predicates.equalTo("account_id", accountId);
    predicates.orderByDesc("is_default");
    predicates.orderByAsc("name");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, SOURCE_COLUMNS);

    try {
      const items: CalendarSource[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readSource(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async loadDefaultSource(): Promise<CalendarSource | null> {
    await this.init();
    const sources: CalendarSource[] = await this.listSources();
    const defaults: CalendarSource[] = sources.filter((source: CalendarSource) => source.isDefault && !source.isReadOnly);
    if (defaults.length > 0) {
      return defaults[0];
    }

    const writable: CalendarSource[] = sources.filter((source: CalendarSource) => !source.isReadOnly);
    if (writable.length > 0) {
      return writable[0];
    }

    return sources.length > 0 ? sources[0] : null;
  }

  async upsertSource(source: CalendarSource): Promise<CalendarSource> {
    await this.init();
    const id: string = source.id !== undefined && source.id.length > 0 ? source.id : createLocalId("source");
	    const saved: CalendarSource = {
	      id,
	      accountId: source.accountId,
	      name: source.name.trim().length > 0 ? source.name.trim() : "CalDAV 日历",
	      description: source.description ?? "",
	      collectionUrl: normalizeCollectionUrl(source.collectionUrl),
		      subscriptionUrl: source.subscriptionUrl ?? "",
		      principalUrl: source.principalUrl ?? "",
		      homeSetUrl: source.homeSetUrl ?? "",
		      scheduleInboxUrl: source.scheduleInboxUrl ?? "",
		      scheduleOutboxUrl: source.scheduleOutboxUrl ?? "",
		      calendarUserAddressSet: source.calendarUserAddressSet ?? "",
		      ownerEmail: source.ownerEmail ?? "",
	      color: normalizeColor(source.color),
	      backgroundColor: normalizeColor(source.backgroundColor ?? source.color),
	      borderColor: normalizeColor(source.borderColor ?? source.color),
	      textColor: source.textColor ?? "#FFFFFF",
	      isVisible: source.isVisible,
	      isDefault: source.isDefault,
	      isReadOnly: source.isReadOnly,
	      sourceType: source.sourceType,
	      freeBusyTransparent: source.freeBusyTransparent ?? source.sourceType !== "caldav",
	      displayOrder: source.displayOrder ?? 0,
	      refreshIntervalMinutes: source.refreshIntervalMinutes ?? 15,
	      refreshPolicy: source.refreshPolicy ?? "manualAndInterval",
		      permissionsJson: source.permissionsJson ?? "",
		      sharePermissionsJson: source.sharePermissionsJson ?? "",
		      shareUsersJson: source.shareUsersJson ?? "",
		      shareGroupsJson: source.shareGroupsJson ?? "",
		      publicShareUrl: source.publicShareUrl ?? "",
		      publicShareToken: source.publicShareToken ?? "",
			      supportedReportsJson: source.supportedReportsJson ?? "",
			      supportedComponentsJson: source.supportedComponentsJson ?? "",
			      discoveryTraceJson: source.discoveryTraceJson ?? "",
			      capabilitySource: source.capabilitySource ?? "",
			      lastDiscoveryError: source.lastDiscoveryError ?? "",
	      providerType: source.providerType ?? inferCalendarProviderType(source.collectionUrl),
	      providerPresetJson: source.providerPresetJson ?? "",
	      syncStrategy: source.syncStrategy ?? "",
	      externalProviderId: source.externalProviderId ?? "",
	      nativeCalendarId: source.nativeCalendarId ?? "",
	      nativeCalendarSyncState: source.nativeCalendarSyncState ?? "",
	      widgetConfigJson: source.widgetConfigJson ?? "",
	      providerAdapterType: source.providerAdapterType ?? "",
	      sourceLoadingState: source.sourceLoadingState ?? "idle",
	      lastLoadedRangeStart: source.lastLoadedRangeStart ?? 0,
	      lastLoadedRangeEnd: source.lastLoadedRangeEnd ?? 0,
		      subscriptionEtag: source.subscriptionEtag ?? "",
		      subscriptionLastModified: source.subscriptionLastModified ?? "",
		      ctag: source.ctag ?? "",
		      syncToken: source.syncToken ?? "",
		      lastSuccessfulSyncAt: source.lastSuccessfulSyncAt ?? 0,
		      lastSyncAt: source.lastSyncAt ?? 0,
		      lastSyncHttpStatus: source.lastSyncHttpStatus ?? 0,
		      retryAfterSeconds: source.retryAfterSeconds ?? 0,
		      lastSyncDiagnosticJson: source.lastSyncDiagnosticJson ?? "",
		      lastSyncError: source.lastSyncError ?? ""
		    };

    if (saved.isDefault) {
      await this.requireStore().executeSql(`UPDATE ${SOURCE_TABLE} SET is_default = 0`);
    }

    await this.requireStore().executeSql(`DELETE FROM ${SOURCE_TABLE} WHERE id = '${escapeSql(id)}'`);
    await this.requireStore().insert(SOURCE_TABLE, this.sourceToBucket(saved));
    return saved;
  }

  async updateSourceVisibility(sourceId: string, isVisible: boolean): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET is_visible = ${isVisible ? 1 : 0}, updated_at = ${Date.now()} WHERE id = '${escapeSql(sourceId)}'`
    );
  }

  async updateSourceRefreshPolicy(sourceId: string, refreshIntervalMinutes: number, refreshPolicy: string): Promise<void> {
    await this.init();
    const interval: number = Math.max(0, Math.floor(refreshIntervalMinutes));
    const policy: string = refreshPolicy === "manualOnly" ? "manualOnly" : "manualAndInterval";
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET refresh_interval_minutes = ${interval}, refresh_policy = '${escapeSql(policy)}', ` +
        `updated_at = ${Date.now()} WHERE id = '${escapeSql(sourceId)}'`
    );
  }

  async updateSourceMetadata(sourceId: string, name: string, color: string): Promise<void> {
    await this.init();
    const normalizedColor: string = normalizeColor(color);
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET name = '${escapeSql(name.trim().length > 0 ? name.trim() : "CalDAV 日历")}', ` +
        `color = '${escapeSql(normalizedColor)}', background_color = '${escapeSql(normalizedColor)}', ` +
        `border_color = '${escapeSql(normalizedColor)}', text_color = '#FFFFFF', updated_at = ${Date.now()} ` +
        `WHERE id = '${escapeSql(sourceId)}'`
    );
  }

  async updateSourceSharePermissions(sourceId: string, sharePermissionsJson: string): Promise<void> {
    await this.init();
    const shareUsersJson: string = this.shareUsersJsonFromPermissions(sharePermissionsJson);
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET share_permissions_json = '${escapeSql(sharePermissionsJson)}', ` +
        `share_users_json = '${escapeSql(shareUsersJson)}', updated_at = ${Date.now()} ` +
        `WHERE id = '${escapeSql(sourceId)}'`
    );
  }

  async loadViewConfig(): Promise<CalendarViewConfig> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(VIEW_CONFIG_TABLE);
    predicates.equalTo("id", "default");
    predicates.limitAs(1);
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, VIEW_CONFIG_COLUMNS);

    try {
      if (resultSet.goToNextRow()) {
        return this.readViewConfig(resultSet);
      }
    } finally {
      resultSet.close();
    }

    return this.defaultViewConfig();
  }

  async saveViewConfig(config: CalendarViewConfig): Promise<CalendarViewConfig> {
    await this.init();
    const saved: CalendarViewConfig = this.normalizeViewConfig(config);
    await this.requireStore().executeSql(`DELETE FROM ${VIEW_CONFIG_TABLE} WHERE id = '${escapeSql(saved.id ?? "default")}'`);
    await this.requireStore().insert(VIEW_CONFIG_TABLE, this.viewConfigToBucket(saved));
    return saved;
  }

  async listDateMarkers(startAt: number, endAt: number): Promise<CalendarDateMarker[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(DATE_MARKER_TABLE);
    predicates.greaterThanOrEqualTo("marker_date", startOfDayValue(startAt));
    predicates.lessThan("marker_date", startOfDayValue(endAt));
    predicates.orderByAsc("marker_date");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, DATE_MARKER_COLUMNS);

    try {
      const items: CalendarDateMarker[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readDateMarker(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async upsertDateMarker(marker: CalendarDateMarker): Promise<CalendarDateMarker> {
    await this.init();
    const saved: CalendarDateMarker = this.normalizeDateMarker(marker);
    await this.requireStore().executeSql(`DELETE FROM ${DATE_MARKER_TABLE} WHERE id = '${escapeSql(saved.id ?? "")}'`);
    await this.requireStore().insert(DATE_MARKER_TABLE, this.dateMarkerToBucket(saved));
    return saved;
  }

  async removeDateMarker(markerId: string): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(`DELETE FROM ${DATE_MARKER_TABLE} WHERE id = '${escapeSql(markerId)}'`);
  }

  async listResources(sourceId: string = ""): Promise<CalendarResource[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(RESOURCE_TABLE);
    if (sourceId.length > 0) {
      predicates.equalTo("source_id", sourceId);
    }
    predicates.orderByAsc("resource_type");
    predicates.orderByAsc("name");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, RESOURCE_COLUMNS);

    try {
      const items: CalendarResource[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readResource(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async upsertResource(resource: CalendarResource): Promise<CalendarResource> {
    await this.init();
    const saved: CalendarResource = this.normalizeResource(resource);
    await this.requireStore().executeSql(`DELETE FROM ${RESOURCE_TABLE} WHERE id = '${escapeSql(saved.id ?? "")}'`);
    await this.requireStore().insert(RESOURCE_TABLE, this.resourceToBucket(saved));
    return saved;
  }

  async removeResource(resourceId: string): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(`DELETE FROM ${RESOURCE_TABLE} WHERE id = '${escapeSql(resourceId)}'`);
  }

  async removeSource(sourceId: string): Promise<void> {
    await this.init();
    const sources: CalendarSource[] = await this.listSources();
    const removed: CalendarSource | undefined = sources.find((source: CalendarSource) => (source.id ?? "") === sourceId);
    if (removed === undefined) {
      return;
    }

    await this.requireStore().executeSql(`DELETE FROM ${EVENT_TABLE} WHERE source_id = '${escapeSql(sourceId)}'`);
    await this.requireStore().executeSql(`DELETE FROM ${RESOURCE_TABLE} WHERE source_id = '${escapeSql(sourceId)}'`);
    await this.requireStore().executeSql(`DELETE FROM ${SOURCE_TABLE} WHERE id = '${escapeSql(sourceId)}'`);

    if (removed.isDefault) {
      const remaining: CalendarSource[] = (await this.listSources()).filter((source: CalendarSource) => !source.isReadOnly);
      if (remaining.length > 0 && (remaining[0].id ?? "").length > 0) {
        await this.setDefaultSource(remaining[0].id ?? "");
      }
    }
  }

  async setDefaultSource(sourceId: string): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(`UPDATE ${SOURCE_TABLE} SET is_default = 0`);
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET is_default = 1, updated_at = ${Date.now()} WHERE id = '${escapeSql(sourceId)}'`
    );
  }

	  async saveSourceSyncState(
	    sourceId: string,
	    syncToken: string,
	    ctag: string,
	    error: string,
	    syncStrategy: string = "",
	    httpStatus: number = 0,
	    retryAfterSeconds: number = 0,
	    diagnosticJson: string = ""
	  ): Promise<void> {
		    await this.init();
		    const successAtSql: string = error.length === 0 ? `last_successful_sync_at = ${Date.now()}, ` : "";
		    const strategySql: string = syncStrategy.length > 0 ? `sync_strategy = '${escapeSql(syncStrategy)}', ` : "";
		    const loadingState: string = error.length === 0 ? "idle" : "error";
		    await this.requireStore().executeSql(
		      `UPDATE ${SOURCE_TABLE} SET sync_token = '${escapeSql(syncToken)}', ctag = '${escapeSql(ctag)}', ` +
		        successAtSql +
		        strategySql +
		        `source_loading_state = '${loadingState}', last_sync_at = ${Date.now()}, ` +
		        `last_sync_http_status = ${Math.max(0, Math.floor(httpStatus))}, ` +
		        `retry_after_seconds = ${Math.max(0, Math.floor(retryAfterSeconds))}, ` +
		        `last_sync_diagnostic_json = '${escapeSql(diagnosticJson)}', ` +
		        `last_sync_error = '${escapeSql(error)}', updated_at = ${Date.now()} ` +
		        `WHERE id = '${escapeSql(sourceId)}'`
		    );
		  }

	  async saveSubscriptionSyncState(
	    sourceId: string,
	    etag: string,
	    lastModified: string,
	    error: string,
	    httpStatus: number = 0,
	    retryAfterSeconds: number = 0,
	    diagnosticJson: string = ""
	  ): Promise<void> {
	    await this.init();
	    const successAtSql: string = error.length === 0 ? `last_successful_sync_at = ${Date.now()}, ` : "";
	    const loadingState: string = error.length === 0 ? "idle" : "error";
	    await this.requireStore().executeSql(
	      `UPDATE ${SOURCE_TABLE} SET subscription_etag = '${escapeSql(etag)}', ` +
	        `subscription_last_modified = '${escapeSql(lastModified)}', ` +
	        successAtSql +
	        `source_loading_state = '${loadingState}', last_sync_at = ${Date.now()}, ` +
	        `last_sync_http_status = ${Math.max(0, Math.floor(httpStatus))}, ` +
	        `retry_after_seconds = ${Math.max(0, Math.floor(retryAfterSeconds))}, ` +
	        `last_sync_diagnostic_json = '${escapeSql(diagnosticJson)}', ` +
	        `last_sync_error = '${escapeSql(error)}', updated_at = ${Date.now()} ` +
	        `WHERE id = '${escapeSql(sourceId)}'`
	    );
	  }

  async markSourceLoading(sourceId: string, state: string, rangeStart: number = 0, rangeEnd: number = 0): Promise<void> {
    await this.init();
    const loadingState: string = state === "loading" || state === "error" ? state : "idle";
    const rangeSql: string = rangeStart > 0 || rangeEnd > 0 ?
      `last_loaded_range_start = ${Math.max(0, Math.floor(rangeStart))}, last_loaded_range_end = ${Math.max(0, Math.floor(rangeEnd))}, ` : "";
    await this.requireStore().executeSql(
      `UPDATE ${SOURCE_TABLE} SET source_loading_state = '${loadingState}', ${rangeSql}` +
        `updated_at = ${Date.now()} WHERE id = '${escapeSql(sourceId)}'`
    );
  }

  async activateAccount(id: string): Promise<void> {
    await this.init();
    const store: relationalStore.RdbStore = this.requireStore();
    await store.executeSql(`UPDATE ${CALDAV_ACCOUNT_TABLE} SET is_active = 0`);
    await store.executeSql(
      `UPDATE ${CALDAV_ACCOUNT_TABLE} SET is_active = 1, updated_at = ${Date.now()} WHERE id = '${escapeSql(id)}'`
    );
  }

  async removeAccount(id: string): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(`DELETE FROM ${CALDAV_ACCOUNT_TABLE} WHERE id = '${escapeSql(id)}'`);
  }

  async clearAccount(): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(`DELETE FROM ${ACCOUNT_TABLE}`);
  }

  async listEvents(includeDeleted: boolean = false): Promise<CalendarEvent[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(EVENT_TABLE);
    if (!includeDeleted) {
      predicates.notEqualTo("sync_status", "deleted");
    }
    predicates.orderByAsc("start_at");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, EVENT_COLUMNS);

    try {
      const items: CalendarEvent[] = [];

      while (resultSet.goToNextRow()) {
        items.push(this.readEvent(resultSet));
      }

      return items;
    } finally {
      resultSet.close();
    }
  }

  async listDirtyEvents(sourceId: string = ""): Promise<CalendarEvent[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(EVENT_TABLE);
    predicates.equalTo("sync_status", "dirty");
    if (sourceId.length > 0) {
      predicates.equalTo("source_id", sourceId);
    }
    predicates.orderByAsc("updated_at");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, EVENT_COLUMNS);

    try {
      const items: CalendarEvent[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readEvent(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async listDeletedEvents(sourceId: string = ""): Promise<CalendarEvent[]> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(EVENT_TABLE);
    predicates.equalTo("sync_status", "deleted");
    if (sourceId.length > 0) {
      predicates.equalTo("source_id", sourceId);
    }
    predicates.orderByAsc("updated_at");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, EVENT_COLUMNS);

    try {
      const items: CalendarEvent[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readEvent(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  async removeCleanEventsMissingFromRemote(remoteIds: string[], sourceId: string = ""): Promise<number> {
    await this.init();
    const events: CalendarEvent[] = await this.listEvents(false);
    let removed: number = 0;

    for (const event of events) {
      if ((sourceId.length === 0 || event.sourceId === sourceId) && event.syncStatus === "clean" && remoteIds.indexOf(event.id) < 0) {
        await this.deleteById(event.id);
        removed += 1;
      }
    }

    return removed;
  }

	  async upsertRemoteEvent(event: CalendarEvent, sourceId: string = ""): Promise<void> {
	    await this.init();
	    const store: relationalStore.RdbStore = this.requireStore();
	    const existing: CalendarEvent | null = await this.findEventById(event.id);

	    if (existing !== null && existing.syncStatus === "dirty") {
	      if ((existing.etag ?? "") !== (event.etag ?? "") && (event.etag ?? "").length > 0) {
	        await this.markConflict(existing, event, "localDirtyRemoteChanged");
	      }
	      return;
	    }

    if (existing !== null && existing.syncStatus === "deleted") {
      return;
    }

	    await this.deleteById(event.id);
	    const cleanEvent: CalendarEvent = this.copyEvent(event, event.href, event.etag, event.lastModified, "clean", sourceId.length > 0 ? sourceId : event.sourceId);
	    await store.insert(EVENT_TABLE, this.toBucket(cleanEvent));
	  }

	  async markConflict(local: CalendarEvent, remote: CalendarEvent, status: CalendarConflictStatus): Promise<void> {
	    await this.init();
		    const conflictEvent: CalendarEvent = {
		      id: local.id,
		      sourceId: local.sourceId,
		      eventSourceId: local.eventSourceId ?? local.sourceId,
	      uid: local.uid,
	      href: local.href,
	      etag: local.etag,
	      title: local.title,
	      startAt: local.startAt,
	      endAt: local.endAt,
	      allDay: local.allDay,
	      location: local.location,
	      notes: local.notes,
	      reminderMinutes: local.reminderMinutes,
	      secondReminderMinutes: local.secondReminderMinutes,
	      rrule: local.rrule,
	      categoryColor: local.categoryColor,
	      eventKind: local.eventKind,
	      url: local.url,
	      attendees: local.attendees,
	      attendeeJson: local.attendeeJson,
	      organizerName: local.organizerName,
	      organizerEmail: local.organizerEmail,
		      conferenceUrl: local.conferenceUrl,
		      attachmentUrl: local.attachmentUrl,
		      attachmentsJson: local.attachmentsJson,
		      travelMinutes: local.travelMinutes,
				      comingDuration: local.comingDuration,
				      availability: local.availability,
				      freeBusyTransparent: local.freeBusyTransparent,
				      eventCategory: local.eventCategory,
				      privacy: local.privacy,
		      timeZone: local.timeZone,
		      eventStatus: local.eventStatus,
		      appointmentStatus: local.appointmentStatus,
		      appointmentCapacity: local.appointmentCapacity,
		      appointmentBookedCount: local.appointmentBookedCount,
		      appointmentMinDurationMinutes: local.appointmentMinDurationMinutes,
		      appointmentMaxDurationMinutes: local.appointmentMaxDurationMinutes,
		      appointmentBufferBeforeMinutes: local.appointmentBufferBeforeMinutes,
		      appointmentBufferAfterMinutes: local.appointmentBufferAfterMinutes,
		      appointmentDeadlineMinutes: local.appointmentDeadlineMinutes,
		      appointmentPublicUrl: local.appointmentPublicUrl,
		      appointmentFormJson: local.appointmentFormJson,
		      appointmentTimezone: local.appointmentTimezone,
		      appointmentSlotIntervalMinutes: local.appointmentSlotIntervalMinutes,
		      appointmentApprovalRequired: local.appointmentApprovalRequired,
		      bookingJson: local.bookingJson,
		      bookingContactName: local.bookingContactName,
		      bookingContactEmail: local.bookingContactEmail,
		      bookingContactPhone: local.bookingContactPhone,
		      bookingConfirmationStatus: local.bookingConfirmationStatus,
		      bookingStatus: local.bookingStatus,
		      exdate: local.exdate,
	      rdate: local.rdate,
	      recurrenceId: local.recurrenceId,
	      sequence: local.sequence,
	      reminderOffsets: local.reminderOffsets,
	      dueAt: local.dueAt,
	      completedAt: local.completedAt,
		      priority: local.priority,
		      percentComplete: local.percentComplete,
			      backgroundColor: local.backgroundColor,
			      borderColor: local.borderColor,
			      textColor: local.textColor,
			      dragBackgroundColor: local.dragBackgroundColor,
			      milestoneStatus: local.milestoneStatus,
			      dueDateClass: local.dueDateClass,
			      groupId: local.groupId,
			      displayMode: local.displayMode,
			      overlap: local.overlap,
			      editable: local.editable,
			      startEditable: local.startEditable,
			      durationEditable: local.durationEditable,
			      resourceEditable: local.resourceEditable,
			      interactive: local.interactive,
			      eventReadOnly: local.eventReadOnly,
			      isVisible: local.isVisible,
			      isPending: local.isPending,
			      isFocused: local.isFocused,
			      overlapPosition: local.overlapPosition,
			      overlapCount: local.overlapCount,
			      classNames: local.classNames,
			      customStyleJson: local.customStyleJson,
			      constraintJson: local.constraintJson,
			      extendedPropsJson: local.extendedPropsJson,
			      rawPropsJson: local.rawPropsJson,
			      resourceIdsJson: local.resourceIdsJson,
		      roomIdsJson: local.roomIdsJson,
		      resourceStatusJson: local.resourceStatusJson,
		      alarmAction: local.alarmAction,
		      snoozeMinutes: local.snoozeMinutes,
		      snoozeTimes: local.snoozeTimes,
		      allDayReminderAt: local.allDayReminderAt,
		      alarmActionsJson: local.alarmActionsJson,
		      reminderId: local.reminderId,
	      lastModified: local.lastModified,
	      syncStatus: local.syncStatus,
	      conflictStatus: status,
		      conflictJson: JSON.stringify({
		        detectedAt: Date.now(),
		        remoteEvent: remote
		      })
		    };
		    await this.saveLocalEvent(conflictEvent);
		  }

  async resolveConflictUseLocal(event: CalendarEvent): Promise<void> {
    await this.init();
    const remote: CalendarEvent | null = this.remoteEventFromConflict(event.conflictJson ?? "");
    const eventForPush: CalendarEvent = remote === null ? event : {
  id: event.id, uid: event.uid, sourceId: event.sourceId, href: remote.href.length > 0 ? remote.href : event.href,
  etag: remote.etag, title: event.title, startAt: event.startAt, endAt: event.endAt,
  allDay: event.allDay, location: event.location, notes: event.notes,
  reminderMinutes: event.reminderMinutes, secondReminderMinutes: event.secondReminderMinutes, syncStatus: event.syncStatus,
  lastModified: event.lastModified, rrule: event.rrule ?? "", categoryColor: event.categoryColor ?? "",
  backgroundColor: event.backgroundColor ?? "", borderColor: event.borderColor ?? "",
  textColor: event.textColor ?? "", dragBackgroundColor: event.dragBackgroundColor ?? "",
  eventCategory: event.eventCategory ?? "", eventKind: event.eventKind ?? "calendar",
  eventSourceId: event.eventSourceId ?? "", url: event.url ?? "", attendees: event.attendees ?? "",
  attendeeJson: event.attendeeJson ?? "", organizerName: event.organizerName ?? "",
  organizerEmail: event.organizerEmail ?? "", conferenceUrl: event.conferenceUrl ?? "",
  attachmentUrl: event.attachmentUrl ?? "", attachmentsJson: event.attachmentsJson ?? "",
  travelMinutes: event.travelMinutes ?? 0, comingDuration: event.comingDuration ?? 0,
  availability: event.availability ?? "busy", freeBusyTransparent: event.freeBusyTransparent ?? false,
  rawPropsJson: event.rawPropsJson ?? "", snoozeMinutes: event.snoozeMinutes ?? 0,
  snoozeTimes: event.snoozeTimes ?? 0, reminderId: event.reminderId ?? 0,
  conflictStatus: event.conflictStatus, conflictJson: event.conflictJson ?? ""
} as CalendarEvent;
    const nextStatus: CalendarSyncStatus = event.syncStatus === "deleted" ? "deleted" : "dirty";
    const resolved: CalendarEvent = this.copyResolvedEvent(eventForPush, nextStatus, Date.now(), event.sourceId);
    await this.saveLocalEvent(resolved);
  }

  async resolveConflictUseRemote(event: CalendarEvent): Promise<void> {
    await this.init();
    const remote: CalendarEvent | null = this.remoteEventFromConflict(event.conflictJson ?? "");
    if (remote === null) {
      await this.resolveConflictUseLocal(event);
      return;
    }

    const resolved: CalendarEvent = this.copyResolvedEvent(remote, "clean", remote.lastModified, event.sourceId);
    await this.saveLocalEvent(resolved);
  }

  async saveSyncedEvent(event: CalendarEvent, href: string, etag: string): Promise<void> {
    await this.init();
    await this.deleteById(event.id);
    const syncedEvent: CalendarEvent = this.copyEvent(event, href, etag, Date.now(), "clean", event.sourceId);
    await this.requireStore().insert(EVENT_TABLE, this.toBucket(syncedEvent));
  }

  async saveLocalEvent(event: CalendarEvent): Promise<void> {
    await this.init();
    await this.deleteById(event.id);
    await this.requireStore().insert(EVENT_TABLE, this.toBucket(event));
  }

  async createDraft(draft: CalendarEventDraft, href: string = ""): Promise<CalendarEvent> {
    await this.init();
    const sourceId: string = await this.resolveDraftSourceId(draft.sourceId ?? "");
	    const event: CalendarEvent = {
	      id: createLocalId("event"),
	      sourceId,
	      eventSourceId: draft.eventSourceId ?? sourceId,
      uid: createEventUid(),
      href,
      etag: "",
      title: draft.title,
      startAt: draft.startAt,
      endAt: draft.endAt,
      allDay: draft.allDay,
      location: draft.location,
      notes: draft.notes,
      reminderMinutes: draft.reminderMinutes ?? 0,
      secondReminderMinutes: draft.secondReminderMinutes ?? 0,
      rrule: draft.rrule ?? "",
      categoryColor: draft.categoryColor ?? "#2563EB",
      backgroundColor: draft.backgroundColor ?? "",
      borderColor: draft.borderColor ?? "",
      textColor: draft.textColor ?? "",
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
		      freeBusyTransparent: draft.freeBusyTransparent ?? (draft.availability ?? "busy") === "free",
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
      reminderOffsets: draft.reminderOffsets ?? this.defaultReminderOffsets(draft.reminderMinutes ?? 0, draft.secondReminderMinutes ?? 0),
      dueAt: draft.dueAt ?? 0,
      completedAt: draft.completedAt ?? 0,
		      priority: draft.priority ?? 0,
		      percentComplete: draft.percentComplete ?? 0,
			      milestoneStatus: draft.milestoneStatus ?? "",
			      dueDateClass: draft.dueDateClass ?? "",
			      groupId: draft.groupId ?? "",
			      displayMode: draft.displayMode ?? "",
			      overlap: draft.overlap ?? true,
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
	      syncStatus: "dirty",
	      conflictStatus: "none",
	      conflictJson: ""
    };
    await this.requireStore().insert(EVENT_TABLE, this.toBucket(event));
    return event;
  }

  async updateLocalEvent(event: CalendarEvent, draft: CalendarEventDraft): Promise<CalendarEvent> {
    await this.init();
    const sourceId: string = draft.sourceId !== undefined && draft.sourceId.length > 0 ? draft.sourceId : event.sourceId;
	    const updated: CalendarEvent = {
	      id: event.id,
	      sourceId,
	      eventSourceId: draft.eventSourceId ?? event.eventSourceId ?? sourceId,
      uid: event.uid,
      href: event.href,
      etag: event.etag,
      title: draft.title,
      startAt: draft.startAt,
      endAt: draft.endAt,
      allDay: draft.allDay,
      location: draft.location,
      notes: draft.notes,
      reminderMinutes: draft.reminderMinutes ?? 0,
      secondReminderMinutes: draft.secondReminderMinutes ?? 0,
      rrule: draft.rrule ?? "",
      categoryColor: draft.categoryColor ?? event.categoryColor ?? "#2563EB",
      backgroundColor: draft.backgroundColor ?? event.backgroundColor ?? "",
      borderColor: draft.borderColor ?? event.borderColor ?? "",
      textColor: draft.textColor ?? event.textColor ?? "",
      dragBackgroundColor: draft.dragBackgroundColor ?? event.dragBackgroundColor ?? "",
      eventCategory: draft.eventCategory ?? event.eventCategory ?? "",
      eventKind: draft.eventKind ?? event.eventKind ?? "calendar",
      url: draft.url ?? event.url ?? "",
      attendees: draft.attendees ?? event.attendees ?? "",
      attendeeJson: draft.attendeeJson ?? event.attendeeJson ?? "",
      organizerName: draft.organizerName ?? event.organizerName ?? "",
      organizerEmail: draft.organizerEmail ?? event.organizerEmail ?? "",
	      conferenceUrl: draft.conferenceUrl ?? event.conferenceUrl ?? "",
	      attachmentUrl: draft.attachmentUrl ?? event.attachmentUrl ?? "",
	      attachmentsJson: draft.attachmentsJson ?? event.attachmentsJson ?? "",
	      travelMinutes: draft.travelMinutes ?? event.travelMinutes ?? 0,
		      comingDuration: draft.comingDuration ?? event.comingDuration ?? 0,
		      availability: draft.availability ?? event.availability ?? "busy",
		      freeBusyTransparent: draft.freeBusyTransparent ?? event.freeBusyTransparent ?? (draft.availability ?? event.availability ?? "busy") === "free",
		      privacy: draft.privacy ?? event.privacy ?? "default",
	      timeZone: draft.timeZone ?? event.timeZone ?? "",
	      eventStatus: draft.eventStatus ?? event.eventStatus ?? "confirmed",
	      appointmentStatus: draft.appointmentStatus ?? event.appointmentStatus ?? "available",
	      appointmentCapacity: draft.appointmentCapacity ?? event.appointmentCapacity ?? 1,
	      appointmentBookedCount: draft.appointmentBookedCount ?? event.appointmentBookedCount ?? 0,
	      appointmentMinDurationMinutes: draft.appointmentMinDurationMinutes ?? event.appointmentMinDurationMinutes ?? 0,
	      appointmentMaxDurationMinutes: draft.appointmentMaxDurationMinutes ?? event.appointmentMaxDurationMinutes ?? 0,
	      appointmentBufferBeforeMinutes: draft.appointmentBufferBeforeMinutes ?? event.appointmentBufferBeforeMinutes ?? 0,
	      appointmentBufferAfterMinutes: draft.appointmentBufferAfterMinutes ?? event.appointmentBufferAfterMinutes ?? 0,
	      appointmentDeadlineMinutes: draft.appointmentDeadlineMinutes ?? event.appointmentDeadlineMinutes ?? 0,
	      appointmentPublicUrl: draft.appointmentPublicUrl ?? event.appointmentPublicUrl ?? "",
	      appointmentFormJson: draft.appointmentFormJson ?? event.appointmentFormJson ?? "",
	      appointmentTimezone: draft.appointmentTimezone ?? event.appointmentTimezone ?? "",
	      appointmentSlotIntervalMinutes: draft.appointmentSlotIntervalMinutes ?? event.appointmentSlotIntervalMinutes ?? 0,
	      appointmentApprovalRequired: draft.appointmentApprovalRequired ?? event.appointmentApprovalRequired ?? false,
	      bookingJson: draft.bookingJson ?? event.bookingJson ?? "",
	      bookingContactName: draft.bookingContactName ?? event.bookingContactName ?? "",
	      bookingContactEmail: draft.bookingContactEmail ?? event.bookingContactEmail ?? "",
	      bookingContactPhone: draft.bookingContactPhone ?? event.bookingContactPhone ?? "",
	      bookingConfirmationStatus: draft.bookingConfirmationStatus ?? event.bookingConfirmationStatus ?? "",
	      bookingStatus: draft.bookingStatus ?? event.bookingStatus ?? "",
	      exdate: draft.exdate ?? event.exdate ?? "",
      rdate: draft.rdate ?? event.rdate ?? "",
      recurrenceId: draft.recurrenceId ?? event.recurrenceId ?? "",
      sequence: draft.sequence ?? event.sequence ?? 0,
      reminderOffsets: draft.reminderOffsets ?? event.reminderOffsets ?? this.defaultReminderOffsets(draft.reminderMinutes ?? 0, draft.secondReminderMinutes ?? 0),
      dueAt: draft.dueAt ?? event.dueAt ?? 0,
      completedAt: draft.completedAt ?? event.completedAt ?? 0,
		      priority: draft.priority ?? event.priority ?? 0,
		      percentComplete: draft.percentComplete ?? event.percentComplete ?? 0,
			      milestoneStatus: draft.milestoneStatus ?? event.milestoneStatus ?? "",
			      dueDateClass: draft.dueDateClass ?? event.dueDateClass ?? "",
			      groupId: draft.groupId ?? event.groupId ?? "",
			      displayMode: draft.displayMode ?? event.displayMode ?? "",
			      overlap: draft.overlap ?? event.overlap ?? true,
			      editable: draft.editable ?? event.editable ?? true,
			      startEditable: draft.startEditable ?? event.startEditable ?? true,
			      durationEditable: draft.durationEditable ?? event.durationEditable ?? true,
			      resourceEditable: draft.resourceEditable ?? event.resourceEditable ?? true,
			      interactive: draft.interactive ?? event.interactive ?? true,
			      eventReadOnly: draft.eventReadOnly ?? event.eventReadOnly ?? false,
			      isVisible: draft.isVisible ?? event.isVisible ?? true,
			      isPending: draft.isPending ?? event.isPending ?? false,
			      isFocused: draft.isFocused ?? event.isFocused ?? false,
			      overlapPosition: draft.overlapPosition ?? event.overlapPosition ?? 0,
			      overlapCount: draft.overlapCount ?? event.overlapCount ?? 1,
			      classNames: draft.classNames ?? event.classNames ?? "",
			      customStyleJson: draft.customStyleJson ?? event.customStyleJson ?? "",
			      constraintJson: draft.constraintJson ?? event.constraintJson ?? "",
			      extendedPropsJson: draft.extendedPropsJson ?? event.extendedPropsJson ?? "",
			      rawPropsJson: draft.rawPropsJson ?? event.rawPropsJson ?? "",
			      resourceIdsJson: draft.resourceIdsJson ?? event.resourceIdsJson ?? "",
		      roomIdsJson: draft.roomIdsJson ?? event.roomIdsJson ?? "",
		      resourceStatusJson: draft.resourceStatusJson ?? event.resourceStatusJson ?? "",
		      alarmAction: draft.alarmAction ?? event.alarmAction ?? "",
		      snoozeMinutes: draft.snoozeMinutes ?? event.snoozeMinutes ?? 0,
		      snoozeTimes: draft.snoozeTimes ?? event.snoozeTimes ?? 0,
		      allDayReminderAt: draft.allDayReminderAt ?? event.allDayReminderAt ?? "",
		      alarmActionsJson: draft.alarmActionsJson ?? event.alarmActionsJson ?? "",
		      lastModified: Date.now(),
	      syncStatus: "dirty",
	      conflictStatus: "none",
	      conflictJson: ""
    };
    await this.deleteById(event.id);
    await this.requireStore().insert(EVENT_TABLE, this.toBucket(updated));
    return updated;
  }

  async markDeleted(event: CalendarEvent): Promise<void> {
    await this.init();
    if (event.href.length === 0 || event.etag.length === 0) {
      await this.deleteById(event.id);
      return;
    }

    await this.deleteById(event.id);
    const deletedEvent: CalendarEvent = this.copyEvent(event, event.href, event.etag, Date.now(), "deleted", event.sourceId);
    await this.requireStore().insert(EVENT_TABLE, this.toBucket(deletedEvent));
  }

  async removeEvent(id: string): Promise<void> {
    await this.init();
    await this.deleteById(id);
  }

  async findEventById(id: string): Promise<CalendarEvent | null> {
    await this.init();
    const predicates = new relationalStore.RdbPredicates(EVENT_TABLE);
    predicates.equalTo("id", id);
    predicates.limitAs(1);
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, EVENT_COLUMNS);

    try {
      if (!resultSet.goToNextRow()) {
        return null;
      }

      return this.readEvent(resultSet);
    } finally {
      resultSet.close();
    }
  }

  private async openAndMigrate(): Promise<void> {
    this.store = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
    const store: relationalStore.RdbStore = this.requireStore();
    await store.executeSql(CREATE_ACCOUNT_TABLE_SQL);
    await store.executeSql(CREATE_CALDAV_ACCOUNT_TABLE_SQL);
    await store.executeSql(CREATE_SOURCE_TABLE_SQL);
	    await store.executeSql(CREATE_EVENT_TABLE_SQL);
	    await store.executeSql(CREATE_VIEW_CONFIG_TABLE_SQL);
	    await store.executeSql(CREATE_DATE_MARKER_TABLE_SQL);
	    await store.executeSql(CREATE_RESOURCE_TABLE_SQL);
	    await this.migrateLegacyAccount();
	    await this.ensureSourceColumn("description", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("subscription_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("principal_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("home_set_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("schedule_inbox_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("schedule_outbox_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("calendar_user_address_set", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("owner_email", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureSourceColumn("background_color", "TEXT NOT NULL DEFAULT '#2563EB'");
	    await this.ensureSourceColumn("border_color", "TEXT NOT NULL DEFAULT '#2563EB'");
		    await this.ensureSourceColumn("display_order", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureSourceColumn("refresh_interval_minutes", "INTEGER NOT NULL DEFAULT 15");
		    await this.ensureSourceColumn("refresh_policy", "TEXT NOT NULL DEFAULT 'manualAndInterval'");
		    await this.ensureSourceColumn("permissions_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("share_permissions_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("share_users_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("share_groups_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("public_share_url", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("public_share_token", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("supported_reports_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureSourceColumn("supported_components_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("provider_type", "TEXT NOT NULL DEFAULT 'custom'");
				    await this.ensureSourceColumn("discovery_trace_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("capability_source", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("last_discovery_error", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("provider_preset_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureSourceColumn("sync_strategy", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureSourceColumn("external_provider_id", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureSourceColumn("native_calendar_id", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureSourceColumn("native_calendar_sync_state", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("widget_config_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("provider_adapter_type", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureSourceColumn("source_loading_state", "TEXT NOT NULL DEFAULT 'idle'");
				    await this.ensureSourceColumn("last_loaded_range_start", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureSourceColumn("last_loaded_range_end", "INTEGER NOT NULL DEFAULT 0");
					    await this.ensureSourceColumn("subscription_etag", "TEXT NOT NULL DEFAULT ''");
					    await this.ensureSourceColumn("subscription_last_modified", "TEXT NOT NULL DEFAULT ''");
					    await this.ensureSourceColumn("last_successful_sync_at", "INTEGER NOT NULL DEFAULT 0");
					    await this.ensureSourceColumn("last_sync_http_status", "INTEGER NOT NULL DEFAULT 0");
					    await this.ensureSourceColumn("retry_after_seconds", "INTEGER NOT NULL DEFAULT 0");
					    await this.ensureSourceColumn("last_sync_diagnostic_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureViewConfigColumn("week_ends_on", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureViewConfigColumn("show_six_weeks", "INTEGER NOT NULL DEFAULT 1");
	    await this.ensureViewConfigColumn("show_adjacent_months", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureViewConfigColumn("now_indicator_visible", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureViewConfigColumn("scroll_offset_minutes", "INTEGER NOT NULL DEFAULT 480");
		    await this.ensureViewConfigColumn("hour_row_height", "INTEGER NOT NULL DEFAULT 56");
		    await this.ensureViewConfigColumn("event_min_height_for_month_view", "INTEGER NOT NULL DEFAULT 18");
		    await this.ensureViewConfigColumn("show_all_day_event_cell", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureViewConfigColumn("timeslots", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureViewConfigColumn("month_more_label", "TEXT NOT NULL DEFAULT '更多'");
	    await this.ensureViewConfigColumn("event_order", "TEXT NOT NULL DEFAULT 'start,title'");
	    await this.ensureViewConfigColumn("locale", "TEXT NOT NULL DEFAULT 'zh-CN'");
	    await this.ensureViewConfigColumn("hour_format", "TEXT NOT NULL DEFAULT '24h'");
	    await this.ensureViewConfigColumn("time_zone", "TEXT NOT NULL DEFAULT 'Asia/Shanghai'");
	    await this.ensureViewConfigColumn("enabled_views_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureViewConfigColumn("agenda_empty_text", "TEXT NOT NULL DEFAULT '当天没有日程'");
		    await this.ensureViewConfigColumn("agenda_group_mode", "TEXT NOT NULL DEFAULT 'day'");
		    await this.ensureViewConfigColumn("agenda_show_past_days", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("agenda_past_scroll_range", "INTEGER NOT NULL DEFAULT 6");
		    await this.ensureViewConfigColumn("agenda_future_scroll_range", "INTEGER NOT NULL DEFAULT 12");
		    await this.ensureViewConfigColumn("agenda_show_only_selected_day_items", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("theme_mode", "TEXT NOT NULL DEFAULT 'system'");
	    await this.ensureViewConfigColumn("default_reminder_minutes", "INTEGER NOT NULL DEFAULT 15");
	    await this.ensureViewConfigColumn("reminder_sound", "TEXT NOT NULL DEFAULT 'default'");
	    await this.ensureViewConfigColumn("reminder_vibrate", "INTEGER NOT NULL DEFAULT 1");
	    await this.ensureViewConfigColumn("event_kind_filter", "TEXT NOT NULL DEFAULT 'all'");
	    await this.ensureViewConfigColumn("source_filter_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureViewConfigColumn("hide_cancelled_events", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("show_incomplete_tasks_only", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("business_hours_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureViewConfigColumn("min_selectable_date", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("max_selectable_date", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("disabled_days_indexes_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureViewConfigColumn("display_loading_indicator", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureViewConfigColumn("loaded_date_ranges_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("attachments_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("coming_duration", "INTEGER NOT NULL DEFAULT 0");
			    await this.ensureEventColumn("background_color", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("border_color", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("text_color", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("drag_background_color", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("group_id", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("display_mode", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("overlap", "INTEGER NOT NULL DEFAULT 1");
			    await this.ensureEventColumn("editable", "INTEGER NOT NULL DEFAULT 1");
			    await this.ensureEventColumn("start_editable", "INTEGER NOT NULL DEFAULT 1");
			    await this.ensureEventColumn("duration_editable", "INTEGER NOT NULL DEFAULT 1");
			    await this.ensureEventColumn("resource_editable", "INTEGER NOT NULL DEFAULT 1");
				    await this.ensureEventColumn("interactive", "INTEGER NOT NULL DEFAULT 1");
				    await this.ensureEventColumn("event_read_only", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("is_visible", "INTEGER NOT NULL DEFAULT 1");
				    await this.ensureEventColumn("is_pending", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("is_focused", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("overlap_position", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("overlap_count", "INTEGER NOT NULL DEFAULT 1");
				    await this.ensureEventColumn("class_names", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("custom_style_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("constraint_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("extended_props_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("raw_props_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("resource_ids_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("appointment_status", "TEXT NOT NULL DEFAULT 'available'");
			    await this.ensureEventColumn("appointment_capacity", "INTEGER NOT NULL DEFAULT 1");
			    await this.ensureEventColumn("appointment_booked_count", "INTEGER NOT NULL DEFAULT 0");
			    await this.ensureEventColumn("appointment_min_duration_minutes", "INTEGER NOT NULL DEFAULT 0");
			    await this.ensureEventColumn("appointment_max_duration_minutes", "INTEGER NOT NULL DEFAULT 0");
			    await this.ensureEventColumn("appointment_buffer_before_minutes", "INTEGER NOT NULL DEFAULT 0");
			    await this.ensureEventColumn("appointment_buffer_after_minutes", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("appointment_deadline_minutes", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("appointment_public_url", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("appointment_form_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("appointment_timezone", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("appointment_slot_interval_minutes", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("appointment_approval_required", "INTEGER NOT NULL DEFAULT 0");
				    await this.ensureEventColumn("booking_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("booking_contact_name", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("booking_contact_email", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("booking_contact_phone", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("booking_confirmation_status", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("booking_status", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureEventColumn("room_ids_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("resource_status_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("alarm_action", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("snooze_minutes", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("snooze_times", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("all_day_reminder_at", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("alarm_actions_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureAccountColumn("provider_type", "TEXT NOT NULL DEFAULT 'custom'");
			    await this.ensureAccountColumn("provider_preset_json", "TEXT NOT NULL DEFAULT ''");
			    await this.ensureAccountColumn("auth_type", "TEXT NOT NULL DEFAULT 'basic'");
			    await this.ensureAccountColumn("bearer_token", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureAccountColumn("custom_headers_json", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("source_id", "TEXT NOT NULL DEFAULT ''");
				    await this.ensureEventColumn("event_source_id", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("reminder_minutes", "INTEGER NOT NULL DEFAULT 0");
    await this.ensureEventColumn("second_reminder_minutes", "INTEGER NOT NULL DEFAULT 0");
    await this.ensureEventColumn("rrule", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("category_color", "TEXT NOT NULL DEFAULT '#2563EB'");
    await this.ensureEventColumn("background_color", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("border_color", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("text_color", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("drag_background_color", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("event_category", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("event_kind", "TEXT NOT NULL DEFAULT 'calendar'");
    await this.ensureEventColumn("url", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("attendees", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("attendee_json", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("organizer_name", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("organizer_email", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("conference_url", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("attachment_url", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("travel_minutes", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("availability", "TEXT NOT NULL DEFAULT 'busy'");
	    await this.ensureEventColumn("free_busy_transparent", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("privacy", "TEXT NOT NULL DEFAULT 'default'");
	    await this.ensureEventColumn("time_zone", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("event_status", "TEXT NOT NULL DEFAULT 'confirmed'");
	    await this.ensureEventColumn("appointment_status", "TEXT NOT NULL DEFAULT 'available'");
	    await this.ensureEventColumn("appointment_capacity", "INTEGER NOT NULL DEFAULT 1");
	    await this.ensureEventColumn("appointment_booked_count", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("appointment_min_duration_minutes", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("appointment_max_duration_minutes", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("appointment_buffer_before_minutes", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("appointment_buffer_after_minutes", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("appointment_deadline_minutes", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("appointment_public_url", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("appointment_form_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("appointment_timezone", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("appointment_slot_interval_minutes", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("appointment_approval_required", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("booking_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("booking_contact_name", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("booking_contact_email", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("booking_contact_phone", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("booking_confirmation_status", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("booking_status", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("exdate", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("rdate", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("recurrence_id", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("sequence", "INTEGER NOT NULL DEFAULT 0");
    await this.ensureEventColumn("reminder_offsets", "TEXT NOT NULL DEFAULT ''");
    await this.ensureEventColumn("due_at", "INTEGER NOT NULL DEFAULT 0");
    await this.ensureEventColumn("completed_at", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("priority", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("percent_complete", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("milestone_status", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("due_date_class", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureEventColumn("is_visible", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureEventColumn("overlap_position", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureEventColumn("overlap_count", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureEventColumn("alarm_action", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("snooze_minutes", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("snooze_times", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("all_day_reminder_at", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureEventColumn("reminder_id", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureEventColumn("conflict_status", "TEXT NOT NULL DEFAULT 'none'");
	    await this.ensureEventColumn("conflict_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureDateMarkerColumn("disable_touch_event", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureDateMarkerColumn("multi_period_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureDateMarkerColumn("selected_color", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureDateMarkerColumn("selected_dot_color", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureDateMarkerColumn("accessibility_label", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureDateMarkerColumn("custom_mark_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureResourceColumn("source_id", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureResourceColumn("resource_type", "TEXT NOT NULL DEFAULT 'resource'");
		    await this.ensureResourceColumn("email", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("external_id", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("parent_resource_id", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("resource_group_id", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("capacity", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureResourceColumn("location", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureResourceColumn("color", "TEXT NOT NULL DEFAULT '#2563EB'");
	    await this.ensureResourceColumn("is_bookable", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureResourceColumn("is_visible", "INTEGER NOT NULL DEFAULT 1");
		    await this.ensureResourceColumn("availability_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("conflict_policy", "TEXT NOT NULL DEFAULT 'deny'");
		    await this.ensureResourceColumn("auto_accept", "INTEGER NOT NULL DEFAULT 0");
		    await this.ensureResourceColumn("backend_id", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("event_constraint_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("event_allow_json", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("event_class_names", "TEXT NOT NULL DEFAULT ''");
		    await this.ensureResourceColumn("permissions_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureResourceColumn("raw_props_json", "TEXT NOT NULL DEFAULT ''");
	    await this.ensureResourceColumn("last_sync_at", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureSourceColumn("free_busy_transparent", "INTEGER NOT NULL DEFAULT 0");
	    await this.ensureDefaultViewConfig();
	    await this.ensureDefaultSources();
    await this.ensureEventSourceIds();
  }

  async updateReminderId(eventId: string, reminderId: number): Promise<void> {
    await this.init();
    await this.requireStore().executeSql(
      `UPDATE ${EVENT_TABLE} SET reminder_id = ${Math.floor(reminderId)}, updated_at = ${Date.now()} WHERE id = '${escapeSql(eventId)}'`
    );
  }

  private requireStore(): relationalStore.RdbStore {
    if (this.store === null) {
      throw new Error("本地数据库未初始化");
    }

    return this.store;
  }

  private async deleteById(id: string): Promise<void> {
    await this.requireStore().executeSql(`DELETE FROM ${EVENT_TABLE} WHERE id = '${escapeSql(id)}'`);
  }

  private readEvent(resultSet: relationalStore.ResultSet): CalendarEvent {
	    return {
	      id: resultSet.getString(resultSet.getColumnIndex("id")),
	      sourceId: this.readOptionalString(resultSet, "source_id"),
	      eventSourceId: this.readOptionalString(resultSet, "event_source_id"),
	      uid: resultSet.getString(resultSet.getColumnIndex("uid")),
      href: resultSet.getString(resultSet.getColumnIndex("href")),
      etag: resultSet.getString(resultSet.getColumnIndex("etag")),
      title: resultSet.getString(resultSet.getColumnIndex("title")),
      startAt: resultSet.getLong(resultSet.getColumnIndex("start_at")),
      endAt: resultSet.getLong(resultSet.getColumnIndex("end_at")),
      allDay: resultSet.getLong(resultSet.getColumnIndex("all_day")) === 1,
      location: resultSet.getString(resultSet.getColumnIndex("location")),
      notes: resultSet.getString(resultSet.getColumnIndex("notes")),
	      reminderMinutes: resultSet.getLong(resultSet.getColumnIndex("reminder_minutes")),
      secondReminderMinutes: this.readOptionalLong(resultSet, "second_reminder_minutes"),
      rrule: resultSet.getString(resultSet.getColumnIndex("rrule")),
      categoryColor: resultSet.getString(resultSet.getColumnIndex("category_color")),
      backgroundColor: this.readOptionalString(resultSet, "background_color"),
      borderColor: this.readOptionalString(resultSet, "border_color"),
      textColor: this.readOptionalString(resultSet, "text_color"),
      dragBackgroundColor: this.readOptionalString(resultSet, "drag_background_color"),
      eventCategory: this.readOptionalString(resultSet, "event_category"),
      eventKind: this.readEventKind(resultSet),
      url: this.readOptionalString(resultSet, "url"),
      attendees: this.readOptionalString(resultSet, "attendees"),
      attendeeJson: this.readOptionalString(resultSet, "attendee_json"),
      organizerName: this.readOptionalString(resultSet, "organizer_name"),
      organizerEmail: this.readOptionalString(resultSet, "organizer_email"),
	      conferenceUrl: this.readOptionalString(resultSet, "conference_url"),
	      attachmentUrl: this.readOptionalString(resultSet, "attachment_url"),
	      attachmentsJson: this.readOptionalString(resultSet, "attachments_json"),
	      travelMinutes: this.readOptionalLong(resultSet, "travel_minutes"),
		      comingDuration: this.readOptionalLong(resultSet, "coming_duration"),
		      availability: this.readAvailability(resultSet),
		      freeBusyTransparent: this.readOptionalLong(resultSet, "free_busy_transparent") !== 0,
		      privacy: this.readPrivacy(resultSet),
	      timeZone: this.readOptionalString(resultSet, "time_zone"),
	      eventStatus: this.readEventStatus(resultSet),
	      appointmentStatus: this.readAppointmentStatus(resultSet),
	      appointmentCapacity: this.readOptionalLong(resultSet, "appointment_capacity"),
	      appointmentBookedCount: this.readOptionalLong(resultSet, "appointment_booked_count"),
	      appointmentMinDurationMinutes: this.readOptionalLong(resultSet, "appointment_min_duration_minutes"),
	      appointmentMaxDurationMinutes: this.readOptionalLong(resultSet, "appointment_max_duration_minutes"),
	      appointmentBufferBeforeMinutes: this.readOptionalLong(resultSet, "appointment_buffer_before_minutes"),
	      appointmentBufferAfterMinutes: this.readOptionalLong(resultSet, "appointment_buffer_after_minutes"),
	      appointmentDeadlineMinutes: this.readOptionalLong(resultSet, "appointment_deadline_minutes"),
	      appointmentPublicUrl: this.readOptionalString(resultSet, "appointment_public_url"),
	      appointmentFormJson: this.readOptionalString(resultSet, "appointment_form_json"),
	      appointmentTimezone: this.readOptionalString(resultSet, "appointment_timezone"),
	      appointmentSlotIntervalMinutes: this.readOptionalLong(resultSet, "appointment_slot_interval_minutes"),
	      appointmentApprovalRequired: this.readOptionalLong(resultSet, "appointment_approval_required") !== 0,
	      bookingJson: this.readOptionalString(resultSet, "booking_json"),
	      bookingContactName: this.readOptionalString(resultSet, "booking_contact_name"),
	      bookingContactEmail: this.readOptionalString(resultSet, "booking_contact_email"),
	      bookingContactPhone: this.readOptionalString(resultSet, "booking_contact_phone"),
	      bookingConfirmationStatus: this.readOptionalString(resultSet, "booking_confirmation_status"),
	      bookingStatus: this.readOptionalString(resultSet, "booking_status"),
	      exdate: this.readOptionalString(resultSet, "exdate"),
      rdate: this.readOptionalString(resultSet, "rdate"),
      recurrenceId: this.readOptionalString(resultSet, "recurrence_id"),
      sequence: this.readOptionalLong(resultSet, "sequence"),
      reminderOffsets: this.readOptionalString(resultSet, "reminder_offsets"),
      dueAt: this.readOptionalLong(resultSet, "due_at"),
      completedAt: this.readOptionalLong(resultSet, "completed_at"),
	      priority: this.readOptionalLong(resultSet, "priority"),
	      percentComplete: this.readOptionalLong(resultSet, "percent_complete"),
		      milestoneStatus: this.readOptionalString(resultSet, "milestone_status"),
		      dueDateClass: this.readOptionalString(resultSet, "due_date_class"),
		      groupId: this.readOptionalString(resultSet, "group_id"),
		      displayMode: this.readOptionalString(resultSet, "display_mode"),
		      overlap: this.readOptionalLong(resultSet, "overlap") !== 0,
		      editable: this.readOptionalLong(resultSet, "editable") !== 0,
		      startEditable: this.readOptionalLong(resultSet, "start_editable") !== 0,
		      durationEditable: this.readOptionalLong(resultSet, "duration_editable") !== 0,
		      resourceEditable: this.readOptionalLong(resultSet, "resource_editable") !== 0,
		      interactive: this.readOptionalLong(resultSet, "interactive") !== 0,
		      eventReadOnly: this.readOptionalLong(resultSet, "event_read_only") !== 0,
		      isVisible: this.readOptionalLong(resultSet, "is_visible") !== 0,
		      isPending: this.readOptionalLong(resultSet, "is_pending") !== 0,
		      isFocused: this.readOptionalLong(resultSet, "is_focused") !== 0,
		      overlapPosition: this.readOptionalLong(resultSet, "overlap_position"),
		      overlapCount: this.readOptionalLong(resultSet, "overlap_count"),
		      classNames: this.readOptionalString(resultSet, "class_names"),
		      customStyleJson: this.readOptionalString(resultSet, "custom_style_json"),
		      constraintJson: this.readOptionalString(resultSet, "constraint_json"),
		      extendedPropsJson: this.readOptionalString(resultSet, "extended_props_json"),
		      rawPropsJson: this.readOptionalString(resultSet, "raw_props_json"),
		      resourceIdsJson: this.readOptionalString(resultSet, "resource_ids_json"),
	      roomIdsJson: this.readOptionalString(resultSet, "room_ids_json"),
	      resourceStatusJson: this.readOptionalString(resultSet, "resource_status_json"),
	      alarmAction: this.readOptionalString(resultSet, "alarm_action"),
	      snoozeMinutes: this.readOptionalLong(resultSet, "snooze_minutes"),
	      snoozeTimes: this.readOptionalLong(resultSet, "snooze_times"),
	      allDayReminderAt: this.readOptionalString(resultSet, "all_day_reminder_at"),
	      alarmActionsJson: this.readOptionalString(resultSet, "alarm_actions_json"),
		      reminderId: this.readOptionalLong(resultSet, "reminder_id"),
	      conflictStatus: this.readConflictStatus(resultSet),
	      conflictJson: this.readOptionalString(resultSet, "conflict_json"),
	      lastModified: resultSet.getLong(resultSet.getColumnIndex("last_modified")),
      syncStatus: parseSyncStatus(resultSet.getString(resultSet.getColumnIndex("sync_status")))
    };
  }

  private readAccount(resultSet: relationalStore.ResultSet): CalendarAccount {
    return {
	      id: resultSet.getString(resultSet.getColumnIndex("id")),
	      displayName: resultSet.getString(resultSet.getColumnIndex("display_name")),
	      providerType: this.readOptionalString(resultSet, "provider_type"),
		      providerPresetJson: this.readOptionalString(resultSet, "provider_preset_json"),
		      serverUrl: resultSet.getString(resultSet.getColumnIndex("server_url")),
	      username: resultSet.getString(resultSet.getColumnIndex("username")),
	      password: resultSet.getString(resultSet.getColumnIndex("password")),
	      authType: this.normalizeAuthType(this.readOptionalString(resultSet, "auth_type")),
	      bearerToken: this.readOptionalString(resultSet, "bearer_token"),
	      customHeadersJson: this.readOptionalString(resultSet, "custom_headers_json"),
	      isActive: resultSet.getLong(resultSet.getColumnIndex("is_active")) === 1
	    };
	  }

  private readSource(resultSet: relationalStore.ResultSet): CalendarSource {
    return {
	      id: resultSet.getString(resultSet.getColumnIndex("id")),
	      accountId: resultSet.getString(resultSet.getColumnIndex("account_id")),
	      name: resultSet.getString(resultSet.getColumnIndex("name")),
	      description: this.readOptionalString(resultSet, "description"),
	      collectionUrl: resultSet.getString(resultSet.getColumnIndex("collection_url")),
		      subscriptionUrl: this.readOptionalString(resultSet, "subscription_url"),
		      principalUrl: this.readOptionalString(resultSet, "principal_url"),
		      homeSetUrl: this.readOptionalString(resultSet, "home_set_url"),
		      scheduleInboxUrl: this.readOptionalString(resultSet, "schedule_inbox_url"),
		      scheduleOutboxUrl: this.readOptionalString(resultSet, "schedule_outbox_url"),
		      calendarUserAddressSet: this.readOptionalString(resultSet, "calendar_user_address_set"),
		      ownerEmail: this.readOptionalString(resultSet, "owner_email"),
	      color: resultSet.getString(resultSet.getColumnIndex("color")),
	      backgroundColor: this.readOptionalString(resultSet, "background_color"),
	      borderColor: this.readOptionalString(resultSet, "border_color"),
	      textColor: resultSet.getString(resultSet.getColumnIndex("text_color")),
	      isVisible: resultSet.getLong(resultSet.getColumnIndex("is_visible")) === 1,
	      isDefault: resultSet.getLong(resultSet.getColumnIndex("is_default")) === 1,
	      isReadOnly: resultSet.getLong(resultSet.getColumnIndex("is_read_only")) === 1,
		      sourceType: parseSourceType(resultSet.getString(resultSet.getColumnIndex("source_type"))),
		      freeBusyTransparent: this.readOptionalLong(resultSet, "free_busy_transparent") !== 0,
		      displayOrder: this.readOptionalLong(resultSet, "display_order"),
		      refreshIntervalMinutes: this.readOptionalLong(resultSet, "refresh_interval_minutes"),
		      refreshPolicy: this.readOptionalString(resultSet, "refresh_policy"),
		      permissionsJson: this.readOptionalString(resultSet, "permissions_json"),
		      sharePermissionsJson: this.readOptionalString(resultSet, "share_permissions_json"),
		      shareUsersJson: this.readOptionalString(resultSet, "share_users_json"),
		      shareGroupsJson: this.readOptionalString(resultSet, "share_groups_json"),
		      publicShareUrl: this.readOptionalString(resultSet, "public_share_url"),
		      publicShareToken: this.readOptionalString(resultSet, "public_share_token"),
			      supportedReportsJson: this.readOptionalString(resultSet, "supported_reports_json"),
			      supportedComponentsJson: this.readOptionalString(resultSet, "supported_components_json"),
			      discoveryTraceJson: this.readOptionalString(resultSet, "discovery_trace_json"),
			      capabilitySource: this.readOptionalString(resultSet, "capability_source"),
			      lastDiscoveryError: this.readOptionalString(resultSet, "last_discovery_error"),
			      providerType: this.readOptionalString(resultSet, "provider_type"),
		      providerPresetJson: this.readOptionalString(resultSet, "provider_preset_json"),
		      syncStrategy: this.readOptionalString(resultSet, "sync_strategy"),
		      externalProviderId: this.readOptionalString(resultSet, "external_provider_id"),
		      nativeCalendarId: this.readOptionalString(resultSet, "native_calendar_id"),
		      nativeCalendarSyncState: this.readOptionalString(resultSet, "native_calendar_sync_state"),
		      widgetConfigJson: this.readOptionalString(resultSet, "widget_config_json"),
		      providerAdapterType: this.readOptionalString(resultSet, "provider_adapter_type"),
		      sourceLoadingState: this.readOptionalString(resultSet, "source_loading_state"),
		      lastLoadedRangeStart: this.readOptionalLong(resultSet, "last_loaded_range_start"),
		      lastLoadedRangeEnd: this.readOptionalLong(resultSet, "last_loaded_range_end"),
		      subscriptionEtag: this.readOptionalString(resultSet, "subscription_etag"),
		      subscriptionLastModified: this.readOptionalString(resultSet, "subscription_last_modified"),
		      ctag: resultSet.getString(resultSet.getColumnIndex("ctag")),
	      syncToken: resultSet.getString(resultSet.getColumnIndex("sync_token")),
	      lastSuccessfulSyncAt: this.readOptionalLong(resultSet, "last_successful_sync_at"),
	      lastSyncAt: resultSet.getLong(resultSet.getColumnIndex("last_sync_at")),
	      lastSyncHttpStatus: this.readOptionalLong(resultSet, "last_sync_http_status"),
	      retryAfterSeconds: this.readOptionalLong(resultSet, "retry_after_seconds"),
	      lastSyncDiagnosticJson: this.readOptionalString(resultSet, "last_sync_diagnostic_json"),
	      lastSyncError: resultSet.getString(resultSet.getColumnIndex("last_sync_error"))
		    };
  }

  private async migrateLegacyAccount(): Promise<void> {
    const existingPredicates = new relationalStore.RdbPredicates(CALDAV_ACCOUNT_TABLE);
    existingPredicates.limitAs(1);
    const existingResultSet: relationalStore.ResultSet =
      await this.requireStore().query(existingPredicates, CALDAV_ACCOUNT_COLUMNS);

    try {
      if (existingResultSet.goToNextRow()) {
        return;
      }
    } finally {
      existingResultSet.close();
    }

    const predicates = new relationalStore.RdbPredicates(ACCOUNT_TABLE);
    predicates.limitAs(1);
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, ACCOUNT_COLUMNS);

    try {
      if (!resultSet.goToNextRow()) {
        return;
      }

      const legacyAccount: CalendarAccount = {
        id: createLocalId("caldav"),
        displayName: "默认 CalDAV",
	        serverUrl: resultSet.getString(resultSet.getColumnIndex("server_url")),
	        username: resultSet.getString(resultSet.getColumnIndex("username")),
	        password: resultSet.getString(resultSet.getColumnIndex("password")),
	        authType: "basic",
	        bearerToken: "",
	        customHeadersJson: "",
	        isActive: true
	      };

      await this.requireStore().insert(CALDAV_ACCOUNT_TABLE, {
	        id: legacyAccount.id,
	        display_name: this.accountDisplayName(legacyAccount),
	        provider_type: inferCalendarProviderType(legacyAccount.serverUrl),
	        provider_preset_json: "",
	        server_url: legacyAccount.serverUrl,
	        username: legacyAccount.username,
	        password: legacyAccount.password,
	        auth_type: legacyAccount.authType ?? "basic",
	        bearer_token: "",
	        custom_headers_json: "",
	        is_active: 1,
        updated_at: Date.now()
      });
    } finally {
      resultSet.close();
    }
  }

  private accountDisplayName(account: CalendarAccount): string {
    const name: string = (account.displayName ?? "").trim();
    if (name.length > 0) {
      return name;
    }

    const username: string = account.username.trim();
    return username.length > 0 ? username : "CalDAV 账号";
  }

  private toBucket(event: CalendarEvent): relationalStore.ValuesBucket {
	    return {
	      id: event.id,
	      source_id: event.sourceId,
	      event_source_id: event.eventSourceId ?? event.sourceId,
	      uid: event.uid,
      href: event.href,
      etag: event.etag,
      title: event.title,
      start_at: event.startAt,
      end_at: event.endAt,
      all_day: event.allDay ? 1 : 0,
      location: event.location,
      notes: event.notes,
      reminder_minutes: event.reminderMinutes ?? 0,
      second_reminder_minutes: event.secondReminderMinutes ?? 0,
      rrule: event.rrule ?? "",
      category_color: event.categoryColor ?? "#2563EB",
      background_color: event.backgroundColor ?? "",
      border_color: event.borderColor ?? "",
      text_color: event.textColor ?? "",
      drag_background_color: event.dragBackgroundColor ?? "",
	      event_category: event.eventCategory ?? "",
	      event_kind: event.eventKind ?? "calendar",
      url: event.url ?? "",
      attendees: event.attendees ?? "",
      attendee_json: event.attendeeJson ?? "",
      organizer_name: event.organizerName ?? "",
	      organizer_email: event.organizerEmail ?? "",
	      conference_url: event.conferenceUrl ?? "",
	      attachment_url: event.attachmentUrl ?? "",
	      attachments_json: event.attachmentsJson ?? "",
	      travel_minutes: event.travelMinutes ?? 0,
		      coming_duration: event.comingDuration ?? 0,
		      availability: event.availability ?? "busy",
			      free_busy_transparent: this.eventIsFreeBusyTransparent(event) ? 1 : 0,
		      privacy: event.privacy ?? "default",
	      time_zone: event.timeZone ?? "",
	      event_status: event.eventStatus ?? "confirmed",
	      appointment_status: event.appointmentStatus ?? "available",
	      appointment_capacity: event.appointmentCapacity ?? 1,
	      appointment_booked_count: event.appointmentBookedCount ?? 0,
	      appointment_min_duration_minutes: event.appointmentMinDurationMinutes ?? 0,
	      appointment_max_duration_minutes: event.appointmentMaxDurationMinutes ?? 0,
	      appointment_buffer_before_minutes: event.appointmentBufferBeforeMinutes ?? 0,
	      appointment_buffer_after_minutes: event.appointmentBufferAfterMinutes ?? 0,
	      appointment_deadline_minutes: event.appointmentDeadlineMinutes ?? 0,
	      appointment_public_url: event.appointmentPublicUrl ?? "",
	      appointment_form_json: event.appointmentFormJson ?? "",
	      appointment_timezone: event.appointmentTimezone ?? "",
	      appointment_slot_interval_minutes: event.appointmentSlotIntervalMinutes ?? 0,
	      appointment_approval_required: event.appointmentApprovalRequired === true ? 1 : 0,
	      booking_json: event.bookingJson ?? "",
	      booking_contact_name: event.bookingContactName ?? "",
	      booking_contact_email: event.bookingContactEmail ?? "",
	      booking_contact_phone: event.bookingContactPhone ?? "",
	      booking_confirmation_status: event.bookingConfirmationStatus ?? "",
	      booking_status: event.bookingStatus ?? "",
	      exdate: event.exdate ?? "",
      rdate: event.rdate ?? "",
      recurrence_id: event.recurrenceId ?? "",
      sequence: event.sequence ?? 0,
      reminder_offsets: event.reminderOffsets ?? this.defaultReminderOffsets(event.reminderMinutes ?? 0, event.secondReminderMinutes ?? 0),
      due_at: event.dueAt ?? 0,
      completed_at: event.completedAt ?? 0,
		      priority: event.priority ?? 0,
		      percent_complete: event.percentComplete ?? 0,
			      milestone_status: event.milestoneStatus ?? "",
			      due_date_class: event.dueDateClass ?? "",
			      group_id: event.groupId ?? "",
			      display_mode: event.displayMode ?? "",
			      overlap: event.overlap === false ? 0 : 1,
			      editable: event.editable === false ? 0 : 1,
			      start_editable: event.startEditable === false ? 0 : 1,
			      duration_editable: event.durationEditable === false ? 0 : 1,
			      resource_editable: event.resourceEditable === false ? 0 : 1,
			      interactive: event.interactive === false ? 0 : 1,
			      event_read_only: event.eventReadOnly === true ? 1 : 0,
			      is_visible: event.isVisible === false ? 0 : 1,
			      is_pending: event.isPending === true ? 1 : 0,
			      is_focused: event.isFocused === true ? 1 : 0,
			      overlap_position: event.overlapPosition ?? 0,
			      overlap_count: event.overlapCount ?? 1,
			      class_names: event.classNames ?? "",
			      custom_style_json: event.customStyleJson ?? "",
			      constraint_json: event.constraintJson ?? "",
			      extended_props_json: event.extendedPropsJson ?? "",
			      raw_props_json: event.rawPropsJson ?? "",
			      resource_ids_json: event.resourceIdsJson ?? "",
		      room_ids_json: event.roomIdsJson ?? "",
		      resource_status_json: event.resourceStatusJson ?? "",
		      alarm_action: event.alarmAction ?? "",
		      snooze_minutes: event.snoozeMinutes ?? 0,
		      snooze_times: event.snoozeTimes ?? 0,
		      all_day_reminder_at: event.allDayReminderAt ?? "",
		      alarm_actions_json: event.alarmActionsJson ?? "",
		      reminder_id: event.reminderId ?? 0,
	      conflict_status: event.conflictStatus ?? "none",
	      conflict_json: event.conflictJson ?? "",
	      last_modified: event.lastModified,
      sync_status: event.syncStatus,
      updated_at: Date.now()
    };
  }

  private copyEvent(
    event: CalendarEvent,
    href: string,
    etag: string,
    lastModified: number,
    syncStatus: CalendarSyncStatus,
    sourceId: string
  ): CalendarEvent {
	    return {
	      id: event.id,
	      sourceId,
	      eventSourceId: event.eventSourceId ?? sourceId,
	      uid: event.uid,
      href,
      etag,
      title: event.title,
      startAt: event.startAt,
      endAt: event.endAt,
      allDay: event.allDay,
      location: event.location,
      notes: event.notes,
      reminderMinutes: event.reminderMinutes ?? 0,
      secondReminderMinutes: event.secondReminderMinutes ?? 0,
      rrule: event.rrule ?? "",
      categoryColor: event.categoryColor ?? "#2563EB",
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
		      freeBusyTransparent: event.freeBusyTransparent ?? (event.availability ?? "busy") === "free",
		      privacy: event.privacy ?? "default",
	      timeZone: event.timeZone ?? "",
	      eventStatus: event.eventStatus ?? "confirmed",
	      appointmentStatus: event.appointmentStatus ?? "available",
	      appointmentCapacity: event.appointmentCapacity ?? 1,
	      appointmentBookedCount: event.appointmentBookedCount ?? 0,
	      appointmentMinDurationMinutes: event.appointmentMinDurationMinutes ?? 0,
	      appointmentMaxDurationMinutes: event.appointmentMaxDurationMinutes ?? 0,
	      appointmentBufferBeforeMinutes: event.appointmentBufferBeforeMinutes ?? 0,
	      appointmentBufferAfterMinutes: event.appointmentBufferAfterMinutes ?? 0,
		      appointmentDeadlineMinutes: event.appointmentDeadlineMinutes ?? 0,
		      appointmentPublicUrl: event.appointmentPublicUrl ?? "",
		      appointmentFormJson: event.appointmentFormJson ?? "",
		      appointmentTimezone: event.appointmentTimezone ?? "",
		      appointmentSlotIntervalMinutes: event.appointmentSlotIntervalMinutes ?? 0,
		      appointmentApprovalRequired: event.appointmentApprovalRequired ?? false,
		      bookingJson: event.bookingJson ?? "",
		      bookingContactName: event.bookingContactName ?? "",
		      bookingContactEmail: event.bookingContactEmail ?? "",
		      bookingContactPhone: event.bookingContactPhone ?? "",
		      bookingConfirmationStatus: event.bookingConfirmationStatus ?? "",
		      bookingStatus: event.bookingStatus ?? "",
	      exdate: event.exdate ?? "",
      rdate: event.rdate ?? "",
      recurrenceId: event.recurrenceId ?? "",
      sequence: event.sequence ?? 0,
      reminderOffsets: event.reminderOffsets ?? this.defaultReminderOffsets(event.reminderMinutes ?? 0, event.secondReminderMinutes ?? 0),
      dueAt: event.dueAt ?? 0,
      completedAt: event.completedAt ?? 0,
		      priority: event.priority ?? 0,
		      percentComplete: event.percentComplete ?? 0,
			      milestoneStatus: event.milestoneStatus ?? "",
			      dueDateClass: event.dueDateClass ?? "",
			      groupId: event.groupId ?? "",
			      displayMode: event.displayMode ?? "",
			      overlap: event.overlap ?? true,
			      editable: event.editable ?? true,
			      startEditable: event.startEditable ?? true,
			      durationEditable: event.durationEditable ?? true,
				      resourceEditable: event.resourceEditable ?? true,
				      interactive: event.interactive ?? true,
				      eventReadOnly: event.eventReadOnly ?? false,
				      isVisible: event.isVisible ?? true,
				      isPending: event.isPending ?? false,
				      isFocused: event.isFocused ?? false,
				      overlapPosition: event.overlapPosition ?? 0,
				      overlapCount: event.overlapCount ?? 1,
				      classNames: event.classNames ?? "",
			      customStyleJson: event.customStyleJson ?? "",
			      constraintJson: event.constraintJson ?? "",
			      extendedPropsJson: event.extendedPropsJson ?? "",
			      rawPropsJson: event.rawPropsJson ?? "",
			      resourceIdsJson: event.resourceIdsJson ?? "",
		      roomIdsJson: event.roomIdsJson ?? "",
		      resourceStatusJson: event.resourceStatusJson ?? "",
		      alarmAction: event.alarmAction ?? "",
		      snoozeMinutes: event.snoozeMinutes ?? 0,
		      snoozeTimes: event.snoozeTimes ?? 0,
		      allDayReminderAt: event.allDayReminderAt ?? "",
		      alarmActionsJson: event.alarmActionsJson ?? "",
		      reminderId: event.reminderId ?? 0,
	      conflictStatus: event.conflictStatus ?? "none",
	      conflictJson: event.conflictJson ?? "",
	      lastModified,
      syncStatus
    };
  }

  private sourceToBucket(source: CalendarSource): relationalStore.ValuesBucket {
    return {
	      id: source.id ?? "",
	      account_id: source.accountId,
	      name: source.name,
	      description: source.description ?? "",
	      collection_url: source.collectionUrl,
		      subscription_url: source.subscriptionUrl ?? "",
		      principal_url: source.principalUrl ?? "",
		      home_set_url: source.homeSetUrl ?? "",
		      schedule_inbox_url: source.scheduleInboxUrl ?? "",
		      schedule_outbox_url: source.scheduleOutboxUrl ?? "",
		      calendar_user_address_set: source.calendarUserAddressSet ?? "",
		      owner_email: source.ownerEmail ?? "",
	      color: normalizeColor(source.color),
	      background_color: normalizeColor(source.backgroundColor ?? source.color),
	      border_color: normalizeColor(source.borderColor ?? source.color),
	      text_color: source.textColor ?? "#FFFFFF",
	      is_visible: source.isVisible ? 1 : 0,
	      is_default: source.isDefault ? 1 : 0,
	      is_read_only: source.isReadOnly ? 1 : 0,
	      source_type: source.sourceType,
	      free_busy_transparent: source.freeBusyTransparent === true ? 1 : 0,
		      display_order: source.displayOrder ?? 0,
		      refresh_interval_minutes: source.refreshIntervalMinutes ?? 15,
		      refresh_policy: source.refreshPolicy ?? "manualAndInterval",
			      permissions_json: source.permissionsJson ?? "",
			      share_permissions_json: source.sharePermissionsJson ?? "",
			      share_users_json: source.shareUsersJson ?? "",
			      share_groups_json: source.shareGroupsJson ?? "",
			      public_share_url: source.publicShareUrl ?? "",
			      public_share_token: source.publicShareToken ?? "",
				      supported_reports_json: source.supportedReportsJson ?? "",
				      supported_components_json: source.supportedComponentsJson ?? "",
				      discovery_trace_json: source.discoveryTraceJson ?? "",
				      capability_source: source.capabilitySource ?? "",
				      last_discovery_error: source.lastDiscoveryError ?? "",
				      provider_type: source.providerType ?? inferCalendarProviderType(source.collectionUrl),
		      provider_preset_json: source.providerPresetJson ?? "",
		      sync_strategy: source.syncStrategy ?? "",
		      external_provider_id: source.externalProviderId ?? "",
		      native_calendar_id: source.nativeCalendarId ?? "",
			      native_calendar_sync_state: source.nativeCalendarSyncState ?? "",
			      widget_config_json: source.widgetConfigJson ?? "",
			      provider_adapter_type: source.providerAdapterType ?? "",
			      source_loading_state: source.sourceLoadingState ?? "idle",
			      last_loaded_range_start: source.lastLoadedRangeStart ?? 0,
			      last_loaded_range_end: source.lastLoadedRangeEnd ?? 0,
			      subscription_etag: source.subscriptionEtag ?? "",
			      subscription_last_modified: source.subscriptionLastModified ?? "",
			      ctag: source.ctag ?? "",
		      sync_token: source.syncToken ?? "",
		      last_successful_sync_at: source.lastSuccessfulSyncAt ?? 0,
		      last_sync_at: source.lastSyncAt ?? 0,
		      last_sync_http_status: source.lastSyncHttpStatus ?? 0,
		      retry_after_seconds: source.retryAfterSeconds ?? 0,
		      last_sync_diagnostic_json: source.lastSyncDiagnosticJson ?? "",
		      last_sync_error: source.lastSyncError ?? "",
	      updated_at: Date.now()
	    };
  }

  private readResource(resultSet: relationalStore.ResultSet): CalendarResource {
    return {
      id: resultSet.getString(resultSet.getColumnIndex("id")),
      sourceId: this.readOptionalString(resultSet, "source_id"),
      resourceType: this.readResourceType(resultSet),
      name: resultSet.getString(resultSet.getColumnIndex("name")),
      email: this.readOptionalString(resultSet, "email"),
      externalId: this.readOptionalString(resultSet, "external_id"),
      parentResourceId: this.readOptionalString(resultSet, "parent_resource_id"),
      resourceGroupId: this.readOptionalString(resultSet, "resource_group_id"),
      capacity: this.readOptionalLong(resultSet, "capacity"),
      location: this.readOptionalString(resultSet, "location"),
      color: this.readOptionalString(resultSet, "color"),
      isBookable: this.readOptionalLong(resultSet, "is_bookable") !== 0,
      isVisible: this.readOptionalLong(resultSet, "is_visible") !== 0,
      availabilityJson: this.readOptionalString(resultSet, "availability_json"),
      conflictPolicy: this.readOptionalString(resultSet, "conflict_policy"),
      autoAccept: this.readOptionalLong(resultSet, "auto_accept") !== 0,
      backendId: this.readOptionalString(resultSet, "backend_id"),
      eventConstraintJson: this.readOptionalString(resultSet, "event_constraint_json"),
      eventAllowJson: this.readOptionalString(resultSet, "event_allow_json"),
      eventClassNames: this.readOptionalString(resultSet, "event_class_names"),
      permissionsJson: this.readOptionalString(resultSet, "permissions_json"),
      rawPropsJson: this.readOptionalString(resultSet, "raw_props_json"),
      lastSyncAt: this.readOptionalLong(resultSet, "last_sync_at")
    };
  }

  private resourceToBucket(resource: CalendarResource): relationalStore.ValuesBucket {
    return {
      id: resource.id ?? "",
      source_id: resource.sourceId ?? "",
      resource_type: resource.resourceType,
      name: resource.name,
      email: resource.email ?? "",
      external_id: resource.externalId ?? "",
      parent_resource_id: resource.parentResourceId ?? "",
      resource_group_id: resource.resourceGroupId ?? "",
      capacity: resource.capacity ?? 0,
      location: resource.location ?? "",
      color: normalizeColor(resource.color ?? "#2563EB"),
      is_bookable: resource.isBookable === false ? 0 : 1,
      is_visible: resource.isVisible === false ? 0 : 1,
      availability_json: resource.availabilityJson ?? "",
      conflict_policy: resource.conflictPolicy ?? "deny",
      auto_accept: resource.autoAccept === true ? 1 : 0,
      backend_id: resource.backendId ?? "",
      event_constraint_json: resource.eventConstraintJson ?? "",
      event_allow_json: resource.eventAllowJson ?? "",
      event_class_names: resource.eventClassNames ?? "",
      permissions_json: resource.permissionsJson ?? "",
      raw_props_json: resource.rawPropsJson ?? "",
      last_sync_at: resource.lastSyncAt ?? 0,
      updated_at: Date.now()
    };
  }

  private readViewConfig(resultSet: relationalStore.ResultSet): CalendarViewConfig {
    return {
      id: resultSet.getString(resultSet.getColumnIndex("id")),
      defaultView: resultSet.getString(resultSet.getColumnIndex("default_view")),
      weekStartsOn: resultSet.getLong(resultSet.getColumnIndex("week_starts_on")),
      weekEndsOn: this.readOptionalLong(resultSet, "week_ends_on"),
      minHour: resultSet.getLong(resultSet.getColumnIndex("min_hour")),
      maxHour: resultSet.getLong(resultSet.getColumnIndex("max_hour")),
      timeSlotMinutes: resultSet.getLong(resultSet.getColumnIndex("time_slot_minutes")),
      maxVisibleEventsPerDay: resultSet.getLong(resultSet.getColumnIndex("max_visible_events_per_day")),
	      overlapOffset: resultSet.getLong(resultSet.getColumnIndex("overlap_offset")),
	      swipeEnabled: resultSet.getLong(resultSet.getColumnIndex("swipe_enabled")) === 1,
	      showWeekNumbers: resultSet.getLong(resultSet.getColumnIndex("show_week_numbers")) === 1,
	      showSixWeeks: this.readOptionalLong(resultSet, "show_six_weeks") !== 0,
		      showAdjacentMonths: this.readOptionalLong(resultSet, "show_adjacent_months") !== 0,
		      nowIndicatorVisible: this.readOptionalLong(resultSet, "now_indicator_visible") !== 0,
		      scrollOffsetMinutes: this.readOptionalLong(resultSet, "scroll_offset_minutes"),
		      hourRowHeight: this.readOptionalLong(resultSet, "hour_row_height"),
		      eventMinHeightForMonthView: this.readOptionalLong(resultSet, "event_min_height_for_month_view"),
		      showAllDayEventCell: this.readOptionalLong(resultSet, "show_all_day_event_cell") !== 0,
		      timeslots: this.readOptionalLong(resultSet, "timeslots"),
		      monthMoreLabel: this.readOptionalString(resultSet, "month_more_label"),
	      eventOrder: this.readOptionalString(resultSet, "event_order"),
	      locale: this.readOptionalString(resultSet, "locale"),
	      hourFormat: this.readOptionalString(resultSet, "hour_format"),
	      timeZone: this.readOptionalString(resultSet, "time_zone"),
	      enabledViewsJson: this.readOptionalString(resultSet, "enabled_views_json"),
		      agendaEmptyText: this.readOptionalString(resultSet, "agenda_empty_text"),
		      agendaGroupMode: this.readOptionalString(resultSet, "agenda_group_mode"),
		      agendaShowPastDays: this.readOptionalLong(resultSet, "agenda_show_past_days") !== 0,
		      agendaPastScrollRange: this.readOptionalLong(resultSet, "agenda_past_scroll_range"),
		      agendaFutureScrollRange: this.readOptionalLong(resultSet, "agenda_future_scroll_range"),
		      agendaShowOnlySelectedDayItems: this.readOptionalLong(resultSet, "agenda_show_only_selected_day_items") !== 0,
		      themeMode: this.readOptionalString(resultSet, "theme_mode"),
	      defaultReminderMinutes: this.readOptionalLong(resultSet, "default_reminder_minutes"),
	      reminderSound: this.readOptionalString(resultSet, "reminder_sound"),
	      reminderVibrate: this.readOptionalLong(resultSet, "reminder_vibrate") !== 0,
	      eventKindFilter: this.readOptionalString(resultSet, "event_kind_filter"),
	      sourceFilterJson: this.readOptionalString(resultSet, "source_filter_json"),
		      hideCancelledEvents: this.readOptionalLong(resultSet, "hide_cancelled_events") !== 0,
		      showIncompleteTasksOnly: this.readOptionalLong(resultSet, "show_incomplete_tasks_only") !== 0,
		      businessHoursJson: this.readOptionalString(resultSet, "business_hours_json"),
		      minSelectableDate: this.readOptionalLong(resultSet, "min_selectable_date"),
		      maxSelectableDate: this.readOptionalLong(resultSet, "max_selectable_date"),
		      disabledDaysIndexesJson: this.readOptionalString(resultSet, "disabled_days_indexes_json"),
		      displayLoadingIndicator: this.readOptionalLong(resultSet, "display_loading_indicator") !== 0,
		      loadedDateRangesJson: this.readOptionalString(resultSet, "loaded_date_ranges_json")
    };
  }

  private viewConfigToBucket(config: CalendarViewConfig): relationalStore.ValuesBucket {
    return {
      id: config.id ?? "default",
      default_view: config.defaultView,
      week_starts_on: config.weekStartsOn,
      week_ends_on: config.weekEndsOn ?? this.defaultWeekEndsOn(config.weekStartsOn),
      min_hour: config.minHour,
      max_hour: config.maxHour,
      time_slot_minutes: config.timeSlotMinutes,
      max_visible_events_per_day: config.maxVisibleEventsPerDay,
	      overlap_offset: config.overlapOffset,
	      swipe_enabled: config.swipeEnabled ? 1 : 0,
	      show_week_numbers: config.showWeekNumbers ? 1 : 0,
		      show_six_weeks: config.showSixWeeks === false ? 0 : 1,
		      show_adjacent_months: config.showAdjacentMonths === false ? 0 : 1,
		      now_indicator_visible: config.nowIndicatorVisible === false ? 0 : 1,
		      scroll_offset_minutes: config.scrollOffsetMinutes ?? 480,
		      hour_row_height: config.hourRowHeight ?? 56,
		      event_min_height_for_month_view: config.eventMinHeightForMonthView ?? 18,
		      show_all_day_event_cell: config.showAllDayEventCell === false ? 0 : 1,
		      timeslots: config.timeslots ?? 1,
		      month_more_label: config.monthMoreLabel ?? "更多",
	      event_order: config.eventOrder ?? "start,title",
	      locale: config.locale ?? "zh-CN",
	      hour_format: config.hourFormat ?? "24h",
	      time_zone: config.timeZone ?? "Asia/Shanghai",
	      enabled_views_json: config.enabledViewsJson ?? "",
		      agenda_empty_text: config.agendaEmptyText ?? "当天没有日程",
		      agenda_group_mode: config.agendaGroupMode ?? "day",
		      agenda_show_past_days: config.agendaShowPastDays === true ? 1 : 0,
		      agenda_past_scroll_range: config.agendaPastScrollRange ?? 6,
		      agenda_future_scroll_range: config.agendaFutureScrollRange ?? 12,
		      agenda_show_only_selected_day_items: config.agendaShowOnlySelectedDayItems === true ? 1 : 0,
		      theme_mode: config.themeMode ?? "system",
	      default_reminder_minutes: config.defaultReminderMinutes ?? 15,
	      reminder_sound: config.reminderSound ?? "default",
	      reminder_vibrate: config.reminderVibrate === false ? 0 : 1,
	      event_kind_filter: config.eventKindFilter ?? "all",
	      source_filter_json: config.sourceFilterJson ?? "",
		      hide_cancelled_events: config.hideCancelledEvents === true ? 1 : 0,
		      show_incomplete_tasks_only: config.showIncompleteTasksOnly === true ? 1 : 0,
		      business_hours_json: config.businessHoursJson ?? "",
		      min_selectable_date: config.minSelectableDate ?? 0,
		      max_selectable_date: config.maxSelectableDate ?? 0,
		      disabled_days_indexes_json: config.disabledDaysIndexesJson ?? "",
		      display_loading_indicator: config.displayLoadingIndicator === true ? 1 : 0,
		      loaded_date_ranges_json: config.loadedDateRangesJson ?? "",
      updated_at: Date.now()
    };
  }

  private readDateMarker(resultSet: relationalStore.ResultSet): CalendarDateMarker {
    return {
      id: resultSet.getString(resultSet.getColumnIndex("id")),
      markerDate: resultSet.getLong(resultSet.getColumnIndex("marker_date")),
      markingType: this.readDateMarkingType(resultSet),
      title: this.readOptionalString(resultSet, "title"),
      color: this.readOptionalString(resultSet, "color"),
      selected: this.readOptionalLong(resultSet, "selected") === 1,
      disabled: this.readOptionalLong(resultSet, "disabled") === 1,
      disableTouchEvent: this.readOptionalLong(resultSet, "disable_touch_event") === 1,
      dotColorsJson: this.readOptionalString(resultSet, "dot_colors_json"),
      multiPeriodJson: this.readOptionalString(resultSet, "multi_period_json"),
      periodStart: this.readOptionalLong(resultSet, "period_start"),
      periodEnd: this.readOptionalLong(resultSet, "period_end"),
      periodColor: this.readOptionalString(resultSet, "period_color"),
      selectedColor: this.readOptionalString(resultSet, "selected_color"),
      selectedDotColor: this.readOptionalString(resultSet, "selected_dot_color"),
      accessibilityLabel: this.readOptionalString(resultSet, "accessibility_label"),
      customMarkJson: this.readOptionalString(resultSet, "custom_mark_json")
    };
  }

  private dateMarkerToBucket(marker: CalendarDateMarker): relationalStore.ValuesBucket {
    return {
      id: marker.id ?? "",
      marker_date: marker.markerDate,
      marking_type: marker.markingType,
      title: marker.title ?? "",
      color: normalizeColor(marker.color ?? "#2563EB"),
      selected: marker.selected === true ? 1 : 0,
      disabled: marker.disabled === true ? 1 : 0,
      disable_touch_event: marker.disableTouchEvent === true ? 1 : 0,
      dot_colors_json: marker.dotColorsJson ?? "",
      multi_period_json: marker.multiPeriodJson ?? "",
      period_start: marker.periodStart ?? 0,
      period_end: marker.periodEnd ?? 0,
      period_color: marker.periodColor ?? "",
      selected_color: marker.selectedColor ?? "",
      selected_dot_color: marker.selectedDotColor ?? "",
      accessibility_label: marker.accessibilityLabel ?? "",
      custom_mark_json: marker.customMarkJson ?? "",
      updated_at: Date.now()
    };
  }

  private async resolveDraftSourceId(sourceId: string): Promise<string> {
    if (sourceId.length > 0) {
      return sourceId;
    }

    const source: CalendarSource | null = await this.loadDefaultSource();
    if (source !== null && (source.id ?? "").length > 0) {
      return source.id ?? "";
    }

    return "";
  }

  private async ensureDefaultSources(): Promise<void> {
    const accounts: CalendarAccount[] = await this.readAllAccountsForMigration();
    for (const account of accounts) {
      const accountId: string = account.id ?? "";
      if (accountId.length === 0) {
        continue;
      }

      const existing: CalendarSource[] = await this.readSourcesForAccountForMigration(accountId);
      if (existing.length > 0) {
        continue;
      }

      const sourceCount: number = (await this.readAllSourcesForMigration()).length;
      const id: string = createLocalId("source");
      const source: CalendarSource = {
	        id,
	        accountId,
	        name: this.accountDisplayName(account),
	        description: "",
		        collectionUrl: normalizeCollectionUrl(account.serverUrl),
		        subscriptionUrl: "",
		        principalUrl: "",
		        homeSetUrl: "",
		        scheduleInboxUrl: "",
		        scheduleOutboxUrl: "",
		        calendarUserAddressSet: "",
		        ownerEmail: account.username.indexOf("@") > 0 ? account.username : "",
	        color: "#2563EB",
	        backgroundColor: "#2563EB",
	        borderColor: "#2563EB",
		        textColor: "#FFFFFF",
	        isVisible: true,
	        isDefault: sourceCount === 0 || account.isActive === true,
	        isReadOnly: false,
		        sourceType: "caldav",
		        freeBusyTransparent: false,
		        displayOrder: sourceCount,
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
				        capabilitySource: "",
				        lastDiscoveryError: "",
				        providerType: inferCalendarProviderType(account.serverUrl),
		        providerPresetJson: "",
			        syncStrategy: "",
			        externalProviderId: "",
			        nativeCalendarId: "",
				        nativeCalendarSyncState: "",
				        widgetConfigJson: "",
				        providerAdapterType: "",
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
      await this.requireStore().insert(SOURCE_TABLE, this.sourceToBucket(source));
    }
  }

  private async ensureDefaultViewConfig(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(VIEW_CONFIG_TABLE);
    predicates.equalTo("id", "default");
    predicates.limitAs(1);
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, ["id"]);

    try {
      if (resultSet.goToNextRow()) {
        return;
      }
    } finally {
      resultSet.close();
    }

    await this.requireStore().insert(VIEW_CONFIG_TABLE, this.viewConfigToBucket(this.defaultViewConfig()));
  }

	  private async ensureEventSourceIds(): Promise<void> {
	    const source: CalendarSource | null = await this.readDefaultSourceForMigration();
	    if (source === null || (source.id ?? "").length === 0) {
	      return;
	    }

	    await this.requireStore().executeSql(
	      `UPDATE ${EVENT_TABLE} SET source_id = '${escapeSql(source.id ?? "")}' WHERE source_id = ''`
	    );
	    await this.requireStore().executeSql(
	      `UPDATE ${EVENT_TABLE} SET event_source_id = source_id WHERE event_source_id = ''`
	    );
		    await this.requireStore().executeSql(
		      `UPDATE ${EVENT_TABLE} SET free_busy_transparent = 1 WHERE availability = 'free' AND free_busy_transparent = 0`
		    );
		    await this.requireStore().executeSql(
		      `UPDATE ${SOURCE_TABLE} SET free_busy_transparent = 1 WHERE source_type <> 'caldav' AND free_busy_transparent = 0`
		    );
	  }

  private async readAllAccountsForMigration(): Promise<CalendarAccount[]> {
    const predicates = new relationalStore.RdbPredicates(CALDAV_ACCOUNT_TABLE);
    predicates.orderByDesc("is_active");
    predicates.orderByDesc("updated_at");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, CALDAV_ACCOUNT_COLUMNS);

    try {
      const items: CalendarAccount[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readAccount(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  private async readAllSourcesForMigration(): Promise<CalendarSource[]> {
    const predicates = new relationalStore.RdbPredicates(SOURCE_TABLE);
    predicates.orderByDesc("is_default");
    predicates.orderByAsc("name");
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, SOURCE_COLUMNS);

    try {
      const items: CalendarSource[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readSource(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  private async readSourcesForAccountForMigration(accountId: string): Promise<CalendarSource[]> {
    const predicates = new relationalStore.RdbPredicates(SOURCE_TABLE);
    predicates.equalTo("account_id", accountId);
    const resultSet: relationalStore.ResultSet = await this.requireStore().query(predicates, SOURCE_COLUMNS);

    try {
      const items: CalendarSource[] = [];
      while (resultSet.goToNextRow()) {
        items.push(this.readSource(resultSet));
      }
      return items;
    } finally {
      resultSet.close();
    }
  }

  private async readDefaultSourceForMigration(): Promise<CalendarSource | null> {
    const sources: CalendarSource[] = await this.readAllSourcesForMigration();
    const defaults: CalendarSource[] = sources.filter((source: CalendarSource) => source.isDefault && !source.isReadOnly);
    if (defaults.length > 0) {
      return defaults[0];
    }

    const writable: CalendarSource[] = sources.filter((source: CalendarSource) => !source.isReadOnly);
    if (writable.length > 0) {
      return writable[0];
    }

    return sources.length > 0 ? sources[0] : null;
  }

  private readOptionalLong(resultSet: relationalStore.ResultSet, columnName: string): number {
    const columnIndex: number = resultSet.getColumnIndex(columnName);
    if (columnIndex < 0) {
      return 0;
    }

    return resultSet.getLong(columnIndex);
  }

	  private readOptionalString(resultSet: relationalStore.ResultSet, columnName: string): string {
    const columnIndex: number = resultSet.getColumnIndex(columnName);
    if (columnIndex < 0) {
      return "";
    }

	    return resultSet.getString(columnIndex);
	  }

	  private normalizeAuthType(value: string | undefined): "basic" | "bearer" | "none" | "custom" {
	    const normalized: string = (value ?? "").trim().toLowerCase();
	    if (normalized === "bearer" || normalized === "none" || normalized === "custom") {
	      return normalized as "bearer" | "none" | "custom";
	    }
	    return "basic";
	  }

	  private readEventKind(resultSet: relationalStore.ResultSet):
    "calendar" | "important" | "reminder" | "task" | "focus" | "outOfOffice" | "workingLocation" | "appointment" {
    const columnIndex: number = resultSet.getColumnIndex("event_kind");
    if (columnIndex < 0) {
      return "calendar";
    }

    const value: string = resultSet.getString(columnIndex);
    if (value === "important" || value === "reminder" || value === "task" || value === "focus" ||
      value === "outOfOffice" || value === "workingLocation" || value === "appointment") {
      return value;
    }

    return "calendar";
  }

  private readAvailability(resultSet: relationalStore.ResultSet): "busy" | "free" {
    return this.readOptionalString(resultSet, "availability") === "free" ? "free" : "busy";
  }

  private eventIsFreeBusyTransparent(event: CalendarEvent): boolean {
    return event.freeBusyTransparent === true || (event.availability ?? "busy") === "free";
  }

  private readPrivacy(resultSet: relationalStore.ResultSet): "default" | "public" | "private" | "confidential" {
    const value: string = this.readOptionalString(resultSet, "privacy");
    if (value === "public" || value === "private" || value === "confidential") {
      return value;
    }

    return "default";
  }

	  private readEventStatus(resultSet: relationalStore.ResultSet): "confirmed" | "tentative" | "cancelled" {
    const value: string = this.readOptionalString(resultSet, "event_status");
    if (value === "tentative" || value === "cancelled") {
      return value;
    }

		    return "confirmed";
		  }

	  private readAppointmentStatus(resultSet: relationalStore.ResultSet): "available" | "held" | "booked" | "cancelled" {
	    const value: string = this.readOptionalString(resultSet, "appointment_status");
	    if (value === "held" || value === "booked" || value === "cancelled") {
	      return value;
	    }

	    return "available";
	  }

		  private readConflictStatus(resultSet: relationalStore.ResultSet): CalendarConflictStatus {
	    const value: string = this.readOptionalString(resultSet, "conflict_status");
	    return value === "localDirtyRemoteChanged" ? "localDirtyRemoteChanged" : "none";
	  }

  private readDateMarkingType(resultSet: relationalStore.ResultSet): CalendarDateMarkingType {
    const value: string = this.readOptionalString(resultSet, "marking_type");
    if (value === "multi-dot" || value === "period" || value === "multi-period" || value === "custom") {
      return value;
    }
    return "dot";
  }

  private defaultViewConfig(): CalendarViewConfig {
    return {
      id: "default",
      defaultView: "day",
      weekStartsOn: 1,
      weekEndsOn: 0,
      minHour: 8,
      maxHour: 21,
      timeSlotMinutes: 60,
	      maxVisibleEventsPerDay: 3,
	      overlapOffset: 6,
	      swipeEnabled: true,
	      showWeekNumbers: false,
	      showSixWeeks: true,
	      showAdjacentMonths: true,
		      nowIndicatorVisible: true,
		      scrollOffsetMinutes: 480,
		      hourRowHeight: 56,
		      eventMinHeightForMonthView: 18,
		      showAllDayEventCell: true,
		      timeslots: 1,
		      monthMoreLabel: "更多",
	      eventOrder: "start,title",
	      locale: "zh-CN",
	      hourFormat: "24h",
	      timeZone: "Asia/Shanghai",
	      enabledViewsJson: "",
	      agendaEmptyText: "当天没有日程",
		      agendaGroupMode: "day",
		      agendaShowPastDays: false,
		      agendaPastScrollRange: 6,
		      agendaFutureScrollRange: 12,
		      agendaShowOnlySelectedDayItems: false,
		      themeMode: "system",
	      defaultReminderMinutes: 15,
	      reminderSound: "default",
	      reminderVibrate: true,
	      eventKindFilter: "all",
	      sourceFilterJson: "",
	      hideCancelledEvents: false,
		      showIncompleteTasksOnly: false,
		      businessHoursJson: "",
		      minSelectableDate: 0,
		      maxSelectableDate: 0,
		      disabledDaysIndexesJson: "",
		      displayLoadingIndicator: false,
		      loadedDateRangesJson: ""
    };
  }

  private normalizeViewConfig(config: CalendarViewConfig): CalendarViewConfig {
    const minHour: number = Math.min(23, Math.max(0, Math.floor(config.minHour)));
    const maxHour: number = Math.min(23, Math.max(minHour, Math.floor(config.maxHour)));
    const slot: number = [5, 10, 15, 20, 30, 60].indexOf(config.timeSlotMinutes) >= 0 ? config.timeSlotMinutes : 60;
    return {
      id: config.id ?? "default",
      defaultView: config.defaultView.length > 0 ? config.defaultView : "day",
      weekStartsOn: config.weekStartsOn === 0 ? 0 : 1,
      weekEndsOn: config.weekEndsOn === undefined ? this.defaultWeekEndsOn(config.weekStartsOn === 0 ? 0 : 1) :
        Math.min(6, Math.max(0, Math.floor(config.weekEndsOn))),
      minHour,
      maxHour,
      timeSlotMinutes: slot,
      maxVisibleEventsPerDay: Math.max(1, Math.floor(config.maxVisibleEventsPerDay)),
	      overlapOffset: Math.max(0, Math.floor(config.overlapOffset)),
	      swipeEnabled: config.swipeEnabled,
	      showWeekNumbers: config.showWeekNumbers,
	      showSixWeeks: config.showSixWeeks !== false,
		      showAdjacentMonths: config.showAdjacentMonths !== false,
		      nowIndicatorVisible: config.nowIndicatorVisible !== false,
		      scrollOffsetMinutes: Math.max(0, Math.min(1439, Math.floor(config.scrollOffsetMinutes ?? minHour * 60))),
		      hourRowHeight: Math.max(24, Math.floor(config.hourRowHeight ?? 56)),
		      eventMinHeightForMonthView: Math.max(12, Math.floor(config.eventMinHeightForMonthView ?? 18)),
		      showAllDayEventCell: config.showAllDayEventCell !== false,
		      timeslots: Math.max(1, Math.floor(config.timeslots ?? 1)),
		      monthMoreLabel: (config.monthMoreLabel ?? "更多").trim().length > 0 ? (config.monthMoreLabel ?? "更多").trim() : "更多",
	      eventOrder: (config.eventOrder ?? "start,title").trim().length > 0 ? (config.eventOrder ?? "start,title").trim() : "start,title",
	      locale: (config.locale ?? "zh-CN").trim().length > 0 ? (config.locale ?? "zh-CN").trim() : "zh-CN",
	      hourFormat: this.normalizeHourFormat(config.hourFormat ?? "24h"),
	      timeZone: this.normalizeTimeZone(config.timeZone ?? "Asia/Shanghai"),
	      enabledViewsJson: config.enabledViewsJson ?? "",
		      agendaEmptyText: (config.agendaEmptyText ?? "当天没有日程").trim().length > 0 ? (config.agendaEmptyText ?? "当天没有日程").trim() : "当天没有日程",
		      agendaGroupMode: this.normalizeAgendaGroupMode(config.agendaGroupMode ?? "day"),
		      agendaShowPastDays: config.agendaShowPastDays === true,
		      agendaPastScrollRange: Math.max(0, Math.floor(config.agendaPastScrollRange ?? 6)),
		      agendaFutureScrollRange: Math.max(0, Math.floor(config.agendaFutureScrollRange ?? 12)),
		      agendaShowOnlySelectedDayItems: config.agendaShowOnlySelectedDayItems === true,
		      themeMode: this.normalizeThemeMode(config.themeMode ?? "system"),
	      defaultReminderMinutes: Math.max(0, Math.floor(config.defaultReminderMinutes ?? 15)),
	      reminderSound: (config.reminderSound ?? "default").trim().length > 0 ? (config.reminderSound ?? "default").trim() : "default",
	      reminderVibrate: config.reminderVibrate !== false,
	      eventKindFilter: this.normalizeEventKindFilter(config.eventKindFilter ?? "all"),
	      sourceFilterJson: config.sourceFilterJson ?? "",
		      hideCancelledEvents: config.hideCancelledEvents === true,
		      showIncompleteTasksOnly: config.showIncompleteTasksOnly === true,
		      businessHoursJson: config.businessHoursJson ?? "",
		      minSelectableDate: Math.max(0, Math.floor(config.minSelectableDate ?? 0)),
		      maxSelectableDate: Math.max(0, Math.floor(config.maxSelectableDate ?? 0)),
		      disabledDaysIndexesJson: config.disabledDaysIndexesJson ?? "",
		      displayLoadingIndicator: config.displayLoadingIndicator === true,
		      loadedDateRangesJson: config.loadedDateRangesJson ?? ""
	    };
	  }

	  private normalizeThemeMode(value: string): string {
	    return value === "light" || value === "dark" ? value : "system";
	  }

	  private defaultWeekEndsOn(weekStartsOn: number): number {
	    return weekStartsOn === 0 ? 6 : 0;
	  }

	  private normalizeHourFormat(value: string): string {
	    return value === "12h" ? "12h" : "24h";
	  }

	  private normalizeTimeZone(value: string): string {
	    const timeZone: string = value.trim();
	    return timeZone.length > 0 ? timeZone : "Asia/Shanghai";
	  }

	  private normalizeEventKindFilter(value: string): string {
	    const allowed: string[] = ["all", "calendar", "important", "reminder", "task", "focus", "outOfOffice", "workingLocation", "appointment"];
	    return allowed.indexOf(value) >= 0 ? value : "all";
	  }

	  private normalizeAgendaGroupMode(value: string): string {
	    return value === "source" || value === "none" ? value : "day";
	  }

  private normalizeResource(resource: CalendarResource): CalendarResource {
    const name: string = resource.name.trim().length > 0 ? resource.name.trim() : "未命名资源";
    return {
      id: resource.id !== undefined && resource.id.length > 0 ? resource.id : createLocalId("resource"),
      sourceId: resource.sourceId ?? "",
      resourceType: this.normalizeResourceType(resource.resourceType),
      name,
      email: resource.email ?? "",
      externalId: resource.externalId ?? "",
      parentResourceId: resource.parentResourceId ?? "",
      resourceGroupId: resource.resourceGroupId ?? "",
      capacity: Math.max(0, Math.floor(resource.capacity ?? 0)),
      location: resource.location ?? "",
      color: normalizeColor(resource.color ?? "#2563EB"),
      isBookable: resource.isBookable !== false,
      isVisible: resource.isVisible !== false,
      availabilityJson: resource.availabilityJson ?? "",
      conflictPolicy: resource.conflictPolicy ?? "deny",
      autoAccept: resource.autoAccept === true,
      backendId: resource.backendId ?? "",
      eventConstraintJson: resource.eventConstraintJson ?? "",
      eventAllowJson: resource.eventAllowJson ?? "",
      eventClassNames: resource.eventClassNames ?? "",
      permissionsJson: resource.permissionsJson ?? "",
      rawPropsJson: resource.rawPropsJson ?? "",
      lastSyncAt: resource.lastSyncAt ?? 0
    };
  }

  private normalizeResourceType(value: CalendarResourceType): CalendarResourceType {
    if (value === "room" || value === "equipment" || value === "person") {
      return value;
    }
    return "resource";
  }

  private readResourceType(resultSet: relationalStore.ResultSet): CalendarResourceType {
    const value: string = this.readOptionalString(resultSet, "resource_type");
    if (value === "room" || value === "equipment" || value === "person") {
      return value;
    }
    return "resource";
  }

	  private shareUsersJsonFromPermissions(value: string): string {
	    if (value.trim().length === 0) {
	      return "";
	    }

	    try {
	      const parsed = JSON.parse(value) as Record<string, Object>[];
	      if (!Array.isArray(parsed)) {
	        return "";
	      }

	      const users: Object[] = [];
	      parsed.forEach((item: Record<string, Object>) => {
	        const email: string = `${item["email"] ?? ""}`.trim();
	        if (email.length === 0) {
	          return;
	        }
	        users.push(JSON.parse(JSON.stringify({
	          email,
	          role: `${item["role"] ?? "read"}` === "write" ? "write" : "read",
	          diagnostic: `${item["diagnostic"] ?? ""}`
	        })));
	      });
	      return users.length > 0 ? JSON.stringify(users) : "";
	    } catch {
	      return "";
	    }
	  }

  private normalizeDateMarker(marker: CalendarDateMarker): CalendarDateMarker {
    const markerDate: number = startOfDayValue(marker.markerDate);
    return {
      id: marker.id !== undefined && marker.id.length > 0 ? marker.id : createLocalId("marker"),
      markerDate,
      markingType: marker.markingType,
      title: marker.title ?? "",
      color: marker.color ?? "#2563EB",
      selected: marker.selected === true,
      disabled: marker.disabled === true,
      disableTouchEvent: marker.disableTouchEvent === true,
      dotColorsJson: marker.dotColorsJson ?? "",
      multiPeriodJson: marker.multiPeriodJson ?? "",
      periodStart: marker.periodStart ?? 0,
      periodEnd: marker.periodEnd ?? 0,
      periodColor: marker.periodColor ?? "",
      selectedColor: marker.selectedColor ?? "",
      selectedDotColor: marker.selectedDotColor ?? "",
      accessibilityLabel: marker.accessibilityLabel ?? "",
      customMarkJson: marker.customMarkJson ?? ""
    };
  }

	  private defaultReminderOffsets(first: number, second: number): string {
    const values: number[] = [];
    if (first > 0) {
      values.push(first);
    }
    if (second > 0 && values.indexOf(second) < 0) {
      values.push(second);
    }
    return values.join(",");
  }

	  private async ensureEventColumn(columnName: string, columnDefinition: string): Promise<void> {
	    try {
	      await this.requireStore().executeSql(`ALTER TABLE ${EVENT_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
	    } catch {
	      return;
	    }
	  }

	  private async ensureSourceColumn(columnName: string, columnDefinition: string): Promise<void> {
	    try {
	      await this.requireStore().executeSql(`ALTER TABLE ${SOURCE_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
	    } catch {
	      return;
	    }
	  }

	  private async ensureAccountColumn(columnName: string, columnDefinition: string): Promise<void> {
	    try {
	      await this.requireStore().executeSql(`ALTER TABLE ${CALDAV_ACCOUNT_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
	    } catch {
	      return;
	    }
	  }

	  private async ensureViewConfigColumn(columnName: string, columnDefinition: string): Promise<void> {
	    try {
	      await this.requireStore().executeSql(`ALTER TABLE ${VIEW_CONFIG_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
	    } catch {
	      return;
	    }
	  }

	  private async ensureDateMarkerColumn(columnName: string, columnDefinition: string): Promise<void> {
	    try {
	      await this.requireStore().executeSql(`ALTER TABLE ${DATE_MARKER_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
	    } catch {
	      return;
	    }
	  }

  private async ensureResourceColumn(columnName: string, columnDefinition: string): Promise<void> {
    try {
      await this.requireStore().executeSql(`ALTER TABLE ${RESOURCE_TABLE} ADD COLUMN ${columnName} ${columnDefinition}`);
    } catch {
      return;
    }
  }

	  private copyResolvedEvent(
	    event: CalendarEvent,
	    syncStatus: CalendarSyncStatus,
	    lastModified: number,
	    sourceId: string
	  ): CalendarEvent {
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
	      reminderId: event.reminderId,
	      lastModified,
	      syncStatus,
	      conflictStatus: "none",
	      conflictJson: ""
	    };
	  }

	  private remoteEventFromConflict(conflictJson: string): CalendarEvent | null {
	    if (conflictJson.trim().length === 0) {
	      return null;
	    }

	    try {
	      const parsed: Object = JSON.parse(conflictJson) as Object;
	      const holder = parsed as Record<string, Object>;
	      const remote: CalendarEvent = holder["remoteEvent"] as CalendarEvent;
	      if (remote !== undefined && remote.id !== undefined && remote.uid !== undefined) {
	        return remote;
	      }
	    } catch {
	      return null;
	    }

	    return null;
	  }
	}

const parseSyncStatus = (value: string): CalendarSyncStatus => {
  if (value === "dirty" || value === "deleted") {
    return value;
  }

  return "clean";
};

const parseSourceType = (value: string): "caldav" | "subscription" | "local" => {
  if (value === "subscription" || value === "local") {
    return value;
  }

  return "caldav";
};

const normalizeColor = (value: string): string => {
  const color: string = value.trim();
  if (/^#[0-9a-fA-F]{6}$/.test(color)) {
    return color;
  }

  if (/^#[0-9a-fA-F]{8}$/.test(color)) {
    return color.substring(0, 7);
  }

  return "#2563EB";
};

const escapeSql = (value: string): string => value.replace(/'/g, "''");

const startOfDayValue = (value: number): number => {
  const date = new Date(value);
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
};
