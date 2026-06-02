import { common } from "@kit.AbilityKit";
import { CalendarLocalStore } from "../services/CalendarLocalStore";
import { CalendarReminderService } from "../services/CalendarReminderService";
import { CalendarSyncService } from "../services/CalendarSyncService";
import {
  CalendarAccount,
  CalendarAuthType,
  CalendarAvailability,
  CalendarConnectionTestResult,
  CalendarDateMarker,
  CalendarDateMarkingType,
	  CalendarEvent,
	  CalendarEventDraft,
	  CalendarEventKind,
	  CalendarEventStatus,
	  CalendarAppointmentStatus,
	  CalendarFreeBusySlot,
	  CalendarFreeBusyResult,
  CalendarPrivacy,
  CalendarResource,
  CalendarResourceType,
  CalendarSource,
  CalendarSyncResult,
  CalendarViewConfig,
  DEFAULT_ZOHO_CALDAV_URL
} from "../services/CalendarTypes";
import {
  addDays,
  addMonths,
  expandRecurringEvents,
	  formatDateTime,
	  formatMonthTitle,
	  formatTime,
	  monthGridDays,
	  sameDay,
	  startOfDay,
	  toUtcIcsDate
	} from "../services/CalendarFormat";
import {

// ---- ArkTS object spread helper (替代 ...viewConfig) ----
  buildProviderPresetJson,
  inferCalendarProviderType,
  normalizeProviderServerUrl,
  providerDiagnosticHint,
  providerPresetFor
} from "../services/CalendarProviderPresets";

// ---- ViewConfig helper: create copy with single field override ----
function withViewConfig(source: CalendarViewConfig, field: string, value: Object): CalendarViewConfig {
  return {
    id: field === "id" ? (value as string) : source.id,
    defaultView: field === "defaultView" ? (value as string) : source.defaultView,
    weekStartsOn: field === "weekStartsOn" ? (value as number) : source.weekStartsOn,
    weekEndsOn: field === "weekEndsOn" ? (value as number) : source.weekEndsOn,
    minHour: field === "minHour" ? (value as number) : source.minHour,
    maxHour: field === "maxHour" ? (value as number) : source.maxHour,
    timeSlotMinutes: field === "timeSlotMinutes" ? (value as number) : source.timeSlotMinutes,
    maxVisibleEventsPerDay: field === "maxVisibleEventsPerDay" ? (value as number) : source.maxVisibleEventsPerDay,
    overlapOffset: field === "overlapOffset" ? (value as number) : source.overlapOffset,
    swipeEnabled: field === "swipeEnabled" ? (value as boolean) : source.swipeEnabled,
    showWeekNumbers: field === "showWeekNumbers" ? (value as boolean) : source.showWeekNumbers,
    showSixWeeks: field === "showSixWeeks" ? (value as boolean) : source.showSixWeeks,
    showAdjacentMonths: field === "showAdjacentMonths" ? (value as boolean) : source.showAdjacentMonths,
    nowIndicatorVisible: field === "nowIndicatorVisible" ? (value as boolean) : source.nowIndicatorVisible,
    scrollOffsetMinutes: field === "scrollOffsetMinutes" ? (value as number) : source.scrollOffsetMinutes,
    hourRowHeight: field === "hourRowHeight" ? (value as number) : source.hourRowHeight,
    eventMinHeightForMonthView: field === "eventMinHeightForMonthView" ? (value as number) : source.eventMinHeightForMonthView,
    showAllDayEventCell: field === "showAllDayEventCell" ? (value as boolean) : source.showAllDayEventCell,
    timeslots: field === "timeslots" ? (value as number) : source.timeslots,
    monthMoreLabel: field === "monthMoreLabel" ? (value as string) : source.monthMoreLabel,
    eventOrder: field === "eventOrder" ? (value as string) : source.eventOrder,
    locale: field === "locale" ? (value as string) : source.locale,
    hourFormat: field === "hourFormat" ? (value as string) : source.hourFormat,
    timeZone: field === "timeZone" ? (value as string) : source.timeZone,
    enabledViewsJson: field === "enabledViewsJson" ? (value as string) : source.enabledViewsJson,
    agendaEmptyText: field === "agendaEmptyText" ? (value as string) : source.agendaEmptyText,
    agendaGroupMode: field === "agendaGroupMode" ? (value as string) : source.agendaGroupMode,
    agendaShowPastDays: field === "agendaShowPastDays" ? (value as boolean) : source.agendaShowPastDays,
    agendaPastScrollRange: field === "agendaPastScrollRange" ? (value as number) : source.agendaPastScrollRange,
    agendaFutureScrollRange: field === "agendaFutureScrollRange" ? (value as number) : source.agendaFutureScrollRange,
    agendaShowOnlySelectedDayItems: field === "agendaShowOnlySelectedDayItems" ? (value as boolean) : source.agendaShowOnlySelectedDayItems,
    themeMode: field === "themeMode" ? (value as string) : source.themeMode,
    defaultReminderMinutes: field === "defaultReminderMinutes" ? (value as number) : source.defaultReminderMinutes,
    reminderSound: field === "reminderSound" ? (value as string) : source.reminderSound,
    reminderVibrate: field === "reminderVibrate" ? (value as boolean) : source.reminderVibrate,
    eventKindFilter: field === "eventKindFilter" ? (value as string) : source.eventKindFilter,
    sourceFilterJson: field === "sourceFilterJson" ? (value as string) : source.sourceFilterJson,
    hideCancelledEvents: field === "hideCancelledEvents" ? (value as boolean) : source.hideCancelledEvents,
    showIncompleteTasksOnly: field === "showIncompleteTasksOnly" ? (value as boolean) : source.showIncompleteTasksOnly,
    businessHoursJson: field === "businessHoursJson" ? (value as string) : source.businessHoursJson,
    minSelectableDate: field === "minSelectableDate" ? (value as number) : source.minSelectableDate,
    maxSelectableDate: field === "maxSelectableDate" ? (value as number) : source.maxSelectableDate,
    disabledDaysIndexesJson: field === "disabledDaysIndexesJson" ? (value as string) : source.disabledDaysIndexesJson,
    displayLoadingIndicator: field === "displayLoadingIndicator" ? (value as boolean) : source.displayLoadingIndicator,
    loadedDateRangesJson: field === "loadedDateRangesJson" ? (value as string) : source.loadedDateRangesJson
  };
}

// Two-field override helper for minHour+maxHour
function withMinMaxHour(source: CalendarViewConfig, minHour: number, maxHour: number): CalendarViewConfig {
  return {
    id: source.id,
    defaultView: source.defaultView,
    weekStartsOn: source.weekStartsOn,
    weekEndsOn: source.weekEndsOn,
    minHour: minHour,
    maxHour: maxHour,
    timeSlotMinutes: source.timeSlotMinutes,
    maxVisibleEventsPerDay: source.maxVisibleEventsPerDay,
    overlapOffset: source.overlapOffset,
    swipeEnabled: source.swipeEnabled,
    showWeekNumbers: source.showWeekNumbers,
    showSixWeeks: source.showSixWeeks,
    showAdjacentMonths: source.showAdjacentMonths,
    nowIndicatorVisible: source.nowIndicatorVisible,
    scrollOffsetMinutes: source.scrollOffsetMinutes,
    hourRowHeight: source.hourRowHeight,
    eventMinHeightForMonthView: source.eventMinHeightForMonthView,
    showAllDayEventCell: source.showAllDayEventCell,
    timeslots: source.timeslots,
    monthMoreLabel: source.monthMoreLabel,
    eventOrder: source.eventOrder,
    locale: source.locale,
    hourFormat: source.hourFormat,
    timeZone: source.timeZone,
    enabledViewsJson: source.enabledViewsJson,
    agendaEmptyText: source.agendaEmptyText,
    agendaGroupMode: source.agendaGroupMode,
    agendaShowPastDays: source.agendaShowPastDays,
    agendaPastScrollRange: source.agendaPastScrollRange,
    agendaFutureScrollRange: source.agendaFutureScrollRange,
    agendaShowOnlySelectedDayItems: source.agendaShowOnlySelectedDayItems,
    themeMode: source.themeMode,
    defaultReminderMinutes: source.defaultReminderMinutes,
    reminderSound: source.reminderSound,
    reminderVibrate: source.reminderVibrate,
    eventKindFilter: source.eventKindFilter,
    sourceFilterJson: source.sourceFilterJson,
    hideCancelledEvents: source.hideCancelledEvents,
    showIncompleteTasksOnly: source.showIncompleteTasksOnly,
    businessHoursJson: source.businessHoursJson,
    minSelectableDate: source.minSelectableDate,
    maxSelectableDate: source.maxSelectableDate,
    disabledDaysIndexesJson: source.disabledDaysIndexesJson,
    displayLoadingIndicator: source.displayLoadingIndicator,
    loadedDateRangesJson: source.loadedDateRangesJson
  };
}

const DAY_MS: number = 24 * 60 * 60 * 1000;
const DEFAULT_CATEGORY_COLOR: string = "#16A37A";
const RECURRENCE_ID_MARKER: string = "__harmony_recur_";
const SURFACE_COLOR: string = "#FFFFFF";
const PAGE_COLOR: string = "#F2F3F5";
const SOFT_SURFACE_COLOR: string = "#E9EBEF";
const TINT_SURFACE_COLOR: string = "#FFF1EE";
const BORDER_COLOR: string = "#E3E5E8";
const TEXT_PRIMARY: string = "#171A1F";
const TEXT_SECONDARY: string = "#8B9099";
const PRIMARY_COLOR: string = "#FF6548";
const PRIMARY_STRONG_COLOR: string = "#E95338";
const PRIMARY_SOFT_COLOR: string = "#FFF1EE";
const SUCCESS_COLOR: string = "#0E8D68";
const SUCCESS_SOFT_COLOR: string = "#E9F8F1";
const WARNING_COLOR: string = "#E6A23C";
const WARNING_SOFT_COLOR: string = "#FFF4D8";
const DANGER_COLOR: string = "#D92D20";
const DANGER_SOFT_COLOR: string = "#FEECEB";
const DAY_ACCENT_COLOR: string = "#FF6548";
const TODAY_COLOR: string = PRIMARY_COLOR;
const TODAY_SOFT_COLOR: string = PRIMARY_SOFT_COLOR;
const BLUE_COLOR: string = "#5B7CFF";
const BLUE_SOFT_COLOR: string = "#EEF2FF";
const CARD_RADIUS: number = 28;
const CONTROL_RADIUS: number = 20;
const PILL_RADIUS: number = 24;
const BOTTOM_SAFE_PADDING: number = 58;
const COLOR_PALETTE_CLASSIC: string[] = ["#16A37A", "#2F6FDB", "#D99A21", "#D92D20", "#7C5CDB", "#64748B"];
const COLOR_PALETTE_SOFT: string[] = ["#36B48F", "#4C7DE7", "#E2A934", "#EF5C4E", "#8B6FE8", "#708090"];
const COLOR_PALETTE_FOCUS: string[] = ["#087A5A", "#245ABF", "#B7791F", "#B42318", "#6842C2", "#0F766E"];
const TIME_GRID_START_HOUR: number = 6;
const TIME_GRID_END_HOUR: number = 22;
const TIME_GRID_HEADER_HEIGHT: number = 58;
const TIME_GRID_HOUR_HEIGHT: number = 64;
const TIME_GRID_MIN_EVENT_HEIGHT: number = 34;

interface TimeGridEventLayout {
  readonly event: CalendarEvent;
  readonly top: number;
  readonly height: number;
  readonly column: number;
  readonly columnCount: number;
}

interface ScheduleBusyItem {
  readonly sourceId: string;
  readonly ownerEmail: string;
  readonly startAt: number;
  readonly endAt: number;
  readonly busyType: string;
}

interface ScheduleSuggestion {
  readonly startAt: number;
  readonly endAt: number;
  readonly label: string;
}

interface ResourceAvailabilityWindow {
  readonly days?: number[];
  readonly start: string;
  readonly end: string;
}

@Entry
@Component
struct Index {
  @State private events: CalendarEvent[] = [];
  @State private accounts: CalendarAccount[] = [];
  @State private sources: CalendarSource[] = [];
  @State private resources: CalendarResource[] = [];
  @State private appPage: string = "calendar";
  @State private selectedDay: number = startOfDay(Date.now());
  @State private visibleMonth: number = startOfDay(Date.now());
  @State private syncStatus: string = "未同步";
  @State private isSyncing: boolean = false;
  @State private isTestingConnection: boolean = false;
  @State private isSavingAccount: boolean = false;
  @State private showAccountForm: boolean = false;
  @State private accountFormStatus: string = "";
  @State private accountIdInput: string = "";
  @State private accountNameInput: string = "";
	  @State private serverUrl: string = DEFAULT_ZOHO_CALDAV_URL;
  @State private username: string = "";
  @State private password: string = "";
  @State private authTypeInput: CalendarAuthType = "basic";
  @State private bearerTokenInput: string = "";
  @State private customHeadersJsonInput: string = "";
  @State private subscriptionNameInput: string = "";
  @State private subscriptionUrlInput: string = "";
  @State private icsTextInput: string = "";
  @State private remoteSourceNameInput: string = "";
  @State private sourceShareEmailInput: string = "";
  @State private sourceShareRoleInput: string = "read";
  @State private remoteDeleteConfirmSourceId: string = "";
  @State private resourceNameInput: string = "";
  @State private resourceEmailInput: string = "";
  @State private resourceTypeInput: CalendarResourceType = "room";
  @State private resourceCapacityInput: string = "0";
  @State private resourceLocationInput: string = "";
  @State private resourceSourceIdInput: string = "";
  @State private titleInput: string = "";
  @State private startInput: string = "";
  @State private endInput: string = "";
  @State private allDayInput: boolean = false;
  @State private locationInput: string = "";
  @State private notesInput: string = "";
  @State private categoryColorInput: string = DEFAULT_CATEGORY_COLOR;
  @State private colorPaletteInput: string = "classic";
  @State private reminderInput: string = "0";
  @State private secondReminderInput: string = "0";
  @State private rruleInput: string = "";
  @State private eventKindInput: CalendarEventKind = "calendar";
  @State private urlInput: string = "";
	  @State private attendeesInput: string = "";
	  @State private attendeeNameInput: string = "";
	  @State private attendeeEmailInput: string = "";
	  @State private attendeeRoleInput: string = "REQ-PARTICIPANT";
	  @State private attendeeStatusInput: string = "NEEDS-ACTION";
	  @State private attendeeRsvpInput: boolean = true;
	  @State private attendeeJsonInput: string = "";
  @State private conferenceUrlInput: string = "";
  @State private attachmentUrlInput: string = "";
  @State private attachmentsJsonInput: string = "";
  @State private travelMinutesInput: string = "0";
  @State private comingDurationInput: string = "0";
  @State private availabilityInput: CalendarAvailability = "busy";
  @State private privacyInput: CalendarPrivacy = "default";
  @State private eventStatusInput: CalendarEventStatus = "confirmed";
  @State private appointmentStatusInput: CalendarAppointmentStatus = "available";
  @State private appointmentCapacityInput: string = "1";
  @State private appointmentBookedCountInput: string = "0";
  @State private appointmentMinDurationInput: string = "0";
  @State private appointmentMaxDurationInput: string = "0";
  @State private appointmentBufferBeforeInput: string = "0";
  @State private appointmentBufferAfterInput: string = "0";
  @State private appointmentDeadlineInput: string = "0";
  @State private appointmentPublicUrlInput: string = "";
  @State private appointmentFormJsonInput: string = "";
  @State private bookingJsonInput: string = "";
  @State private bookingContactNameInput: string = "";
  @State private bookingContactEmailInput: string = "";
  @State private bookingContactPhoneInput: string = "";
  @State private bookingStatusInput: string = "";
  @State private organizerNameInput: string = "";
  @State private organizerEmailInput: string = "";
  @State private exdateInput: string = "";
  @State private rdateInput: string = "";
  @State private reminderOffsetsInput: string = "";
  @State private dueInput: string = "";
  @State private completedInput: string = "";
  @State private priorityInput: string = "0";
  @State private percentCompleteInput: string = "0";
  @State private eventBackgroundColorInput: string = "";
  @State private eventBorderColorInput: string = "";
  @State private eventTextColorInput: string = "";
  @State private eventDragBackgroundColorInput: string = "";
  @State private milestoneStatusInput: string = "";
  @State private dueDateClassInput: string = "";
  @State private groupIdInput: string = "";
  @State private displayModeInput: string = "";
  @State private overlapInput: boolean = true;
  @State private editableInput: boolean = true;
  @State private startEditableInput: boolean = true;
  @State private durationEditableInput: boolean = true;
  @State private resourceEditableInput: boolean = true;
  @State private interactiveInput: boolean = true;
  @State private eventReadOnlyInput: boolean = false;
  @State private isPendingInput: boolean = false;
  @State private isFocusedInput: boolean = false;
  @State private classNamesInput: string = "";
  @State private customStyleJsonInput: string = "";
  @State private constraintJsonInput: string = "";
  @State private extendedPropsJsonInput: string = "";
  @State private rawPropsJsonInput: string = "";
  @State private resourceIdsJsonInput: string = "";
  @State private roomIdsJsonInput: string = "";
  @State private resourceStatusJsonInput: string = "";
  @State private quickRoomInput: string = "";
  @State private quickResourceInput: string = "";
  @State private alarmActionInput: string = "";
  @State private snoozeMinutesInput: string = "0";
  @State private snoozeTimesInput: string = "0";
  @State private allDayReminderAtInput: string = "";
  @State private alarmActionsJsonInput: string = "";
  @State private freeBusyStatus: string = "";
  @State private freeBusyConflictSummary: string = "";
  @State private scheduleSuggestionStatus: string = "";
  @State private scheduleSuggestions: ScheduleSuggestion[] = [];
  @State private timeZoneInput: string = "";
  @State private markerTitleInput: string = "";
  @State private markerDateInput: string = "";
  @State private markerTypeInput: string = "dot";
  @State private markerColorInput: string = PRIMARY_COLOR;
  @State private markerEndDateInput: string = "";
  @State private selectedSourceIdInput: string = "";
  @State private searchKeyword: string = "";
  @State private scheduleView: string = "month";
	  @State private editingEventId: string = "";
	  @State private editingOccurrenceStartAt: number = 0;
	  @State private recurrenceEditScope: string = "series";
  @State private formError: string = "";
  @State private showSearch: boolean = false;
  @State private showAdvancedEventOptions: boolean = false;
  @State private autoSyncIntervalIndex: number = 2;
  @State private viewConfig: CalendarViewConfig = {
    id: "default",
    defaultView: "month",
    weekStartsOn: 1,
    minHour: TIME_GRID_START_HOUR,
    maxHour: TIME_GRID_END_HOUR,
    timeSlotMinutes: 60,
    maxVisibleEventsPerDay: 3,
	    overlapOffset: 6,
	    swipeEnabled: true,
	    showWeekNumbers: false,
	    showSixWeeks: true,
	    showAdjacentMonths: true,
	    nowIndicatorVisible: true,
	    scrollOffsetMinutes: 480,
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
	    hourRowHeight: 56,
	    eventMinHeightForMonthView: 18,
	    showAllDayEventCell: true,
	    timeslots: 1,
	    minSelectableDate: 0,
	    maxSelectableDate: 0,
	    disabledDaysIndexesJson: "",
	    displayLoadingIndicator: false,
	    loadedDateRangesJson: ""
	  };
  @State private dateMarkers: CalendarDateMarker[] = [];
  @State private settingsRenderKey: number = 0;
  
  private syncService: CalendarSyncService | null = null;
  private autoSyncTimerId: number = -1;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    const store = new CalendarLocalStore(context);
    this.syncService = new CalendarSyncService(store, new CalendarReminderService());
    await store.init();
    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.markerDateInput = this.formatFullDate(this.selectedDay);
    this.markerEndDateInput = this.formatFullDate(this.selectedDay);
    await this.loadViewConfig();
    await this.loadAccounts();
    await this.loadSources();
    await this.loadResources();
    await this.loadDateMarkers();
    await this.loadEvents();
    this.resetAutoSyncTimer();
  }

  aboutToDisappear() {
    this.clearAutoSyncTimer();
  }

  build() {
    Column() {
      if (this.appPage === "settings") {
        Text(this.settingsRenderKey.toString()).fontSize(0).width(0).height(0).visibility(Visibility.None)
        this.NewSettingsPage()
      } else if (this.appPage === "calendars") {
        this.NewSourcesPage()
      } else if (this.appPage === "editor") {
        this.NewEditorPage()
      } else {
        this.NewCalendarPage()
      }
    }
    .height("100%")
    .backgroundColor(PAGE_COLOR)
  }

  @Builder
  NewCalendarPage() {
    Column() {
      this.NewTopBar(this.newCalendarKicker(), this.newCalendarTitle(), true, true)
      if (this.isTimeGridView()) {
        this.NewWeekView()
      } else if (this.scheduleView === "month") {
        this.NewMonthView()
      } else if (this.scheduleView === "year") {
        this.NewYearView()
      } else {
        this.NewAgendaView()
      }
    }
    .height("100%")
  }

  @Builder
  NewTopBar(kicker: string, title: string, showSearchButton: boolean, showAddButton: boolean) {
    Row() {
      this.NewSquareIconButton("menu", false)

      Text(title)
        .fontSize(32)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: 18 })

      if (showSearchButton) {
        this.NewSquareIconButton("today", false)
      }
      if (showAddButton) {
        this.NewSquareIconButton("add", false)
      }
      this.NewSquareIconButton("grid", false)
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 18, right: 18, top: 14, bottom: 8 })
    .backgroundColor(PAGE_COLOR)
  }

  @Builder
  NewSubTopBar(kicker: string, title: string, action: string) {
    Row() {
      this.NewSquareIconButton(this.appPage === "editor" ? "close" : "back", false)
      Text(title)
        .fontSize(30)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .margin({ left: 18 })
      if (action.length > 0) {
        this.NewSquareIconButton(action, false)
      }
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 18, right: 18, top: 18, bottom: 8 })
    .backgroundColor(PAGE_COLOR)
  }

  @Builder
  NewSquareIconButton(kind: string, primary: boolean) {
    Stack() {
      if (kind === "add") {
        Text("+")
          .fontSize(24)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Regular)
      } else if (kind === "menu") {
        Column() {
          Blank().width(18).height(2.5).backgroundColor(TEXT_PRIMARY).borderRadius(2)
          Blank().width(18).height(2.5).backgroundColor(TEXT_PRIMARY).borderRadius(2).margin({ top: 5 })
          Blank().width(18).height(2.5).backgroundColor(TEXT_PRIMARY).borderRadius(2).margin({ top: 5 })
        }
      } else if (kind === "grid") {
        Grid() {
          ForEach([0, 1, 2, 3], (item: number) => {
            GridItem() {
              Row() {
                Blank()
                  .width(6)
                  .height(6)
                  .backgroundColor(TEXT_PRIMARY)
                  .borderRadius(3)
              }
              .width("100%")
              .height("100%")
              .justifyContent(FlexAlign.Center)
              .alignItems(VerticalAlign.Center)
            }
          }, (item: number) => `${item}`)
        }
        .width(18)
        .height(18)
        .columnsTemplate("1fr 1fr")
        .rowsTemplate("1fr 1fr")
        .columnsGap(6)
        .rowsGap(6)
      } else if (kind === "today") {
        Text("今")
          .fontSize(18)
          .fontColor(PRIMARY_COLOR)
          .fontWeight(FontWeight.Bold)
      } else if (kind === "search") {
        this.SearchGlyph()
      } else if (kind === "sync") {
        Text("↻")
          .fontSize(24)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
      } else if (kind === "save") {
        Text("✓")
          .fontSize(24)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
      } else if (kind === "close") {
        Text("×")
          .fontSize(24)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Regular)
      } else {
        Text("<")
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width(56)
    .height(56)
    .margin({ left: kind === "menu" || kind === "back" || kind === "close" ? 0 : 12 })
    .backgroundColor("#F8F9FB")
    .borderRadius(28)
    .border({ width: 1, color: "#FDFDFE" })
    .shadow({ radius: 18, color: "#14000000", offsetX: 0, offsetY: 6 })
    .onClick(async () => {
      if (kind === "add") {
        this.openNewEvent();
      } else if (kind === "menu" || kind === "grid") {
        this.openSettings();
      } else if (kind === "today") {
        await this.goToday();
      } else if (kind === "search") {
        this.showSearch = !this.showSearch;
        if (this.showSearch) {
          this.scheduleView = "list";
        }
      } else if (kind === "sync") {
        await this.syncNow();
      } else if (kind === "save") {
        await this.saveEventForm();
      } else if (kind === "close") {
        this.closeEditor();
      } else {
        if (this.appPage === "editor") {
          this.closeEditor();
        } else {
          this.appPage = "calendar";
        }
      }
    })
  }

  @Builder
  SearchGlyph() {
    Column() {
      Row() {
        Blank()
          .width(18)
          .height(18)
          .border({ width: 2, color: TEXT_PRIMARY })
          .borderRadius(9)
      }
      .width(24)
      .justifyContent(FlexAlign.Center)
      Row() {
        Blank()
          .width(9)
          .height(2)
          .backgroundColor(TEXT_PRIMARY)
          .borderRadius(1)
          .rotate({ angle: 45 })
      }
      .width(24)
      .justifyContent(FlexAlign.End)
      .margin({ top: -3 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NewAgendaView() {
    Column() {
      Scroll() {
        Column() {
          if (this.showSearch || this.searchKeyword.trim().length > 0) {
            this.NewSearchBox()
          }
          this.NewViewSwitcher()
          this.NewWeekStrip()
          if (this.scheduleView === "list" || this.searchKeyword.trim().length > 0) {
            this.NewScheduleList(this.homeScheduleTitle(), true)
          } else {
            this.NewDayTimeGrid()
          }
        }
        .padding({ left: 18, right: 18, top: 0, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("calendar")
    }
  }

  @Builder
  NewWeekView() {
    Column() {
      Scroll() {
        Column() {
          this.NewViewSwitcher()
          this.NewWeekStrip()
          this.NewWeekGrid()
        }
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("views")
    }
  }

  @Builder
  NewMonthView() {
    Column() {
      Scroll() {
        Column() {
          this.NewViewSwitcher()
          this.NewMonthCard()
          this.NewScheduleList(`${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日`, true)
        }
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("views")
    }
  }

  @Builder
  NewYearView() {
    Column() {
      Scroll() {
        Column() {
          this.NewViewSwitcher()
          this.NewYearGrid()
        }
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("views")
    }
  }

  @Builder
  NewSearchBox() {
    Row() {
      this.SearchGlyph()
      TextInput({ text: this.searchKeyword, placeholder: "搜索标题、地点、参会人或备注" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor("#00000000")
        .layoutWeight(1)
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
      if (this.searchKeyword.trim().length > 0) {
        Button("清空")
          .height(34)
          .width(64)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(PRIMARY_SOFT_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .margin({ left: 8 })
          .onClick(() => {
            this.searchKeyword = "";
            this.showSearch = false;
          })
      }
    }
    .height(56)
    .padding({ left: 16, right: 16 })
    .margin({ top: 10, bottom: 14 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(24)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewWeekStrip() {
    Row() {
      ForEach(this.weekDaysForSelectedDay(), (day: number) => {
        this.NewWeekDayPill(day)
      }, (day: number) => `${day}`)
    }
    .margin({ top: 4, bottom: 16 })
  }

  @Builder
  NewWeekDayPill(day: number) {
    Column() {
      Text(this.weekdayLabel(day))
        .fontSize(11)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .onClick(() => this.selectCalendarDay(day))
      Text(`${new Date(day).getDate()}`)
        .fontSize(18)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 6 })
        .onClick(() => this.selectCalendarDay(day))
    }
    .height(88)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .backgroundColor(sameDay(day, this.selectedDay) ? DAY_ACCENT_COLOR : "#00000000")
    .borderRadius(44)
    .margin({ right: day === this.weekDaysForSelectedDay()[6] ? 0 : 4 })
    .onClick(() => this.selectCalendarDay(day))
  }

  @Builder
  NewDayViewHeader() {
    Column() {
      Row() {
        Text(this.headerTitle())
          .fontSize(18)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text(`${this.visibleEvents().length} 项`)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
      }
      .width("100%")
      .height(34)
      .alignItems(VerticalAlign.Center)

      Row() {
        ForEach(this.weekDaysForSelectedDay(), (day: number) => {
          this.NewDayHeaderItem(day)
        }, (day: number) => `${day}`)
      }
      .width("100%")
      .margin({ top: 8 })
    }
    .padding({ left: 4, right: 4, top: 14, bottom: 14 })
  }

  @Builder
  NewDayHeaderItem(day: number) {
    Column() {
      Text(this.weekdayLabel(day))
        .fontSize(12)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
      Text(`${new Date(day).getDate()}`)
        .fontSize(19)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 5 })
      Blank()
        .width(4)
        .height(4)
        .backgroundColor(this.hasEventsForDay(day) ? (sameDay(day, this.selectedDay) ? "#FFFFFF" : DANGER_COLOR) : "#00000000")
        .borderRadius(2)
        .margin({ top: 5 })
    }
    .width(46)
    .height(76)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(sameDay(day, this.selectedDay) ? DAY_ACCENT_COLOR : "#00000000")
    .borderRadius(23)
    .layoutWeight(1)
    .onClick(() => this.selectCalendarDay(day, "day"))
  }

  @Builder
  NewDayTimeGrid() {
    Column() {
      Row() {
        Text("全天")
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
          .width(46)
        if (this.allDayEventsForDay(this.selectedDay).length > 0) {
          Text(this.allDaySummary(this.selectedDay))
            .fontSize(13)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        } else {
          Blank()
            .layoutWeight(1)
        }
      }
      .height(52)
      .padding({ left: 12, right: 12 })
      .border({ width: { bottom: 1 }, color: "#EFF1F4" })

      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.timeGridHourLabels(), (hour: string) => {
          Row() {
            Text(this.dayHourLabel(hour))
              .fontSize(12)
              .fontColor(TEXT_SECONDARY)
              .width(46)
              .textAlign(TextAlign.Start)
            Blank()
              .height(1)
              .layoutWeight(1)
              .backgroundColor("#E9EEF2")
          }
          .height(TIME_GRID_HOUR_HEIGHT)
          .width("100%")
          .position({ x: 0, y: this.hourIndex(hour) * TIME_GRID_HOUR_HEIGHT })
        }, (hour: string) => `day_line_${hour}`)

        if (this.nowIndicatorVisibleForDay(this.selectedDay)) {
          Row() {
            Text(this.nowTimeLabel())
              .fontSize(11)
              .fontColor(DAY_ACCENT_COLOR)
              .fontWeight(FontWeight.Bold)
              .width(46)
            Blank()
              .height(2)
              .layoutWeight(1)
              .backgroundColor(DAY_ACCENT_COLOR)
              .borderRadius(1)
          }
          .width("100%")
          .position({ x: 0, y: this.dayNowIndicatorTop() })
        }

        ForEach(this.eventLayoutsForDay(this.selectedDay), (layout: TimeGridEventLayout) => {
          Column() {
            Text(layout.event.title)
              .fontSize(12)
              .fontColor(this.eventCategoryColor(layout.event))
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.eventTimeChip(layout.event))
              .fontSize(11)
              .fontColor(TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .padding({ left: 8, right: 8, top: 6, bottom: 6 })
          .height(layout.height)
          .width(`${Math.floor(90 / layout.columnCount)}%`)
          .backgroundColor(this.eventChipBackground(layout.event))
          .borderRadius(8)
          .border({ width: 1, color: this.eventCategoryColor(layout.event) })
          .position({ x: `${6 + Math.floor(layout.column * 90 / layout.columnCount)}%`, y: Math.max(0, layout.top - TIME_GRID_HEADER_HEIGHT) })
          .onClick(() => {
            this.startEditing(layout.event);
            this.appPage = "editor";
            this.showAdvancedEventOptions = true;
          })
        }, (layout: TimeGridEventLayout) => `day_${layout.event.id}_${layout.column}_${layout.top}`)
      }
      .width("100%")
      .height((this.timeGridEndHour() - this.timeGridStartHour() + 1) * TIME_GRID_HOUR_HEIGHT)
      .padding({ left: 10, right: 10 })
    }
    .width("100%")
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(26)
    .border({ width: 1, color: BORDER_COLOR })
    .clip(true)
  }

  @Builder
  NewHomeMonthCalendar() {
    Column() {
      Row() {
        this.NewHomeMonthNavButton(-1)
        Column() {
          Text(formatMonthTitle(this.visibleMonth))
            .fontSize(18)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
          Text(`${this.eventCountForVisibleMonth()} 项日程`)
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        this.NewHomeMonthNavButton(1)
      }
      .height(46)
      .margin({ bottom: 8 })

      Grid() {
        ForEach(["一", "二", "三", "四", "五", "六", "日"], (label: string) => {
          GridItem() {
            Text(label)
              .fontSize(11)
              .fontColor(TEXT_SECONDARY)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }
        })

        ForEach(this.monthGridDaysMonday(this.visibleMonth), (day: number) => {
          GridItem() {
            this.NewHomeMonthCell(day)
          }
          .onClick(() => this.selectCalendarDay(day))
        }, (day: number) => `${day}`)
      }
      .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
      .columnsGap(5)
      .rowsGap(5)
    }
    .padding(12)
    .margin({ top: 6, bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewHomeMonthNavButton(direction: number) {
    Stack() {
      Text(direction < 0 ? "<" : ">")
        .fontSize(18)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width(40)
    .height(40)
    .backgroundColor(SOFT_SURFACE_COLOR)
    .borderRadius(12)
    .border({ width: 0.5, color: BORDER_COLOR })
    .onClick(async () => {
      this.visibleMonth = addMonths(this.visibleMonth, direction);
      this.selectedDay = this.sameMonth(Date.now(), this.visibleMonth) ? startOfDay(Date.now()) : this.visibleMonth;
      this.startInput = this.defaultStartText();
      this.endInput = this.defaultEndText();
      this.cancelEditing();
      await this.loadDateMarkers();
    })
  }

  @Builder
  NewHomeMonthCell(day: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Text(this.monthCellButtonText(day))
          .fontSize(13)
          .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : this.dayTextColor(day))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Row() {
          ForEach(this.dayEventColors(day), (color: string) => {
            Blank()
              .width(6)
              .height(6)
              .backgroundColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : color)
              .borderRadius(3)
              .margin({ right: 3 })
          }, (color: string) => `${day}_${color}`)
        }
        .height(10)
        .margin({ top: 5 })
      }
      .width("100%")
      .height("100%")
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width("100%")
    .height(64)
    .backgroundColor(this.monthCellBackground(day))
    .borderRadius(CONTROL_RADIUS)
    .border({ width: sameDay(day, this.selectedDay) || sameDay(day, Date.now()) ? 1 : 0.5, color: this.monthCellBorderColor(day) })
    .opacity(this.sameMonth(day, this.visibleMonth) ? 1 : 0.38)
    .onClick(() => this.selectCalendarDay(day))
  }

  @Builder
  NewViewSwitcher() {
    Row() {
      this.NewViewButton("年", "year")
      this.NewViewButton("月", "month")
      this.NewViewButton("周", "week")
      this.NewViewButton("日", "day")
    }
    .width("100%")
    .height(72)
    .padding(4)
    .backgroundColor("#F6F7F9")
    .borderRadius(36)
    .border({ width: 1, color: "#FCFCFD" })
    .shadow({ radius: 20, color: "#12000000", offsetX: 0, offsetY: 6 })
    .margin({ top: 8, bottom: 18 })
  }

  @Builder
  NewViewButton(label: string, value: string) {
    Button(label)
      .height(64)
      .width(0)
      .layoutWeight(1)
      .backgroundColor(this.scheduleView === value || (value === "day" && this.scheduleView === "list") ? SURFACE_COLOR : "#00000000")
      .fontColor(this.scheduleView === value || (value === "day" && this.scheduleView === "list") ? TEXT_PRIMARY : "#4A4F58")
      .fontWeight(FontWeight.Bold)
      .fontSize(16)
      .borderRadius(32)
      .onClick(async () => {
        this.scheduleView = value;
        this.showSearch = false;
        if (value === "month") {
          this.visibleMonth = this.monthStart(this.selectedDay);
        } else if (value === "year") {
          const date = new Date(this.selectedDay);
          this.visibleMonth = startOfDay(new Date(date.getFullYear(), 0, 1).getTime());
        }
      })
  }

  @Builder
  NewTodayHeroCard() {
    Row() {
      Column() {
        Text(this.todayHeroTitle())
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.todayHeroBody())
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(19)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
        Row() {
          this.NewSmallTag(this.localSyncSummary())
          this.NewSmallTag(`自动 ${this.autoSyncIntervalLabel()}`)
        }
        .margin({ top: 10 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      this.FocusRing()
    }
    .padding(14)
    .margin({ top: 10, bottom: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewMetricStrip() {
    Row() {
      this.NewMetricCard(`${this.eventCountForDay(this.selectedDay)}`, "今日事件")
      this.NewMetricCard(`${this.pendingUploadCount()}`, "待同步")
    }
    .height(78)
    .margin({ bottom: 10 })
  }

  @Builder
  NewMetricCard(value: string, label: string) {
    Column() {
      Text(value)
        .fontSize(22)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text(label)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
    .padding({ left: 12, right: 12 })
    .margin({ right: label === "待同步" ? 0 : 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewScheduleList(title: string, showAdd: boolean) {
    Column() {
      Row() {
        Text(title)
          .fontSize(24)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        if (this.searchKeyword.trim().length > 0) {
          Button("清空")
            .height(40)
            .width(70)
            .fontColor(PRIMARY_STRONG_COLOR)
            .fontWeight(FontWeight.Bold)
            .backgroundColor("#00000000")
            .borderRadius(CONTROL_RADIUS)
            .onClick(() => {
              this.searchKeyword = "";
            })
        } else if (showAdd) {
          Button("新增")
            .height(40)
            .width(70)
            .fontColor(PRIMARY_STRONG_COLOR)
            .fontWeight(FontWeight.Bold)
            .backgroundColor("#00000000")
            .borderRadius(CONTROL_RADIUS)
            .onClick(() => this.openNewEvent())
        }
      }
      .margin({ top: 4, bottom: 14 })

	      if (this.visibleEvents().length === 0) {
	        this.NewEmptyState()
	      } else {
        ForEach(this.visibleEvents(), (event: CalendarEvent) => {
          this.NewEventRow(event)
        }, (event: CalendarEvent) => event.id)
      }
    }
  }

  @Builder
  NewEmptyState() {
    Column() {
      Text(this.searchKeyword.trim().length > 0 ? "没有匹配的日程" : this.agendaEmptyText())
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text(this.searchKeyword.trim().length > 0 ? "调整关键词后再试" : "点 + 新建日程")
        .fontSize(12)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .width("100%")
    .padding(24)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(26)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewEventRow(event: CalendarEvent) {
    Row() {
      Text(this.eventTimeChip(event))
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .width(64)

      Column() {
        Text(event.title)
          .fontSize(17)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.eventTimelineMeta(event))
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()
        .width(12)
        .height(50)
        .backgroundColor(this.eventCategoryColor(event))
        .borderRadius(6)
        .margin({ left: 12 })
    }
    .height(94)
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(28)
    .border({ width: 1, color: BORDER_COLOR })
    .onClick(() => {
      this.startEditing(event);
      this.appPage = "editor";
      this.showAdvancedEventOptions = true;
    })
  }

  @Builder
  NewSmallTag(label: string) {
    Text(label)
      .fontSize(11)
      .fontColor(TEXT_SECONDARY)
      .fontWeight(FontWeight.Bold)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 9, right: 9, top: 4, bottom: 4 })
      .backgroundColor("#F4F5F7")
      .borderRadius(12)
      .margin({ right: 6 })
  }

  @Builder
  NewRangeToolbar() {
    Row() {
      this.NewArrowButton(-1)
      Column() {
        Text(this.headerTitle())
          .fontSize(18)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
        Text(this.scheduleSubtitle())
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)
      this.NewArrowButton(1)
    }
    .height(52)
    .margin({ top: 6, bottom: 12 })
  }

  @Builder
  NewArrowButton(direction: number) {
    Stack() {
      Text(direction < 0 ? "<" : ">")
        .fontSize(20)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width(52)
    .height(52)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(26)
    .border({ width: 1, color: BORDER_COLOR })
    .onClick(async () => await this.moveVisibleRange(direction))
  }

	  @Builder
  NewWeekGrid() {
	    Row() {
	      Column() {
	        ForEach(this.timeGridHourLabels(), (hour: string) => {
	          Text(hour)
	            .fontSize(10)
	            .fontColor(TEXT_SECONDARY)
	            .fontWeight(FontWeight.Bold)
	            .height(TIME_GRID_HOUR_HEIGHT)
	            .textAlign(TextAlign.Center)
	        }, (hour: string) => hour)
	      }
	      .width(32)
	      .padding({ top: TIME_GRID_HEADER_HEIGHT })

	      ForEach(this.rangeDaysForSelectedView(), (day: number) => {
	        this.NewWeekColumn(day)
	      }, (day: number) => `${day}`)
	    }
	    .height(this.timeGridTotalHeight())
	    .backgroundColor(SURFACE_COLOR)
	    .borderRadius(CARD_RADIUS)
	    .border({ width: 0.5, color: BORDER_COLOR })
	    .clip(true)
	  }

  @Builder
  NewWeekColumn(day: number) {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Text(`${this.weekdayLabel(day)} ${new Date(day).getDate()}`)
          .fontSize(11)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
        if (this.allDayEventsForDay(day).length > 0) {
          Text(this.allDaySummary(day))
            .fontSize(9)
            .fontColor(PRIMARY_STRONG_COLOR)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }
      }
      .height(TIME_GRID_HEADER_HEIGHT)
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
	      ForEach(this.timeGridHourLabels(), (hour: string) => {
	        Blank()
	          .height(1)
	          .width("100%")
	          .backgroundColor("#EDF2F7")
	          .position({ x: 0, y: TIME_GRID_HEADER_HEIGHT + this.hourIndex(hour) * TIME_GRID_HOUR_HEIGHT })
	      }, (hour: string) => `line_${day}_${hour}`)
	      if (this.nowIndicatorVisibleForDay(day)) {
	        Blank()
	          .height(2)
	          .width("100%")
	          .backgroundColor(PRIMARY_COLOR)
	          .position({ x: 0, y: this.nowIndicatorTop(day) })
	      }
	      ForEach(this.eventLayoutsForDay(day), (layout: TimeGridEventLayout) => {
	        Column() {
	          Text(layout.event.title)
	            .fontSize(10)
	            .fontColor(this.eventCategoryColor(layout.event))
	            .fontWeight(FontWeight.Bold)
	            .maxLines(2)
	            .textOverflow({ overflow: TextOverflow.Ellipsis })
	          Text(this.eventTimeChip(layout.event))
	            .fontSize(9)
	            .fontColor(TEXT_SECONDARY)
	            .maxLines(1)
	            .textOverflow({ overflow: TextOverflow.Ellipsis })
	            .margin({ top: 2 })
	        }
	        .alignItems(HorizontalAlign.Start)
	        .padding(5)
	        .height(layout.height)
	        .width(`${Math.floor(96 / layout.columnCount)}%`)
	        .backgroundColor(this.eventChipBackground(layout.event))
	        .borderRadius(7)
	        .border({ width: 1, color: this.eventCategoryColor(layout.event) })
	        .position({ x: `${Math.floor(layout.column * 100 / layout.columnCount)}%`, y: layout.top })
	        .onClick(() => {
	          this.startEditing(layout.event);
	          this.appPage = "editor";
	          this.showAdvancedEventOptions = true;
	        })
	      }, (layout: TimeGridEventLayout) => `${layout.event.id}_${layout.column}_${layout.top}`)
	    }
	    .layoutWeight(1)
	    .height("100%")
	    .padding({ left: 3, right: 3 })
	    .border({ width: { left: 0.5 }, color: "#EDF2F7" })
	  }

  @Builder
  NewMonthCard() {
    Column() {
      Grid() {
        ForEach(["一", "二", "三", "四", "五", "六", "日"], (label: string) => {
          GridItem() {
            Text(label)
              .fontSize(11)
              .fontColor(TEXT_SECONDARY)
              .fontWeight(FontWeight.Bold)
              .textAlign(TextAlign.Center)
          }
        })

        ForEach(this.monthGridDaysMonday(this.visibleMonth), (day: number) => {
          GridItem() {
            this.NewMonthCell(day)
          }
          .onClick(() => this.selectCalendarDay(day, "month"))
        }, (day: number) => `${day}`)
      }
      .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
      .columnsGap(5)
      .rowsGap(5)
    }
    .padding({ left: 14, right: 14, top: 12, bottom: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(26)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewMonthCell(day: number) {
    Stack({ alignContent: Alignment.Center }) {
      Column() {
        Text(this.monthCellButtonText(day))
          .fontSize(12)
          .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : this.dayTextColor(day))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textAlign(TextAlign.Center)
        Row() {
          ForEach(this.dayEventColors(day), (color: string) => {
            Blank()
              .width(6)
              .height(6)
              .backgroundColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : color)
              .borderRadius(3)
              .margin({ right: 3 })
          }, (color: string) => `month_${day}_${color}`)
        }
        .height(10)
        .margin({ top: 5 })
      }
      .width("100%")
      .height("100%")
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width("100%")
    .height(76)
    .backgroundColor(this.monthCellBackground(day))
    .borderRadius(22)
    .border({ width: sameDay(day, this.selectedDay) ? 0 : 0, color: this.monthCellBorderColor(day) })
    .opacity(this.sameMonth(day, this.visibleMonth) ? 1 : 0.4)
    .onClick(() => this.selectCalendarDay(day, "month"))
  }

  @Builder
  NewYearGrid() {
    Grid() {
      ForEach(this.yearMonths().slice(0, 12), (month: number) => {
        GridItem() {
          this.NewMiniMonth(month)
        }
      }, (month: number) => `${month}`)
    }
    .columnsTemplate("1fr 1fr")
    .columnsGap(14)
    .rowsGap(14)
  }

  @Builder
  NewMiniMonth(month: number) {
    Column() {
      Text(`${new Date(month).getMonth() + 1}月`)
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width("100%")
      Grid() {
        ForEach(this.compactMonthDays(month), (day: number) => {
          GridItem() {
            Column() {
              Text(`${new Date(day).getDate()}`)
                .fontSize(9)
                .fontColor(this.sameMonth(day, month) ? TEXT_PRIMARY : "#CBD5E1")
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Center)
              Blank()
                .width(10)
                .height(3)
                .backgroundColor(this.miniMonthDotColor(day, month))
                .borderRadius(2)
                .margin({ top: 2 })
            }
            .width("100%")
            .height(18)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          }
        }, (day: number) => `${month}_${day}`)
      }
      .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
      .columnsGap(4)
      .rowsGap(5)
      .margin({ top: 8 })
    }
    .height(160)
    .padding(12)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(24)
    .border({ width: 1, color: sameDay(month, this.monthStart(this.selectedDay)) ? PRIMARY_COLOR : BORDER_COLOR })
    .onClick(() => {
      this.visibleMonth = month;
      this.selectedDay = month;
      this.scheduleView = "month";
    })
  }

  @Builder
  NewBottomNav(active: string) {
    Row() {
      this.NewBottomNavItem("calendar", "今天", active)
      this.NewBottomNavItem("views", "视图", active)
      this.NewBottomNavItem("calendars", "日历源", active)
      this.NewBottomNavItem("settings", "设置", active)
    }
    .height(68)
    .padding(6)
    .margin({ left: 18, right: 18, top: 12, bottom: 78 })
    .backgroundColor("#F9FAFB")
    .borderRadius(34)
    .border({ width: 1, color: "#FCFCFD" })
    .shadow({ radius: 22, color: "#16000000", offsetX: 0, offsetY: 6 })
  }

  @Builder
  NewBottomNavItem(value: string, label: string, active: string) {
    Column() {
      this.NewNavIcon(value, active === value)
      Text(label)
        .fontSize(10)
        .fontColor(active === value ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 2 })
    }
    .height(56)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(active === value ? PRIMARY_SOFT_COLOR : "#00000000")
    .borderRadius(28)
    .onClick(async () => {
      if (value === "calendar") {
        await this.goToday();
        this.appPage = "calendar";
        this.scheduleView = "day";
      } else if (value === "views") {
        this.appPage = "calendar";
        if (this.scheduleView === "day" || this.scheduleView === "list") {
          this.scheduleView = "month";
          this.visibleMonth = this.monthStart(this.selectedDay);
        }
      } else if (value === "calendars") {
        this.appPage = "calendars";
      } else {
        this.appPage = "settings";
      }
    })
  }

  @Builder
  NewNavIcon(value: string, active: boolean) {
    Stack() {
      if (value === "calendar") {
        Blank()
          .width(18)
          .height(16)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(3)
        Blank()
          .width(18)
          .height(2)
          .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .translate({ y: -4 })
      } else if (value === "views") {
        Blank()
          .width(20)
          .height(20)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(4)
      } else if (value === "calendars") {
        Blank()
          .width(18)
          .height(18)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(4)
        Blank()
          .width(12)
          .height(12)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(3)
          .translate({ x: 4, y: 4 })
      } else {
        Circle()
          .width(18)
          .height(18)
          .stroke(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .strokeWidth(2)
        Circle()
          .width(6)
          .height(6)
          .fill(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
      }
    }
    .width(22)
    .height(22)
  }

  @Builder
  NewSourcesPage() {
    Column() {
      Row() {
        Column() {
          Text("账户与同步")
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
          Text("日历源")
            .fontSize(31)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        this.NewSquareIconButton("sync", false)
        this.NewSquareIconButton("add", true)
      }
      .padding({ left: 18, right: 18, top: 18, bottom: 8 })

      Scroll() {
        Column() {
          this.NewCalDavStatusCard()
          if (this.showAccountForm) {
            this.NewAccountFormCard()
          }
          this.NewAccountList()
        }
        .width("100%")
        .justifyContent(FlexAlign.Start)
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("calendars")
    }
    .height("100%")
  }

  @Builder
  NewCalDavStatusCard() {
    Row() {
      Stack() {
        Circle()
          .width(30)
          .height(30)
          .fill(BLUE_SOFT_COLOR)
        Circle()
          .width(12)
          .height(12)
          .fill(BLUE_COLOR)
      }
      .width(44)
      .height(44)
      Column() {
        Text(this.sources.length > 0 ? "CalDAV 源已配置" : "还没有 CalDAV 源")
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(`${this.sources.length} 个日历源，${this.visibleSourceCount()} 个显示，${this.pendingUploadCount()} 个本地修改等待上传`)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewAccountList() {
    Column() {
	      Row() {
	        Text("日历源列表")
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
	        Button("添加")
          .height(40)
          .width(70)
          .backgroundColor("#00000000")
          .fontColor(PRIMARY_STRONG_COLOR)
          .fontWeight(FontWeight.Bold)
          .borderRadius(CONTROL_RADIUS)
	          .onClick(() => this.newAccountForm())
	      }
	      .margin({ top: 16, bottom: 10 })

	      if (this.sources.length === 0) {
        this.NewEmptyAccountState()
      } else {
        ForEach(this.sources, (source: CalendarSource) => {
          this.NewSourceRow(source)
        }, (source: CalendarSource) => source.id ?? source.collectionUrl)
      }
    }
  }

	  @Builder
  NewRemoteSourceTools() {
    Column() {
      Text("远端 CalDAV 日历")
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      TextInput({ text: this.remoteSourceNameInput, placeholder: "新日历名称，例如 项目排期" })
        .height(44)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.remoteSourceNameInput = value;
        })
        Button("创建远端 CalDAV")
        .height(42)
        .width("100%")
        .backgroundColor(SOFT_SURFACE_COLOR)
        .fontColor(PRIMARY_STRONG_COLOR)
        .fontWeight(FontWeight.Bold)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onClick(async () => await this.createRemoteSource())
      Text("源行里的改名按钮会使用这里的名称，颜色使用当前事件颜色。")
        .fontSize(11)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: 6 })
      Row() {
        TextInput({ text: this.sourceShareEmailInput, placeholder: "共享成员邮箱" })
          .height(42)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.sourceShareEmailInput = value;
          })
        Blank().width(8)
        Button(this.sourceShareRoleInput === "write" ? "可写" : "只读")
          .height(42)
          .width(64)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => {
            this.sourceShareRoleInput = this.sourceShareRoleInput === "write" ? "read" : "write";
          })
      }
      .margin({ top: 8 })
      Text("源行里的共享按钮会把成员写入本地共享权限字段，远端授权需服务商支持。")
        .fontSize(11)
        .fontColor(TEXT_SECONDARY)
        .margin({ top: 6 })
    }
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
	    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewResourceTools() {
    Column() {
      Text("会议室与资源")
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Row() {
        TextInput({ text: this.resourceNameInput, placeholder: "名称，例如 A101 会议室" })
          .height(42)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.resourceNameInput = value;
          })
        Blank().width(8)
        Button(this.resourceTypeLabel(this.resourceTypeInput))
          .height(42)
          .width(72)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => this.cycleResourceType())
      }
      .margin({ top: 8 })
      Row() {
        TextInput({ text: this.resourceEmailInput, placeholder: "邮箱/CalDAV 地址，可空" })
          .height(42)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.resourceEmailInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.resourceCapacityInput, placeholder: "容量" })
          .height(42)
          .width(64)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onChange((value: string) => {
            this.resourceCapacityInput = value;
          })
      }
      .margin({ top: 8 })
      TextInput({ text: this.resourceLocationInput, placeholder: "位置，例如 3F 东区" })
        .height(42)
        .fontSize(12)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.resourceLocationInput = value;
        })
      Row() {
        Button(`归属：${this.resourceSourceName()}`)
          .height(42)
          .layoutWeight(1)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => this.cycleResourceSource())
        Blank().width(8)
        Button("新增资源")
          .height(42)
          .width(92)
          .fontSize(12)
          .fontColor("#FFFFFF")
          .fontWeight(FontWeight.Bold)
          .backgroundColor(PRIMARY_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(async () => await this.saveResource())
      }
      .margin({ top: 8 })
      if (this.resources.length > 0) {
        ForEach(this.visibleResources(), (resource: CalendarResource) => {
          this.NewResourceRow(resource)
        }, (resource: CalendarResource) => resource.id ?? resource.name)
      }
    }
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewResourceRow(resource: CalendarResource) {
    Row() {
      Blank()
        .width(8)
        .height(34)
        .backgroundColor(this.normalizedCategoryColor(resource.color ?? PRIMARY_COLOR))
        .borderRadius(4)
      Column() {
        Text(resource.name)
          .fontSize(13)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.resourceMeta(resource))
          .fontSize(11)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 })
      Button("用到事件")
        .height(30)
        .width(76)
        .fontSize(11)
        .fontColor(PRIMARY_STRONG_COLOR)
        .backgroundColor("#00000000")
        .borderRadius(CONTROL_RADIUS)
        .onClick(() => this.useResourceInForm(resource))
      Button("删")
        .height(30)
        .width(36)
        .fontSize(11)
        .fontColor(DANGER_COLOR)
        .backgroundColor("#00000000")
        .borderRadius(CONTROL_RADIUS)
        .onClick(async () => await this.removeResource(resource))
    }
    .height(48)
    .padding({ left: 8, right: 4 })
    .margin({ top: 8 })
    .backgroundColor(SOFT_SURFACE_COLOR)
    .borderRadius(CONTROL_RADIUS)
  }

	  @Builder
	  NewEmptyAccountState() {
    Column() {
      Text("还没有日历源")
        .fontSize(16)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Text("添加 Zoho、iCloud、Nextcloud 或自定义 CalDAV 源。")
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .lineHeight(19)
        .textAlign(TextAlign.Center)
        .margin({ top: 6 })
      Button("添加 CalDAV")
        .height(46)
        .width("100%")
        .backgroundColor(PRIMARY_COLOR)
        .fontColor("#FFFFFF")
        .fontWeight(FontWeight.Bold)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 12 })
        .onClick(() => this.newAccountForm())
    }
    .width("100%")
    .padding(16)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
	  }

	  @Builder
	  NewSubscriptionTools() {
	    Column() {
	      Text("订阅与 ICS")
	        .fontSize(16)
	        .fontColor(TEXT_PRIMARY)
	        .fontWeight(FontWeight.Bold)
	      TextInput({ text: this.subscriptionNameInput, placeholder: "订阅名称，例如 节假日" })
	        .height(44)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.subscriptionNameInput = value;
	        })
	      TextInput({ text: this.subscriptionUrlInput, placeholder: "webcal:// 或 https://...ics" })
	        .height(44)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.subscriptionUrlInput = value;
	        })
	      Row() {
	        Button("添加订阅")
	          .height(42)
	          .layoutWeight(1)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .fontColor(PRIMARY_STRONG_COLOR)
	          .fontWeight(FontWeight.Bold)
	          .borderRadius(CONTROL_RADIUS)
	          .onClick(async () => await this.saveSubscriptionSource())
	        Blank().width(8)
	        Button("导出 ICS")
	          .height(42)
	          .layoutWeight(1)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .fontColor(TEXT_PRIMARY)
	          .fontWeight(FontWeight.Bold)
	          .borderRadius(CONTROL_RADIUS)
	          .onClick(async () => await this.exportIcsText())
	      }
	      .margin({ top: 10 })
	      TextInput({ text: this.icsTextInput, placeholder: "粘贴 ICS 文本导入；导出结果也会显示在这里" })
	        .height(88)
	        .fontSize(12)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.icsTextInput = value;
	        })
	      Button("导入 ICS")
	        .height(42)
	        .width("100%")
	        .backgroundColor(PRIMARY_COLOR)
	        .fontColor("#FFFFFF")
	        .fontWeight(FontWeight.Bold)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8, bottom: 10 })
	        .onClick(async () => await this.importIcsText())
	    }
	    .padding(12)
	    .margin({ bottom: 10 })
	    .backgroundColor(SURFACE_COLOR)
	    .borderRadius(CARD_RADIUS)
	    .border({ width: 0.5, color: BORDER_COLOR })
	  }

	  @Builder
	  NewSourceRow(source: CalendarSource) {
    Row() {
	      Blank()
	        .width(12)
	        .height(54)
	        .backgroundColor(this.sourceBackgroundColor(source))
	        .borderRadius(6)
	      Column() {
	        Text(source.name)
	          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
	        Text(source.collectionUrl)
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
	        Row() {
	          this.NewSmallTag(source.isDefault ? "默认新增" : "可选")
	          this.NewSmallTag(source.isVisible ? "已显示" : "已隐藏")
	          this.NewSmallTag(this.sourceTypeLabel(source))
	          if ((source.providerType ?? "").length > 0 && (source.providerType ?? "custom") !== "custom") {
	            this.NewSmallTag(source.providerType ?? "")
	          }
	          if (source.isReadOnly) {
	            this.NewSmallTag("只读")
	          }
	        }
	        .margin({ top: 5 })
	        Text(this.sourceSyncMeta(source))
	          .fontSize(11)
	          .fontColor(source.lastSyncError !== undefined && source.lastSyncError.length > 0 ? DANGER_COLOR : TEXT_SECONDARY)
	          .maxLines(1)
	          .textOverflow({ overflow: TextOverflow.Ellipsis })
	          .margin({ top: 5 })
	        Text(`颜色 ${this.sourceColor(source)} · ${this.sourceEventCount(source)} 项日程`)
	          .fontSize(11)
	          .fontColor(TEXT_SECONDARY)
	          .maxLines(1)
	          .textOverflow({ overflow: TextOverflow.Ellipsis })
	          .margin({ top: 4 })
	      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Column() {
        this.SwitchMark(source.isVisible)
        Button(source.isVisible ? "隐藏" : "显示")
          .height(30)
          .width(62)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .backgroundColor("#00000000")
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 5 })
          .onClick(async () => await this.toggleSourceVisibility(source))
	        Button(source.isDefault ? "默认" : "设默认")
          .height(30)
          .width(62)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor("#00000000")
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 2 })
	          .onClick(async () => await this.setDefaultSource(source))
		        Button("刷新")
	          .height(30)
	          .width(62)
	          .fontSize(12)
	          .fontColor(PRIMARY_STRONG_COLOR)
	          .backgroundColor("#00000000")
	          .borderRadius(CONTROL_RADIUS)
		          .margin({ top: 2 })
		          .onClick(async () => await this.refreshSource(source))
		        Button(this.sourceFilterActive(source) ? "取消筛" : "筛选")
		          .height(30)
		          .width(62)
		          .fontSize(12)
		          .fontColor(this.sourceFilterActive(source) ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
		          .backgroundColor("#00000000")
		          .borderRadius(CONTROL_RADIUS)
		          .margin({ top: 2 })
		          .onClick(async () => await this.toggleSourceFilter(source))
		        Button("换色")
		          .height(30)
		          .width(62)
		          .fontSize(12)
		          .fontColor(PRIMARY_STRONG_COLOR)
		          .backgroundColor("#00000000")
		          .borderRadius(CONTROL_RADIUS)
		          .margin({ top: 2 })
		          .onClick(async () => await this.cycleSourceColor(source))
			        Button(this.remoteDeleteConfirmSourceId === (source.id ?? "") ? "确认删" : "删除")
		          .height(30)
		          .width(62)
		          .fontSize(12)
		          .fontColor(this.remoteDeleteConfirmSourceId === (source.id ?? "") ? "#FFFFFF" : DANGER_COLOR)
		          .backgroundColor(this.remoteDeleteConfirmSourceId === (source.id ?? "") ? DANGER_COLOR : "#00000000")
		          .borderRadius(CONTROL_RADIUS)
		          .margin({ top: 2 })
		          .onClick(async () => {
		            if (this.remoteDeleteConfirmSourceId === (source.id ?? "")) {
		              await this.removeSource(source);
		            } else {
		              this.remoteDeleteConfirmSourceId = source.id ?? "";
		              this.syncStatus = `再次点击确认删除本地日历源：${source.name}`;
		            }
		          })
	      }
      .alignItems(HorizontalAlign.Center)
    }
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewAccountRow(account: CalendarAccount) {
    Row() {
      Blank()
        .width(12)
        .height(50)
        .backgroundColor(account.isActive === true ? PRIMARY_COLOR : WARNING_COLOR)
        .borderRadius(6)
      Column() {
        Text(this.accountTitle(account))
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(account.serverUrl)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
        Row() {
          this.NewSmallTag(account.isActive === true ? "默认新增" : "未启用")
          this.NewSmallTag(account.username.length > 0 ? account.username : "未填账号")
          this.NewSmallTag(account.providerType ?? this.providerTypeFromServerUrl(account.serverUrl))
        }
        .margin({ top: 5 })
        Text(this.accountProviderMeta(account))
          .fontSize(11)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      Column() {
        this.SwitchMark(account.isActive === true)
        Button("编辑")
          .height(30)
          .width(54)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor("#00000000")
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 5 })
          .onClick(() => this.editAccount(account))
      }
      .alignItems(HorizontalAlign.Center)
    }
    .padding(12)
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
    .onClick(async () => {
      if (account.isActive !== true) {
        await this.activateAccount(account);
      }
    })
  }

  @Builder
  NewAccountFormCard() {
    Column() {
      Row() {
        Text((this.accountIdInput.length > 0 ? "编辑" : "添加") + " CalDAV")
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Button("关闭")
          .height(38)
          .width(66)
          .fontColor(TEXT_SECONDARY)
          .backgroundColor("#00000000")
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => this.closeAccountForm())
      }

      this.FieldLabel("服务商")
	      Row() {
	        this.ProviderButton("Zoho", "zoho")
	        Blank().width(8)
	        this.ProviderButton("iCloud", "icloud")
	        Blank().width(8)
	        this.ProviderButton("Nextcloud", "nextcloud")
	      }
	      .margin({ top: 8 })
	      Row() {
	        this.ProviderButton("Google", "google")
	        Blank().width(8)
	        this.ProviderButton("Fastmail", "fastmail")
	        Blank().width(8)
	        this.ProviderButton("ownCloud", "owncloud")
	      }
      .margin({ top: 8 })
	      Row() {
	        this.ProviderButton("Baikal", "baikal")
	        Blank().width(8)
	        this.ProviderButton("Radicale", "radicale")
	        Blank().width(8)
	        this.ProviderButton("SabreDAV", "sabre")
	      }
	      .margin({ top: 8 })
	      Row() {
	        this.ProviderButton("Yahoo", "yahoo")
	        Blank().width(8)
	        this.ProviderButton("自定义", "custom")
	      }
	      .margin({ top: 8 })

      this.FieldLabel("显示名称")
      TextInput({ text: this.accountNameInput, placeholder: "工作日历" })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.accountNameInput = value;
        })

      this.FieldLabel("服务器地址")
      TextInput({ text: this.serverUrl, placeholder: DEFAULT_ZOHO_CALDAV_URL })
        .height(48)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.serverUrl = value;
        })

      this.FieldLabel("用户名")
      TextInput({ text: this.username, placeholder: this.accountUsernamePlaceholder() })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.username = value;
        })

      this.FieldLabel("密码")
      TextInput({ text: this.password, placeholder: this.accountPasswordPlaceholder() })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.password = value;
        })

      this.FieldLabel("认证方式")
      Row() {
        ConfigButton({ label: "Basic", value: "auth:basic", active: this.authTypeInput === "basic", onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: "Bearer", value: "auth:bearer", active: this.authTypeInput === "bearer", onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: "无认证", value: "auth:none", active: this.authTypeInput === "none", onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: "自定义", value: "auth:custom", active: this.authTypeInput === "custom", onClickAction: (v) => this.updateViewConfig(v) })
      }
      .margin({ top: 8 })

      if (this.authTypeInput === "bearer") {
        TextInput({ text: this.bearerTokenInput, placeholder: "Bearer 访问令牌" })
          .height(48)
          .fontSize(13)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.bearerTokenInput = value;
          })
      }

      if (this.authTypeInput === "custom") {
        TextInput({ text: this.customHeadersJsonInput, placeholder: "额外请求头 JSON，例如 {\"authorization\":\"Bearer ...\",\"x-api-key\":\"...\"}" })
          .height(48)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 8 })
          .onChange((value: string) => {
            this.customHeadersJsonInput = value;
          })
      }

      if (this.accountFormStatus.length > 0) {
        Text(this.accountFormStatus)
          .fontSize(12)
          .fontColor(this.accountFormStatusColor())
          .lineHeight(18)
          .padding(10)
          .width("100%")
          .backgroundColor(this.accountFormStatusBackground())
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 10 })
      }

      Row() {
        Button(this.isTestingConnection ? "测试中" : "测试连接")
          .height(48)
          .layoutWeight(1)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .borderRadius(CONTROL_RADIUS)
          .onClick(async () => await this.testConnection())
        Blank().width(10)
        Button(this.isSavingAccount ? "保存中" : "保存日历源")
          .height(48)
          .layoutWeight(1)
          .backgroundColor(PRIMARY_COLOR)
          .fontColor("#FFFFFF")
          .fontWeight(FontWeight.Bold)
          .borderRadius(CONTROL_RADIUS)
          .onClick(async () => await this.saveAccount())
      }
      .margin({ top: 14 })
    }
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewSettingsPage() {
    Column() {
      this.NewSubTopBar("偏好与系统", "设置", "")
      Scroll() {
        Column() {
          this.NewSectionCaption("日历视图")
          this.NewSettingsGroup()
          this.NewSectionCaption("同步与存储")
          this.NewSyncSettingsGroup()
        }
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      this.NewBottomNav("settings")
    }
    .height("100%")
  }

  @Builder
  NewSettingsGroup() {
    Column() {
        Text(this.settingsRenderKey.toString()).fontSize(0).width(0).height(0).visibility(Visibility.None)
	      this.NewSettingSelectRow("默认打开视图", "进入应用时优先显示的视图", this.defaultViewLabel(), this.defaultViewSelectOptions(), this.defaultViewSelectIndex(), "defaultView")
	      this.NewSettingSelectRow("每周开始于", "影响周视图和月历周序", this.weekStartLabel(), this.weekStartSelectOptions(), this.weekStartSelectIndex(), "weekStart")
	      this.NewSettingSelectRow("默认提醒", "新建日程默认提醒时间", this.defaultReminderLabel(), this.defaultReminderSelectOptions(), this.defaultReminderSelectIndex(), "defaultReminder")
	      this.NewSettingSelectRow("时区", "新建日程默认使用的 TZID", this.currentTimeZoneLabel(), this.timeZoneSelectOptions(), this.timeZoneSelectIndex(), "timeZone")
	      Row() {
	        ConfigButton({ label: "系统主题", value: "theme:system", active: (this.viewConfig.themeMode ?? "system") === "system", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "浅色", value: "theme:light", active: this.viewConfig.themeMode === "light", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "深色", value: "theme:dark", active: this.viewConfig.themeMode === "dark", onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: this.viewConfig.reminderVibrate === false ? "震动关" : "震动开", value: "vibrate", active: this.viewConfig.reminderVibrate !== false, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "默认铃声", value: "sound:default", active: (this.viewConfig.reminderSound ?? "default") === "default", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "轻提示", value: "sound:soft", active: this.viewConfig.reminderSound === "soft", onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
	    }
    .margin({ top: 6 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(28)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewViewConfigGroup() {
    Column() {
        Text(this.settingsRenderKey.toString()).fontSize(0).width(0).height(0).visibility(Visibility.None)
      Text("视图配置")
        .fontSize(18)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 12, right: 12, top: 12 })
      Row() {
        ConfigButton({ label: "08-21", value: "hours:8:21", active: this.viewConfig.minHour === 8 && this.viewConfig.maxHour === 21, onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: "06-22", value: "hours:6:22", active: this.viewConfig.minHour === 6 && this.viewConfig.maxHour === 22, onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: "全天", value: "hours:0:23", active: this.viewConfig.minHour === 0 && this.viewConfig.maxHour === 23, onClickAction: (v) => this.updateViewConfig(v) })
      }
      .height(48)
      .padding({ left: 12, right: 12, top: 8 })
      Row() {
	        ConfigButton({ label: "点数3", value: "dots:3", active: this.viewConfig.maxVisibleEventsPerDay === 3, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "点数5", value: "dots:5", active: this.viewConfig.maxVisibleEventsPerDay === 5, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.viewConfig.swipeEnabled ? "滑动开" : "滑动关", value: "swipe", active: this.viewConfig.swipeEnabled, onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
      Row() {
	        ConfigButton({ label: (this.viewConfig.weekEndsOn ?? 0) === 0 ? "周末到周日" : "周末到周六", value: "weekEnd", active: (this.viewConfig.weekEndsOn ?? 0) === 0, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.viewConfig.showSixWeeks === false ? "动态周数" : "固定六周", value: "sixWeeks", active: this.viewConfig.showSixWeeks !== false, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: (this.viewConfig.hourFormat ?? "24h") === "24h" ? "24小时" : "12小时", value: "hourFormat", active: (this.viewConfig.hourFormat ?? "24h") === "24h", onClickAction: (v) => this.updateViewConfig(v) })
      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: "中文", value: "locale:zh-CN", active: (this.viewConfig.locale ?? "zh-CN") === "zh-CN", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "English", value: "locale:en-US", active: this.viewConfig.locale === "en-US", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "全视图", value: "views:all", active: (this.viewConfig.enabledViewsJson ?? "").length === 0, onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: "全部类型", value: "kind:all", active: (this.viewConfig.eventKindFilter ?? "all") === "all", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "任务", value: "kind:task", active: this.viewConfig.eventKindFilter === "task", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "预约", value: "kind:appointment", active: this.viewConfig.eventKindFilter === "appointment", onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: "专注", value: "kind:focus", active: this.viewConfig.eventKindFilter === "focus", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "提醒", value: "kind:reminder", active: this.viewConfig.eventKindFilter === "reminder", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: "日历", value: "kind:calendar", active: this.viewConfig.eventKindFilter === "calendar", onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: this.viewConfig.hideCancelledEvents === true ? "隐藏取消" : "显示取消", value: "hideCancelled", active: this.viewConfig.hideCancelledEvents === true, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.viewConfig.showIncompleteTasksOnly === true ? "仅未完成" : "全部任务", value: "incompleteTasks", active: this.viewConfig.showIncompleteTasksOnly === true, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.activeSourceFilterIds().length > 0 ? "清源过滤" : "全部源", value: "clearSourceFilter", active: this.activeSourceFilterIds().length === 0, onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: this.viewConfig.showAdjacentMonths === false ? "隐藏邻月" : "显示邻月", value: "adjacentMonths", active: this.viewConfig.showAdjacentMonths !== false, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.viewConfig.nowIndicatorVisible === false ? "隐藏当前线" : "显示当前线", value: "nowIndicator", active: this.viewConfig.nowIndicatorVisible !== false, onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: (this.viewConfig.scrollOffsetMinutes ?? 480) === 480 ? "滚动08:00" : "滚动06:00", value: "scrollOffset", active: (this.viewConfig.scrollOffsetMinutes ?? 480) === 480, onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: (this.viewConfig.monthMoreLabel ?? "更多") === "更多" ? "更多" : "+N", value: "monthMoreLabel", active: (this.viewConfig.monthMoreLabel ?? "更多") === "更多", onClickAction: (v) => this.updateViewConfig(v) })
        ConfigButton({ label: (this.viewConfig.eventOrder ?? "start,title") === "start,title" ? "开始排序" : "标题排序", value: "eventOrder", active: (this.viewConfig.eventOrder ?? "start,title") === "start,title", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: this.viewConfig.agendaShowPastDays === true ? "Agenda含过去" : "Agenda今天后", value: "agendaPast", active: this.viewConfig.agendaShowPastDays === true, onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8 })
	      Row() {
	        ConfigButton({ label: (this.viewConfig.agendaGroupMode ?? "day") === "day" ? "按天分组" : "按源分组", value: "agendaGroup", active: (this.viewConfig.agendaGroupMode ?? "day") === "day", onClickAction: (v) => this.updateViewConfig(v) })
	        ConfigButton({ label: (this.viewConfig.agendaEmptyText ?? "当天没有日程") === "当天没有日程" ? "空文案短" : "空文案长", value: "agendaEmpty", active: (this.viewConfig.agendaEmptyText ?? "当天没有日程") === "当天没有日程", onClickAction: (v) => this.updateViewConfig(v) })
	      }
	      .height(48)
	      .padding({ left: 12, right: 12, top: 8, bottom: 12 })
	    }
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }


  // Replaced by ConfigButton component below

  @Builder
  NewDateMarkerGroup() {
    Column() {
        Text(this.settingsRenderKey.toString()).fontSize(0).width(0).height(0).visibility(Visibility.None)
      Text("日期标记")
        .fontSize(18)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
      TextInput({ text: this.markerTitleInput, placeholder: "标记标题，例如 发布日" })
        .height(44)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 10 })
        .onChange((value: string) => {
          this.markerTitleInput = value;
        })
      Row() {
        TextInput({ text: this.markerDateInput, placeholder: "开始 2026-06-01" })
          .height(44)
          .fontSize(13)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.markerDateInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.markerEndDateInput, placeholder: "结束 可空" })
          .height(44)
          .fontSize(13)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.markerEndDateInput = value;
          })
      }
      .margin({ top: 8 })
      Row() {
        this.NewMarkerTypeButton("点", "dot")
        this.NewMarkerTypeButton("多点", "multi-dot")
        this.NewMarkerTypeButton("区间", "period")
        Button("添加")
          .height(38)
          .layoutWeight(1)
          .backgroundColor(PRIMARY_COLOR)
          .fontColor("#FFFFFF")
          .fontWeight(FontWeight.Bold)
          .borderRadius(CONTROL_RADIUS)
          .fontSize(13)
          .onClick(async () => await this.addDateMarkerFromForm())
      }
      .height(48)
      .margin({ top: 8 })
      Row() {
        this.NewMarkerTypeButton("多段", "multi-period")
        this.NewMarkerTypeButton("自定义", "custom")
      }
      .height(48)
      .margin({ top: 4 })

      ForEach(this.recentDateMarkers(), (marker: CalendarDateMarker) => {
        this.NewDateMarkerRow(marker)
      }, (marker: CalendarDateMarker) => marker.id ?? `${marker.markerDate}`)
    }
    .padding(12)
    .margin({ top: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  NewMarkerTypeButton(label: string, value: string) {
    Button(label)
      .height(38)
      .layoutWeight(1)
      .backgroundColor(this.markerTypeInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.markerTypeInput === value ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
      .fontWeight(FontWeight.Bold)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(13)
      .margin({ right: 6 })
      .onClick(() => {
        this.markerTypeInput = value;
      })
  }

  private dateMarkerTypeValue(): CalendarDateMarkingType {
    if (this.markerTypeInput === "multi-dot" || this.markerTypeInput === "period" ||
      this.markerTypeInput === "multi-period" || this.markerTypeInput === "custom") {
      return this.markerTypeInput as CalendarDateMarkingType;
    }

    return "dot";
  }

  @Builder
  NewDateMarkerRow(marker: CalendarDateMarker) {
    Row() {
      Blank()
        .width(10)
        .height(36)
        .backgroundColor(this.normalizedCategoryColor(marker.color ?? marker.periodColor ?? PRIMARY_COLOR))
        .borderRadius(5)
      Column() {
        Text(marker.title !== undefined && marker.title.length > 0 ? marker.title : this.markerTypeLabel(marker.markingType))
          .fontSize(14)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(this.markerDateLabel(marker))
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 10 })
      Button("删除")
        .height(32)
        .width(54)
        .fontSize(12)
        .fontColor(DANGER_COLOR)
        .backgroundColor("#00000000")
        .borderRadius(CONTROL_RADIUS)
        .onClick(async () => await this.removeDateMarker(marker))
    }
    .height(54)
    .border({ width: { top: 0.5 }, color: "#EDF2F7" })
  }

  @Builder
  NewSyncSettingsGroup() {
    Column() {
        Text(this.settingsRenderKey.toString()).fontSize(0).width(0).height(0).visibility(Visibility.None)
      this.NewAutoSyncIntervalRow()
      this.NewSettingStatusRow("后台自动同步", "新增、修改、删除后立即在后台同步", "已启用")
      this.NewSettingStatusRow("本地加密缓存", "RDB Store S3 已启用", "已启用")
    }
    .margin({ top: 6 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(28)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewSectionCaption(title: string) {
    Text(title)
      .fontSize(14)
      .fontColor(TEXT_SECONDARY)
      .fontWeight(FontWeight.Medium)
      .width("100%")
      .textAlign(TextAlign.Start)
      .margin({ top: 18, bottom: 10, left: 4 })
  }

  @Builder
  NewAutoSyncIntervalRow() {
    Row() {
      Column() {
        Text("自动同步时间")
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text("周期刷新 CalDAV，操作后仍会立即后台同步")
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Select(this.autoSyncOptions())
        .selected(this.autoSyncIntervalIndex)
        .value(this.autoSyncIntervalLabel())
        .font({ size: 13, weight: FontWeight.Bold })
        .fontColor(PRIMARY_STRONG_COLOR)
        .selectedOptionFont({ size: 13, weight: FontWeight.Bold })
        .optionFont({ size: 13 })
        .backgroundColor(PRIMARY_SOFT_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .width(96)
        .height(38)
        .onSelect((index: number) => {
          this.autoSyncIntervalIndex = index;
          this.resetAutoSyncTimer();
        })
    }
    .height(82)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .border({ width: { bottom: 1 }, color: "#EFF1F4" })
  }

  @Builder
  NewSettingSelectRow(title: string, body: string, selectedValue: string, options: SelectOption[], selectedIndex: number, action: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Select(options)
        .selected(selectedIndex)
        .value(selectedValue)
        .font({ size: 13, weight: FontWeight.Bold })
        .fontColor(PRIMARY_STRONG_COLOR)
        .selectedOptionFont({ size: 13, weight: FontWeight.Bold })
        .optionFont({ size: 13 })
        .backgroundColor(PRIMARY_SOFT_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .width(176)
        .height(38)
        .onSelect((index: number) => {
          this.updateSettingSelect(action, index);
        })
    }
    .height(82)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .border({ width: { bottom: 1 }, color: "#EFF1F4" })
  }

  @Builder
  NewSettingStatusRow(title: string, body: string, status: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(status)
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
    }
    .height(82)
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .border({ width: { bottom: 1 }, color: "#EFF1F4" })
  }

  @Builder
  NewSettingRow(title: string, body: string, showSwitch: boolean) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      if (showSwitch) {
        this.SwitchMark(true)
      } else {
        Text(">")
          .fontSize(20)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
      }
    }
    .height(66)
    .padding(12)
    .border({ width: { bottom: 0.5 }, color: "#EDF2F7" })
  }

  @Builder
  NewSettingActionRow(title: string, body: string, action: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Button("切换")
        .height(38)
        .width(76)
        .fontSize(13)
        .fontColor(PRIMARY_STRONG_COLOR)
        .fontWeight(FontWeight.Bold)
        .backgroundColor(PRIMARY_SOFT_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .onClick(async () => await this.updateViewConfig(action))
    }
    .height(66)
    .padding(12)
    .border({ width: { bottom: 0.5 }, color: "#EDF2F7" })
  }

  @Builder
  NewEditorPage() {
    Column() {
      this.NewSubTopBar(this.editingEventId.length > 0 ? "编辑日程" : "添加到默认日历", this.editingEventId.length > 0 ? "编辑日程" : "新建日程", "save")
      Scroll() {
        Column() {
          this.NewEventQuickForm()
          if (this.showAdvancedEventOptions) {
            this.NewEventAdvancedForm()
          } else {
            Button("更多选项")
              .height(48)
              .width("100%")
              .backgroundColor(SOFT_SURFACE_COLOR)
              .fontColor(TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .borderRadius(CONTROL_RADIUS)
              .margin({ top: 12 })
              .onClick(() => {
                this.showAdvancedEventOptions = true;
              })
          }
	          if (this.editingEventHasConflict()) {
	            this.NewEditingConflictActions()
	          }
	          if (this.editingEventId.length > 0) {
	            Button("删除日程")
              .height(48)
              .width("100%")
              .backgroundColor(DANGER_SOFT_COLOR)
              .fontColor(DANGER_COLOR)
              .fontWeight(FontWeight.Bold)
              .borderRadius(CONTROL_RADIUS)
              .margin({ top: 12 })
              .onClick(async () => {
                const event: CalendarEvent | null = this.editingEvent();
                if (event !== null) {
                  await this.deleteEvent(event);
                  this.appPage = "calendar";
                }
              })
          }
        }
        .padding({ left: 18, right: 18, bottom: 28 })
      }
      .layoutWeight(1)
    }
    .height("100%")
	  }

	  @Builder
	  NewEditingConflictActions() {
	    ForEach(this.editingConflictEvents(), (event: CalendarEvent) => {
	      this.NewConflictActions(event)
	    }, (event: CalendarEvent) => event.id)
	  }

	  private editingConflictEvents(): CalendarEvent[] {
	    const event: CalendarEvent | null = this.editingEvent();
	    if (event == null || (event.conflictStatus ?? "none") === "none") {
	      return [];
	    }
	    return [event];
	  }

	  @Builder
	  NewConflictActions(event: CalendarEvent) {
	    Column() {
	      Text("同步冲突")
	        .fontSize(16)
	        .fontColor(DANGER_COLOR)
	        .fontWeight(FontWeight.Bold)
	      Text(this.conflictSummary(event))
	        .fontSize(12)
	        .fontColor(TEXT_SECONDARY)
	        .lineHeight(18)
	        .margin({ top: 4 })
	      Row() {
	        Button("保留本地")
	          .height(42)
	          .layoutWeight(1)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .fontColor(PRIMARY_STRONG_COLOR)
	          .fontWeight(FontWeight.Bold)
	          .borderRadius(CONTROL_RADIUS)
	          .onClick(async () => await this.resolveConflict(event, "local"))
	        Blank().width(8)
	        Button("使用远端")
	          .height(42)
	          .layoutWeight(1)
	          .backgroundColor(DANGER_SOFT_COLOR)
	          .fontColor(DANGER_COLOR)
	          .fontWeight(FontWeight.Bold)
	          .borderRadius(CONTROL_RADIUS)
	          .onClick(async () => await this.resolveConflict(event, "remote"))
	      }
	      .margin({ top: 10 })
	    }
	    .padding(12)
	    .margin({ top: 12 })
	    .backgroundColor(SURFACE_COLOR)
	    .borderRadius(CARD_RADIUS)
	    .border({ width: 0.5, color: DANGER_SOFT_COLOR })
	  }

	  @Builder
	  NewEventQuickForm() {
    Column() {
      this.EventKindTabs()
      this.FieldLabel("标题")
      TextInput({ text: this.titleInput, placeholder: "添加标题" })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.titleInput = value;
          this.clearFormError();
        })

      if (this.formError.length > 0) {
        Text(this.formError)
          .fontSize(12)
          .fontColor(DANGER_COLOR)
          .backgroundColor(DANGER_SOFT_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .padding(10)
          .width("100%")
          .margin({ top: 10 })
      }

      this.FieldLabel("时间")
      Row() {
        this.NewDateTimeButton("开始", this.startInput, "start")
        Blank().width(10)
        this.NewDateTimeButton("结束", this.endInput, "end")
      }
      .margin({ top: 8 })

      Row() {
        Column() {
          Text("全天")
            .fontSize(16)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
          Text("关闭后显示开始和结束时间")
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        this.SwitchMark(this.allDayInput)
      }
      .height(56)
      .onClick(() => {
        this.allDayInput = !this.allDayInput;
      })

      this.FieldLabel("保存到")
      this.NewDefaultAccountPicker()

      this.FieldLabel("提醒")
      Row() {
        this.ReminderOption("不提醒", "0")
        this.ReminderOption("10 分钟", "10")
        this.ReminderOption("30 分钟", "30")
      }
      .height(38)
      .margin({ top: 8 })

	      if (this.formConflictSummary().length > 0) {
	        Text(this.formConflictSummary())
          .fontSize(12)
          .fontColor(DANGER_COLOR)
          .backgroundColor(DANGER_SOFT_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .padding(10)
          .margin({ top: 10 })
      }

      Button(this.editingEventId.length > 0 ? "保存修改" : "保存日程")
        .height(52)
        .width("100%")
        .backgroundColor(PRIMARY_COLOR)
        .fontColor("#FFFFFF")
        .fontWeight(FontWeight.Bold)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 14 })
        .onClick(async () => await this.saveEventForm())
    }
    .padding(18)
    .margin({ top: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(28)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewDateTimeButton(label: string, value: string, target: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
      Button(target === "start" ? this.startInput : this.endInput)
        .height(54)
        .width("100%")
        .backgroundColor("#F7F8FA")
        .fontColor(TEXT_PRIMARY)
        .fontSize(12)
        .borderRadius(18)
        .margin({ top: 6 })
        .onClick(() => this.pickDateTime(target))
    }
    .alignItems(HorizontalAlign.Start)
    .layoutWeight(1)
  }

  @Builder
  NewDefaultAccountPicker() {
    Row() {
      Blank()
        .width(12)
        .height(34)
        .backgroundColor(this.formSourceColor())
        .borderRadius(6)
      Column() {
        Text(this.formSourceTitle())
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(this.formSourceSubtitle())
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      Text(">")
        .fontSize(20)
        .fontColor(TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
    }
    .height(62)
    .padding({ left: 14, right: 14 })
    .margin({ top: 8 })
    .backgroundColor("#F7F8FA")
    .borderRadius(20)
    .onClick(() => {
      if (this.editingEventId.length > 0) {
        this.appPage = "calendars";
      } else {
        this.cycleFormSource();
      }
    })
  }

  @Builder
  NewEventAdvancedForm() {
    Column() {
      this.FieldLabel("地点")
      TextInput({ text: this.locationInput, placeholder: "线上会议或地点" })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.locationInput = value;
        })

      this.FieldLabel("会议链接")
      TextInput({ text: this.conferenceUrlInput, placeholder: "https://meeting.example.com/room/1024" })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.conferenceUrlInput = value;
        })

	      this.FieldLabel("参会人")
	      TextInput({ text: this.attendeesInput, placeholder: "designer@example.com, pm@example.com" })
        .height(48)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.attendeesInput = value;
	        })

	      this.FieldLabel("重复")
	      Row() {
	        this.NewRRuleChip("不重复", "")
        this.NewRRuleChip("每天", "FREQ=DAILY")
        this.NewRRuleChip("每周", "FREQ=WEEKLY")
        this.NewRRuleChip("每月", "FREQ=MONTHLY")
	      }
	      .height(38)
	      .margin({ top: 8 })
	      if (this.editingEventId.length > 0 && this.rruleInput.trim().length > 0) {
	        Row() {
	          this.RecurrenceScopeButton("本次", "instance")
	          this.RecurrenceScopeButton("整个系列", "series")
	          this.RecurrenceScopeButton("未来", "future")
	        }
	        .height(38)
	        .margin({ top: 8 })
	      }

      this.FieldLabel("状态")
      Row() {
        this.EventStatusButton("已确认", "confirmed")
        this.EventStatusButton("暂定", "tentative")
        this.EventStatusButton("已取消", "cancelled")
      }
      .height(38)
      .margin({ top: 8 })

      this.FieldLabel("忙闲")
      Row() {
        this.AvailabilityButton("显示为忙", "busy")
        this.AvailabilityButton("显示为空闲", "free")
      }
      .height(38)
      .margin({ top: 8 })

      this.FieldLabel("隐私")
      Row() {
        this.PrivacyButton("默认", "default")
        this.PrivacyButton("公开", "public")
        this.PrivacyButton("私密", "private")
        this.PrivacyButton("机密", "confidential")
      }
      .height(38)
      .margin({ top: 8 })

      this.FieldLabel("颜色")
      this.ColorPaletteGrid()

      this.FieldLabel("备注")
      TextInput({ text: this.notesInput, placeholder: "备注" })
        .height(72)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.notesInput = value;
        })
    }
    .padding(18)
    .margin({ top: 12 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(28)
    .border({ width: 1, color: BORDER_COLOR })
  }

  @Builder
  NewRRuleChip(label: string, value: string) {
    Button(label)
      .height(34)
      .layoutWeight(1)
      .backgroundColor(this.rruleInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.rruleInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(12)
      .margin({ right: label === "每月" ? 0 : 8 })
      .onClick(() => {
        this.rruleInput = value;
      })
  }

  @Builder
  CalendarPage() {
    if (this.scheduleView === "month") {
      this.MonthScreen()
    } else {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            if (this.showSearch) {
              this.SearchCard()
            }
            this.WeekStrip()
            this.ViewSwitcher()
            this.OverviewStrip()
            this.SchedulePanel()
            this.BottomNav("calendar")
          }
          .padding({ left: 18, right: 18, bottom: 26 })
        }
        .layoutWeight(1)
      }
      .height("100%")
    }
  }

  @Builder
  MonthScreen() {
    Column() {
      Scroll() {
        Column() {
          this.SubPageHeader(`${new Date(this.visibleMonth).getFullYear()}`, `${new Date(this.visibleMonth).getMonth() + 1}月`, true)
          this.MonthCard()
          this.SchedulePanel()
          this.BottomNav("month")
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 26 })
      }
      .layoutWeight(1)
    }
    .height("100%")
  }

  @Builder
  Header() {
    Column() {
      Row() {
        Column() {
          Text(this.topbarDateText())
            .fontSize(13)
            .fontColor(TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
          Text(this.topbarTitle())
            .fontSize(34)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Bold)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          this.HeaderIconButton("search")
          this.HeaderIconButton("add")
        }
        .margin({ left: 16 })
      }
      .alignItems(VerticalAlign.Top)

      if (this.shouldShowHeaderStatus()) {
        Text(this.compactSyncStatus())
          .fontSize(12)
          .fontColor(this.compactSyncStatusColor())
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .alignSelf(ItemAlign.Center)
          .margin({ top: 10 })
      }
    }
    .padding({ left: 18, right: 18, top: 18, bottom: 8 })
    .backgroundColor(PAGE_COLOR)
  }

  @Builder
  HeaderIconButton(kind: string) {
    Stack() {
      if (kind === "add" || kind === "add-calendar") {
        Row() {
          Blank()
            .width(18)
            .height(2.5)
            .backgroundColor("#FFFFFF")
            .borderRadius(2)
        }
        .width("100%")
        .justifyContent(FlexAlign.Center)
        Row() {
          Blank()
            .width(2.5)
            .height(18)
            .backgroundColor("#FFFFFF")
            .borderRadius(2)
        }
        .width("100%")
        .justifyContent(FlexAlign.Center)
      } else if (kind === "search") {
        Column() {
          Row() {
            Blank()
              .width(17)
              .height(17)
              .border({ width: 2, color: TEXT_PRIMARY })
              .borderRadius(9)
          }
          .width(24)
          .height(17)
          .justifyContent(FlexAlign.Center)
          Row() {
            Blank()
              .width(8)
              .height(2)
              .backgroundColor(TEXT_PRIMARY)
              .borderRadius(1)
              .rotate({ angle: 45 })
          }
          .width(24)
          .height(7)
          .justifyContent(FlexAlign.End)
          .margin({ top: -2 })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        this.SettingsGridIcon()
      }
    }
    .width(44)
    .height(44)
    .backgroundColor(kind === "add" || kind === "add-calendar" ? PRIMARY_COLOR : SOFT_SURFACE_COLOR)
    .borderRadius(22)
    .border({ width: kind === "add" || kind === "add-calendar" ? 0 : 0.5, color: BORDER_COLOR })
    .onClick(() => {
      if (kind === "add") {
        this.openNewEvent();
      } else if (kind === "add-calendar") {
        if (this.appPage === "calendar") {
          this.openNewEvent();
        } else {
          this.showAccountForm = false;
        }
      } else if (kind === "search") {
        this.showSearch = !this.showSearch;
      } else {
        this.openSettings();
      }
    })
  }

  @Builder
  SettingsGridIcon() {
    Grid() {
      ForEach([0, 1, 2, 3], (item: number) => {
        GridItem() {
          Row() {
            Blank()
              .width(7)
              .height(7)
              .backgroundColor(TEXT_PRIMARY)
              .borderRadius(4)
          }
          .width("100%")
          .height("100%")
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
      }, (item: number) => `${item}`)
    }
    .width(22)
    .height(22)
    .columnsTemplate("1fr 1fr")
    .rowsTemplate("1fr 1fr")
    .columnsGap(6)
    .rowsGap(6)
  }

  @Builder
  OverviewStrip() {
    Row() {
      Column() {
        Text(this.todaySummaryTitle())
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.todaySummaryBody())
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(20)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.FocusRing()
    }
    .padding(17)
    .margin({ top: 14 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  FocusRing() {
    Stack() {
      Circle()
        .width(72)
        .height(72)
        .fill(PRIMARY_SOFT_COLOR)
      Row() {
        Blank()
          .width(20)
          .height(64)
          .backgroundColor(PRIMARY_COLOR)
          .borderRadius(12)
        Blank()
          .width(16)
          .height(52)
          .backgroundColor(BLUE_COLOR)
          .borderRadius(10)
          .margin({ left: 4 })
        Blank()
          .width(12)
          .height(38)
          .backgroundColor(WARNING_COLOR)
          .borderRadius(8)
          .margin({ left: 4 })
      }
      .alignItems(VerticalAlign.Center)
      Circle()
        .width(48)
        .height(48)
        .fill(SURFACE_COLOR)
      Text(`${this.eventCountForDay(this.selectedDay)}`)
        .fontSize(21)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width(72)
    .height(72)
    .margin({ left: 14 })
  }

  @Builder
  WeekStrip() {
    Row() {
      ForEach(this.weekDaysForSelectedDay(), (day: number) => {
        this.WeekDayPill(day)
      }, (day: number) => `${day}`)
    }
    .margin({ top: 12, bottom: 14 })
  }

  @Builder
  WeekDayPill(day: number) {
    Column() {
      Text(this.weekdayLabel(day))
        .fontSize(11)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_SECONDARY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => this.selectCalendarDay(day, "day"))
      Text(`${new Date(day).getDate()}`)
        .fontSize(17)
        .fontColor(sameDay(day, this.selectedDay) ? "#FFFFFF" : TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 4 })
        .onClick(() => this.selectCalendarDay(day, "day"))
    }
    .height(62)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .backgroundColor(sameDay(day, this.selectedDay) ? PRIMARY_COLOR : "#00000000")
    .borderRadius(18)
    .margin({ right: sameDay(day, this.weekDaysForSelectedDay()[6]) ? 0 : 7 })
    .onClick(() => this.selectCalendarDay(day, "day"))
  }

  @Builder
  ViewSwitcher() {
    Row() {
      this.ViewButton("日", "day")
      this.ViewButton("周", "week")
      this.ViewButton("月", "month")
    }
    .height(48)
    .padding(5)
    .backgroundColor(SOFT_SURFACE_COLOR)
    .borderRadius(18)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  SettingsPage() {
    Column() {
      Scroll() {
        Column() {
          this.SubPageHeader("偏好", "设置", false)
          this.ProfileCard()
          this.PreferenceCard()
          this.SettingsList()
          this.ImportSheet()
          this.BottomNav("settings")
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 26 })
      }
      .layoutWeight(1)
    }
    .height("100%")
  }

  @Builder
  CalendarsPage() {
    Column() {
      Scroll() {
        Column() {
          this.SubPageHeader("账户与分类", "我的日历", true)
          this.CalendarSummaryCard()
          Row() {
            Text("日历列表")
              .fontSize(22)
              .fontColor(TEXT_PRIMARY)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
            Button("全选")
              .height(40)
              .width(70)
              .backgroundColor("#00000000")
              .fontColor(PRIMARY_STRONG_COLOR)
              .fontWeight(FontWeight.Bold)
              .borderRadius(CONTROL_RADIUS)
          }
          .margin({ top: 20, bottom: 10 })
          this.CalendarListRows()
          this.SyncAccountSheet()
          this.BottomNav("calendars")
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 26 })
      }
      .layoutWeight(1)
    }
    .height("100%")
  }

  @Builder
  SubPageHeader(kicker: string, title: string, showAdd: boolean) {
    Row() {
      this.BackButton()
      Column() {
        Text(kicker)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
        Text(title)
          .fontSize(34)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      if (showAdd) {
        this.HeaderIconButton("add-calendar")
      }
    }
    .alignItems(VerticalAlign.Top)
    .margin({ bottom: 14 })
  }

  @Builder
  BackButton() {
    Stack() {
      Text("<")
        .fontSize(22)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width(44)
    .height(44)
    .backgroundColor(SOFT_SURFACE_COLOR)
    .borderRadius(22)
    .border({ width: 0.5, color: BORDER_COLOR })
    .onClick(() => {
      if (this.appPage === "editor") {
        this.closeEditor();
      } else {
        this.appPage = "calendar";
      }
    })
  }

  @Builder
  ProfileCard() {
    Row() {
      Text("林")
        .fontSize(20)
        .fontColor(PRIMARY_STRONG_COLOR)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(52)
        .height(52)
        .backgroundColor(TINT_SURFACE_COLOR)
        .borderRadius(18)
      Column() {
        Text("林一")
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text("默认工作日历 · 中国标准时间")
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .padding(14)
    .margin({ bottom: 13 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  PreferenceCard() {
    Column() {
      this.FieldLabel("默认打开视图")
      Row() {
        this.PreferenceSegment("今天", true)
        this.PreferenceSegment("周", false)
        this.PreferenceSegment("月", false)
      }
      .height(48)
      .padding(5)
      .backgroundColor(SOFT_SURFACE_COLOR)
      .borderRadius(18)
      .border({ width: 0.5, color: BORDER_COLOR })
      .margin({ top: 8 })

      this.FieldLabel("每周开始于")
      Button("周一")
        .height(46)
        .width("100%")
        .backgroundColor(SOFT_SURFACE_COLOR)
        .fontColor(TEXT_PRIMARY)
        .borderRadius(CONTROL_RADIUS)
        .fontSize(14)
        .margin({ top: 8 })
    }
    .padding(16)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  PreferenceSegment(label: string, active: boolean) {
    Button(label)
      .height(38)
      .layoutWeight(1)
      .backgroundColor(active ? SURFACE_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(active ? TEXT_PRIMARY : TEXT_SECONDARY)
      .fontWeight(FontWeight.Bold)
      .borderRadius(14)
      .fontSize(14)
      .margin({ right: label === "月" ? 0 : 4 })
  }

  @Builder
  SettingsList() {
    Column() {
      this.SettingRow("日程前提醒", "默认提前 15 分钟", true)
      this.SettingRow("空档建议", "在首页显示可安排时间", true)
      this.SettingRow("会议链接置顶", "日程开始前在详情页显示", false)
    }
    .margin({ top: 13 })
  }

  @Builder
  SettingRow(title: string, body: string, enabled: boolean) {
    Row() {
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      this.SwitchMark(enabled)
    }
    .padding(14)
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  SwitchMark(enabled: boolean) {
    Row() {
      Blank()
        .width(enabled ? 22 : 3)
      Circle()
        .width(24)
        .height(24)
        .fill(SURFACE_COLOR)
      Blank()
        .width(enabled ? 3 : 22)
    }
    .width(52)
    .height(30)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(enabled ? PRIMARY_COLOR : "#E4E6EA")
    .borderRadius(15)
  }

  @Builder
  CalendarStackMark() {
    Column() {
      Row() {
        Blank()
          .width(28)
          .height(28)
          .backgroundColor(WARNING_COLOR)
          .borderRadius(12)
        Blank()
          .layoutWeight(1)
      }
      .height(28)
      Row() {
        Blank()
          .layoutWeight(1)
        Blank()
          .width(44)
          .height(44)
          .backgroundColor(BLUE_COLOR)
          .borderRadius(16)
      }
      .height(46)
      .margin({ top: -12 })
    }
    .width(74)
    .height(74)
    .backgroundColor(PRIMARY_COLOR)
    .borderRadius(24)
  }

  @Builder
  ImportSheet() {
    Row() {
      Stack() {
        Text("+")
          .fontSize(28)
          .fontColor(PRIMARY_STRONG_COLOR)
      }
      .width(42)
      .height(42)
      .backgroundColor(TINT_SURFACE_COLOR)
      .borderRadius(14)

      Column() {
        Text("导入外部日历")
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text("支持 ICS、企业邮箱和系统日历同步")
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .padding(16)
    .margin({ top: 3 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  CalendarSummaryCard() {
    Row() {
      Column() {
        Text(`${this.accounts.length > 0 ? this.accounts.length : 5} 个日历，4 个已显示`)
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text("隐藏低优先级日历可以让首页更聚焦，颜色用于区分事件来源。")
          .fontSize(14)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(20)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()
        .width(14)
      this.CalendarStackMark()
    }
    .padding(17)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  CalendarListRows() {
    Column() {
      this.CalendarVisibilityRow("工作日历", "18 个未来日程 · 默认新增", PRIMARY_COLOR, true)
      this.CalendarVisibilityRow("项目日历", "7 个未来日程 · 团队共享", BLUE_COLOR, true)
      this.CalendarVisibilityRow("个人安排", "3 个未来日程 · 仅自己可见", WARNING_COLOR, true)
      this.CalendarVisibilityRow("订阅节假日", "已隐藏 · 不影响提醒", DANGER_COLOR, false)
    }
  }

  @Builder
  CalendarVisibilityRow(title: string, body: string, color: string, enabled: boolean) {
    Row() {
      Blank()
        .width(12)
        .height(42)
        .backgroundColor(color)
        .borderRadius(6)
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(body)
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
      this.SwitchMark(enabled)
    }
    .padding(14)
    .margin({ bottom: 10 })
    .opacity(enabled ? 1 : 0.72)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  SyncAccountSheet() {
    Row() {
      Stack() {
        Circle()
          .width(28)
          .height(28)
          .stroke(PRIMARY_STRONG_COLOR)
          .strokeWidth(2)
        Circle()
          .width(10)
          .height(10)
          .fill(PRIMARY_STRONG_COLOR)
      }
      .width(42)
      .height(42)

      Column() {
        Text("同步账户")
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
        Text(this.accounts.length > 0 ? this.accountTitle(this.accounts[0]) : "iCloud、企业邮箱、Exchange")
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

    }
    .padding(16)
    .margin({ top: 3 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  MonthCard() {
    Column() {
      this.MonthToolbar()

      Grid() {
        ForEach(["一", "二", "三", "四", "五", "六", "日"], (label: string) => {
          GridItem() {
            Text(label)
              .fontSize(12)
              .fontColor(TEXT_SECONDARY)
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
          }
        })

        ForEach(this.monthGridDaysMonday(this.visibleMonth), (day: number) => {
          GridItem() {
            this.DayCell(day)
          }
          .onClick(() => this.selectCalendarDay(day, "day"))
        }, (day: number) => `${day}`)
      }
      .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr 1fr")
      .rowsGap(7)
      .columnsGap(7)
      .margin({ top: 12 })
    }
    .padding(14)
    .margin({ top: 14 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  MonthToolbar() {
    Row() {
      this.MonthArrowButton(-1)
      Text(`${new Date(this.selectedDay).getMonth() + 1}月 ${new Date(this.selectedDay).getDate()}日 · ${sameDay(this.selectedDay, Date.now()) ? "今天" : "所选日期"}`)
        .fontSize(15)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .layoutWeight(1)
      this.MonthArrowButton(1)
    }
    .height(44)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  MonthArrowButton(direction: number) {
    Stack() {
      Text(direction < 0 ? "<" : ">")
        .fontSize(18)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
    }
    .width(40)
    .height(40)
    .backgroundColor(SOFT_SURFACE_COLOR)
    .borderRadius(20)
    .border({ width: 0.5, color: BORDER_COLOR })
    .onClick(async () => await this.moveVisibleRange(direction))
  }

  @Builder
  BottomNav(active: string) {
    Row() {
      this.BottomNavItem("calendar", "日历", active)
      this.BottomNavItem("month", "月视图", active)
      this.BottomNavItem("calendars", "日历", active)
      this.BottomNavItem("settings", "设置", active)
    }
    .height(70)
    .padding(10)
    .margin({ top: 20 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(24)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  BottomNavItem(value: string, label: string, active: string) {
    Column() {
      this.NavIcon(value, active === value)
      Text(label)
        .fontSize(11)
        .fontColor(active === value ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 3 })
    }
    .height(50)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
    .backgroundColor(active === value ? TINT_SURFACE_COLOR : "#00000000")
    .borderRadius(17)
    .margin({ right: value === "settings" ? 0 : 6 })
    .onClick(() => {
      if (value === "calendar") {
        this.scheduleView = "day";
        this.appPage = "calendar";
      } else if (value === "month") {
        this.scheduleView = "month";
        this.visibleMonth = this.monthStart(this.selectedDay);
        this.appPage = "calendar";
      } else if (value === "calendars") {
        this.appPage = "calendars";
      } else if (value === "settings") {
        this.openSettings();
      }
    })
  }

  @Builder
  NavIcon(value: string, active: boolean) {
    Stack() {
      if (value === "calendar") {
        Blank()
          .width(18)
          .height(16)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(3)
        Blank()
          .width(18)
          .height(2)
          .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .translate({ y: -4 })
      } else if (value === "month") {
        Column() {
          Blank()
            .width(20)
            .height(2)
            .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
            .borderRadius(1)
          Blank()
            .width(20)
            .height(2)
            .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
            .borderRadius(1)
            .margin({ top: 5 })
          Blank()
            .width(14)
            .height(2)
            .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
            .borderRadius(1)
            .margin({ top: 5 })
        }
      } else if (value === "calendars") {
        Blank()
          .width(16)
          .height(20)
          .border({ width: 2, color: active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY })
          .borderRadius(3)
        Blank()
          .width(10)
          .height(2)
          .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .translate({ y: -4 })
        Blank()
          .width(10)
          .height(2)
          .backgroundColor(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .translate({ y: 2 })
      } else {
        Circle()
          .width(18)
          .height(18)
          .stroke(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
          .strokeWidth(2)
        Circle()
          .width(6)
          .height(6)
          .fill(active ? PRIMARY_STRONG_COLOR : TEXT_SECONDARY)
      }
    }
    .width(22)
    .height(22)
  }

  @Builder
  SearchCard() {
    Column() {
      this.FieldLabel("查找日程")
      TextInput({ text: this.searchKeyword, placeholder: "搜索标题、地点或备注" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.searchKeyword = value;
        })
      if (this.searchKeyword.trim().length > 0) {
        Button("清空搜索")
          .height(38)
          .width("100%")
          .backgroundColor(WARNING_SOFT_COLOR)
          .fontColor(WARNING_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .margin({ top: 10 })
          .onClick(() => {
            this.searchKeyword = "";
          })
      }
    }
    .padding(14)
    .margin({ top: 14 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  ViewButton(label: string, value: string) {
    Button(label)
      .height(38)
      .layoutWeight(1)
      .backgroundColor(this.scheduleView === value ? SURFACE_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.scheduleView === value ? TEXT_PRIMARY : TEXT_SECONDARY)
      .borderRadius(14)
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .margin({ left: value === "day" ? 0 : 4 })
      .onClick(() => {
        this.scheduleView = value;
        if (value === "month") {
          this.visibleMonth = this.monthStart(this.selectedDay);
        }
      })
  }

  @Builder
  FieldLabel(label: string) {
    Text(label)
      .fontSize(13)
      .fontColor(TEXT_SECONDARY)
      .fontWeight(FontWeight.Medium)
      .width("100%")
      .textAlign(TextAlign.Start)
      .margin({ top: 16 })
  }

  @Builder
  ProviderButton(label: string, value: string) {
    Button(label)
      .height(38)
      .width(0)
      .layoutWeight(1)
      .backgroundColor(value === "custom" ? SOFT_SURFACE_COLOR : PRIMARY_SOFT_COLOR)
      .fontColor(value === "custom" ? TEXT_PRIMARY : PRIMARY_COLOR)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(13)
      .onClick(() => this.applyProviderPreset(value))
  }

  @Builder
  EventKindTabs() {
    Column() {
      Row() {
        this.EventKindButton("日历", "calendar")
        this.EventKindButton("重要日", "important")
        this.EventKindButton("提醒", "reminder")
        this.EventKindButton("外出", "outOfOffice")
      }
      .height(52)
    }
    .padding(4)
    .backgroundColor("#ECEEF2")
    .borderRadius(26)
    .margin({ top: 12 })
  }

  @Builder
  EventKindButton(label: string, value: CalendarEventKind) {
    Button(label)
      .height(44)
      .layoutWeight(1)
      .backgroundColor(this.eventKindInput === value ? SURFACE_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.eventKindInput === value ? TEXT_PRIMARY : TEXT_SECONDARY)
      .borderRadius(22)
      .fontSize(14)
      .onClick(() => this.selectEventKind(value))
  }

  @Builder
  AvailabilityButton(label: string, value: CalendarAvailability) {
    Button(label)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.availabilityInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.availabilityInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(12)
      .margin({ right: value === "free" ? 0 : 8 })
      .onClick(() => {
        this.availabilityInput = value;
      })
  }

  @Builder
  PrivacyButton(label: string, value: CalendarPrivacy) {
    Button(label)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.privacyInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.privacyInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(12)
      .margin({ right: value === "confidential" ? 0 : 8 })
      .onClick(() => {
        this.privacyInput = value;
      })
  }

  @Builder
	  EventStatusButton(label: string, value: CalendarEventStatus) {
    Button(label)
      .height(36)
      .layoutWeight(1)
      .backgroundColor(this.eventStatusInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.eventStatusInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(12)
      .margin({ right: value === "cancelled" ? 0 : 8 })
      .onClick(() => {
        this.eventStatusInput = value;
	      })
	  }

	  @Builder
	  AppointmentStatusButton(label: string, value: CalendarAppointmentStatus) {
	    Button(label)
	      .height(36)
	      .layoutWeight(1)
	      .backgroundColor(this.appointmentStatusInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
	      .fontColor(this.appointmentStatusInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
	      .borderRadius(CONTROL_RADIUS)
	      .fontSize(12)
	      .margin({ right: value === "cancelled" ? 0 : 8 })
	      .onClick(() => {
	        this.appointmentStatusInput = value;
	      })
	  }

	  @Builder
	  AttendeeRoleButton(label: string, value: string) {
	    Button(label)
	      .height(34)
	      .layoutWeight(1)
	      .backgroundColor(this.attendeeRoleInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
	      .fontColor(this.attendeeRoleInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
	      .borderRadius(CONTROL_RADIUS)
	      .fontSize(11)
	      .margin({ right: 6 })
	      .onClick(() => {
	        this.attendeeRoleInput = value;
	      })
	  }

	  @Builder
	  AttendeeStatusButton(label: string, value: string) {
	    Button(label)
	      .height(34)
	      .layoutWeight(1)
	      .backgroundColor(this.attendeeStatusInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
	      .fontColor(this.attendeeStatusInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
	      .borderRadius(CONTROL_RADIUS)
	      .fontSize(11)
	      .margin({ right: 6 })
	      .onClick(() => {
	        this.attendeeStatusInput = value;
	      })
	  }

	  @Builder
	  RecurrenceScopeButton(label: string, value: string) {
	    Button(label)
	      .height(36)
	      .layoutWeight(1)
	      .backgroundColor(this.recurrenceEditScope === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
	      .fontColor(this.recurrenceEditScope === value ? PRIMARY_COLOR : TEXT_PRIMARY)
	      .borderRadius(CONTROL_RADIUS)
	      .fontSize(12)
	      .margin({ right: value === "future" ? 0 : 8 })
	      .onClick(() => {
	        this.recurrenceEditScope = value;
	      })
	  }

	  @Builder
	  PaletteButton(label: string, value: string) {
    Button(label)
      .height(34)
      .layoutWeight(1)
      .backgroundColor(this.colorPaletteInput === value ? PRIMARY_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.colorPaletteInput === value ? PRIMARY_COLOR : TEXT_PRIMARY)
      .borderRadius(CONTROL_RADIUS)
      .fontSize(12)
      .margin({ right: value === "focus" ? 0 : 8 })
      .onClick(() => {
        this.colorPaletteInput = value;
      })
  }

  @Builder
  ColorPaletteGrid() {
    Grid() {
      ForEach(this.activeColorPalette(), (color: string) => {
        GridItem() {
          this.ColorSwatch(color)
        }
      }, (color: string) => color)
    }
    .columnsTemplate("1fr 1fr 1fr 1fr 1fr 1fr")
    .columnsGap(8)
    .rowsGap(8)
    .margin({ top: 10 })
  }

  @Builder
  ColorSwatch(color: string) {
    Column() {
      Blank()
        .width(30)
        .height(30)
        .backgroundColor(color)
        .borderRadius(15)
        .border({ width: this.normalizedCategoryColor(this.categoryColorInput) === color ? 3 : 0, color: TEXT_PRIMARY })
    }
    .height(42)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.normalizedCategoryColor(this.categoryColorInput) === color ? "#FFFFFF" : SOFT_SURFACE_COLOR)
    .borderRadius(CONTROL_RADIUS)
    .onClick(() => {
      this.categoryColorInput = color;
    })
  }

  @Builder
  ReminderOption(label: string, minutes: string) {
    Button(label)
      .height(38)
      .layoutWeight(1)
      .backgroundColor(this.reminderInput === minutes ? SUCCESS_SOFT_COLOR : SOFT_SURFACE_COLOR)
      .fontColor(this.reminderInput === minutes ? SUCCESS_COLOR : TEXT_PRIMARY)
      .borderRadius(16)
      .fontSize(12)
      .margin({ right: label === "30 分钟" || label === "重要" ? 0 : 8 })
      .onClick(() => {
        this.reminderInput = minutes;
        this.clearFormError();
      })
  }

  @Builder
  DateTimeField(label: string, value: string, target: string) {
    Column() {
      Text(label)
        .fontSize(12)
        .fontColor(TEXT_SECONDARY)
        .width("100%")
        .textAlign(TextAlign.Start)
      Button(target === "start" ? this.startInput : this.endInput)
        .height(52)
        .width("100%")
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 6 })
        .onClick(() => this.pickDateTime(target))
    }
    .alignItems(HorizontalAlign.Start)
    .width("100%")
    .margin({ top: target === "end" ? 10 : 0 })
  }

  @Builder
  DayCell(day: number) {
    Button(`${new Date(day).getDate()}`)
    .width("100%")
    .height(42)
    .backgroundColor(this.dayCellBackground(day))
    .borderRadius(12)
    .border({ width: this.dayCellBorderWidth(day), color: this.dayCellBorderColor(day) })
    .fontColor(this.dayTextColor(day))
    .fontSize(13)
    .fontWeight(FontWeight.Bold)
    .onClick(() => this.selectCalendarDay(day, "day"))
  }

  @Builder
  SchedulePanel() {
    Column() {
      Row() {
        Text(this.scheduleTitle())
          .fontSize(22)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        if (this.searchKeyword.trim().length > 0) {
          Button("清空")
            .height(40)
            .width(70)
            .backgroundColor("#00000000")
            .fontColor(PRIMARY_STRONG_COLOR)
            .borderRadius(CONTROL_RADIUS)
            .margin({ left: 8 })
            .onClick(() => {
              this.searchKeyword = "";
            })
        } else {
          Button("新增")
            .height(40)
            .width(70)
            .backgroundColor("#00000000")
            .fontColor(PRIMARY_STRONG_COLOR)
            .borderRadius(CONTROL_RADIUS)
            .margin({ left: 8 })
            .onClick(() => this.openNewEvent())
        }
      }
      .margin({ top: 20, bottom: 10 })

      if (this.visibleEvents().length === 0) {
        Column() {
          Text(this.searchKeyword.trim().length > 0 ? "没有匹配的日程" : "当前日期没有日程")
            .fontSize(15)
            .fontColor(TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)
          Text(this.searchKeyword.trim().length > 0 ? "调整关键词后再试" : "点右上角 + 新建日程")
            .fontSize(12)
            .fontColor(TEXT_SECONDARY)
            .margin({ top: 6 })
        }
        .width("100%")
        .padding(18)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(SURFACE_COLOR)
        .borderRadius(CARD_RADIUS)
        .border({ width: 0.5, color: BORDER_COLOR })
      } else {
        ForEach(this.visibleEvents(), (event: CalendarEvent) => {
          this.EventRow(event)
        }, (event: CalendarEvent) => event.id)
      }
    }
    .width("100%")
  }

  @Builder
  EventRow(event: CalendarEvent) {
    Row() {
      Text(this.eventTimeChip(event))
        .fontSize(13)
        .fontColor(TEXT_SECONDARY)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .width(54)

      Column() {
        Text(event.title)
          .fontSize(16)
          .fontColor(TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.eventTimelineMeta(event))
          .fontSize(13)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(18)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Blank()
        .width(10)
        .height(42)
        .backgroundColor(this.eventCategoryColor(event))
        .borderRadius(6)
        .margin({ left: 12 })
    }
    .height(76)
    .padding({ left: 13, right: 13 })
    .margin({ bottom: 10 })
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
    .onClick(() => {
      this.startEditing(event);
      this.appPage = "editor";
    })
  }

  @Builder
  EventFormCard() {
    Column() {
      Text("基本信息")
        .fontSize(18)
        .fontColor(TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .width("100%")

      this.EventKindTabs()

      this.FieldLabel("标题")
      TextInput({ text: this.titleInput, placeholder: "标题" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.titleInput = value;
          this.clearFormError();
        })

      if (this.formError.length > 0) {
        Text(this.formError)
          .fontSize(12)
          .fontColor(DANGER_COLOR)
          .backgroundColor(DANGER_SOFT_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .width("100%")
          .margin({ top: 8 })
      }

      this.FieldLabel("时间")
      Column() {
        this.DateTimeField("开始", this.startInput, "start")
        this.DateTimeField("结束", this.endInput, "end")
      }
      .margin({ top: 10 })

      Row() {
        Checkbox()
          .select(this.allDayInput)
          .onChange((checked: boolean) => {
            this.allDayInput = checked;
          })
        Text("全天")
          .fontSize(14)
          .fontColor(TEXT_PRIMARY)
          .margin({ left: 8 })
      }
      .height(44)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 6 })

      if (this.eventKindInput !== "reminder") {
        this.FieldLabel("地点")
        Row() {
          TextInput({ text: this.locationInput, placeholder: "地点或地图关键词" })
            .height(46)
            .fontSize(14)
            .fontColor(TEXT_PRIMARY)
            .backgroundColor(SOFT_SURFACE_COLOR)
            .borderRadius(CONTROL_RADIUS)
            .layoutWeight(1)
            .onChange((value: string) => {
              this.locationInput = value;
            })
          Button("地图")
            .height(46)
            .width(72)
            .backgroundColor(PRIMARY_SOFT_COLOR)
            .fontColor(PRIMARY_COLOR)
            .borderRadius(CONTROL_RADIUS)
            .margin({ left: 8 })
            .onClick(async () => await this.openLocationInMap())
        }
        .margin({ top: 8 })
      }

      this.FieldLabel("链接与协作")
      TextInput({ text: this.urlInput, placeholder: "网页链接，例如议程、文档或活动页面" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.urlInput = value;
        })
      TextInput({ text: this.attendeesInput, placeholder: "参会人邮箱，用逗号分隔" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.attendeesInput = value;
        })
      TextInput({ text: this.conferenceUrlInput, placeholder: "视频会议链接" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.conferenceUrlInput = value;
        })
      TextInput({ text: this.attachmentUrlInput, placeholder: "附件链接" })
        .height(46)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.attachmentUrlInput = value;
        })
      TextInput({ text: this.attachmentsJsonInput, placeholder: "多附件 JSON，可保留 CalDAV/Nextcloud 附件列表" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.attachmentsJsonInput = value;
        })

      this.FieldLabel("资源与会议室")
      if (this.visibleResources().length > 0) {
        Row() {
          ForEach(this.visibleResources().slice(0, 3), (resource: CalendarResource) => {
            Column() {
              Text(resource.name)
                .fontSize(11)
                .fontColor(PRIMARY_STRONG_COLOR)
                .fontWeight(FontWeight.Bold)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.resourceAvailabilityLabel(resource))
                .fontSize(9)
                .fontColor(this.resourceAvailabilityColor(resource))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 })
            }
            .height(42)
            .padding({ left: 6, right: 6 })
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(SOFT_SURFACE_COLOR)
            .borderRadius(CONTROL_RADIUS)
            .margin({ right: 6 })
            .onClick(() => this.useResourceInForm(resource))
          }, (resource: CalendarResource) => resource.id ?? resource.name)
        }
        .margin({ top: 8 })
      }
      Row() {
        TextInput({ text: this.quickRoomInput, placeholder: "会议室邮箱/ID" })
          .height(42)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.quickRoomInput = value;
          })
        Blank().width(8)
        Button("加会议室")
          .height(42)
          .width(82)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => this.addQuickRoom())
      }
      .margin({ top: 8 })
      Row() {
        TextInput({ text: this.quickResourceInput, placeholder: "资源邮箱/ID" })
          .height(42)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.quickResourceInput = value;
          })
        Blank().width(8)
        Button("加资源")
          .height(42)
          .width(82)
          .fontSize(12)
          .fontColor(PRIMARY_STRONG_COLOR)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .onClick(() => this.addQuickResource())
      }
      .margin({ top: 8 })
      TextInput({ text: this.roomIdsJsonInput, placeholder: "会议室 JSON，例如 [\"room-a\"]" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.roomIdsJsonInput = value;
        })
      TextInput({ text: this.resourceIdsJsonInput, placeholder: "资源 JSON，例如 [\"projector-1\"]" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.resourceIdsJsonInput = value;
        })
      TextInput({ text: this.resourceStatusJsonInput, placeholder: "资源状态 JSON，保留会议室/资源邀请响应" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.resourceStatusJsonInput = value;
        })
      Button("检查忙闲")
        .height(42)
        .width("100%")
        .backgroundColor(SOFT_SURFACE_COLOR)
        .fontColor(PRIMARY_STRONG_COLOR)
        .fontWeight(FontWeight.Bold)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onClick(async () => await this.checkFreeBusyForForm())
      if (this.freeBusyStatus.length > 0) {
        Text(this.freeBusyStatus)
          .fontSize(12)
          .fontColor(this.freeBusyStatus.indexOf("失败") >= 0 ? DANGER_COLOR : TEXT_SECONDARY)
          .lineHeight(18)
          .margin({ top: 6 })
      }
      if (this.resourceLocalConflictSummary().length > 0) {
        Text(this.resourceLocalConflictSummary())
          .fontSize(12)
          .fontColor(DANGER_COLOR)
          .lineHeight(18)
          .margin({ top: 4 })
      }
      if (this.freeBusyConflictSummary.length > 0) {
        Text(this.freeBusyConflictSummary)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(18)
          .margin({ top: 4 })
      }
      if (this.scheduleSuggestionStatus.length > 0) {
        Text(this.scheduleSuggestionStatus)
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .lineHeight(18)
          .margin({ top: 4 })
      }
      if (this.scheduleSuggestions.length > 0) {
        ForEach(this.scheduleSuggestions, (suggestion: ScheduleSuggestion) => {
          Row() {
            Text(suggestion.label)
              .fontSize(12)
              .fontColor(TEXT_PRIMARY)
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Button("应用")
              .height(30)
              .width(58)
              .fontSize(12)
              .fontColor(PRIMARY_STRONG_COLOR)
              .backgroundColor(PRIMARY_SOFT_COLOR)
              .borderRadius(CONTROL_RADIUS)
              .onClick(() => this.applyScheduleSuggestion(suggestion))
          }
          .height(38)
          .padding({ left: 10, right: 6 })
          .margin({ top: 6 })
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
        }, (suggestion: ScheduleSuggestion) => `${suggestion.startAt}-${suggestion.endAt}`)
      }

      this.FieldLabel("备注")
      TextInput({ text: this.notesInput, placeholder: "备注" })
        .height(72)
        .fontSize(14)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.notesInput = value;
        })

      this.FieldLabel("分类颜色")
      Row() {
        this.PaletteButton("经典", "classic")
        this.PaletteButton("柔和", "soft")
        this.PaletteButton("专注", "focus")
      }
      .height(38)
      .margin({ top: 8 })

      this.ColorPaletteGrid()

      Row() {
        Blank()
          .width(28)
          .height(28)
          .backgroundColor(this.normalizedCategoryColor(this.categoryColorInput))
          .borderRadius(6)
          .margin({ right: 10 })
      TextInput({ text: this.categoryColorInput, placeholder: "分类颜色，例如 #16A37A" })
          .height(46)
          .fontSize(13)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.categoryColorInput = value;
          })
      }
      .alignItems(VerticalAlign.Center)
      .margin({ top: 10 })

      this.FieldLabel("提醒")
      Row() {
        this.ReminderOption("不提醒", "0")
        this.ReminderOption("10 分钟", "10")
        this.ReminderOption("30 分钟", "30")
      }
      .height(38)
      .margin({ top: 8 })
      Row() {
        this.ReminderOption("1 小时", "60")
        this.ReminderOption("1 天", "1440")
        this.ReminderOption("重要", this.eventKindInput === "important" ? "1440" : "60")
      }
      .height(38)
      .margin({ top: 8 })
      TextInput({ text: this.reminderInput, placeholder: "提醒分钟，0 为不提醒" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.reminderInput = value;
          this.clearFormError();
        })
      TextInput({ text: this.secondReminderInput, placeholder: "第二提醒分钟，0 为不提醒" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.secondReminderInput = value;
          this.clearFormError();
        })
      Row() {
        TextInput({ text: this.snoozeMinutesInput, placeholder: "贪睡分钟" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.snoozeMinutesInput = value;
            this.clearFormError();
          })
        Blank().width(8)
        TextInput({ text: this.snoozeTimesInput, placeholder: "贪睡次数" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.snoozeTimesInput = value;
            this.clearFormError();
          })
      }
      .margin({ top: 8 })
      Row() {
        TextInput({ text: this.alarmActionInput, placeholder: "提醒动作 DISPLAY/EMAIL" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.alarmActionInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.allDayReminderAtInput, placeholder: "全天提醒 09:00" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.allDayReminderAtInput = value;
          })
      }
      .margin({ top: 8 })

      this.FieldLabel("时间语义")
      Row() {
        this.AvailabilityButton("显示为忙", "busy")
        this.AvailabilityButton("显示为空闲", "free")
      }
      .height(38)
      .margin({ top: 8 })
      Row() {
        this.PrivacyButton("默认", "default")
        this.PrivacyButton("公开", "public")
        this.PrivacyButton("私密", "private")
        this.PrivacyButton("机密", "confidential")
      }
      .height(38)
      .margin({ top: 8 })
      TextInput({ text: this.travelMinutesInput, placeholder: "旅行时间分钟，0 为无" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.travelMinutesInput = value;
          this.clearFormError();
        })
      TextInput({ text: this.comingDurationInput, placeholder: "返回/收尾时间分钟，0 为无" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.comingDurationInput = value;
          this.clearFormError();
        })
	      TextInput({ text: this.timeZoneInput, placeholder: "时区 TZID，例如 Asia/Shanghai" })
	        .height(46)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.timeZoneInput = value;
	        })

	      if (this.eventKindInput === "appointment") {
	        this.FieldLabel("预约设置")
	        Row() {
	          this.AppointmentStatusButton("可预约", "available")
	          this.AppointmentStatusButton("占位", "held")
	          this.AppointmentStatusButton("已预订", "booked")
	          this.AppointmentStatusButton("取消", "cancelled")
	        }
	        .height(38)
	        .margin({ top: 8 })
	        Row() {
	          TextInput({ text: this.appointmentCapacityInput, placeholder: "容量" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentCapacityInput = value;
	            })
	          Blank().width(8)
	          TextInput({ text: this.appointmentBookedCountInput, placeholder: "已订" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentBookedCountInput = value;
	            })
	        }
	        .margin({ top: 8 })
	        Row() {
	          TextInput({ text: this.appointmentMinDurationInput, placeholder: "最短分钟" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentMinDurationInput = value;
	            })
	          Blank().width(8)
	          TextInput({ text: this.appointmentMaxDurationInput, placeholder: "最长分钟" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentMaxDurationInput = value;
	            })
	        }
	        .margin({ top: 8 })
	        Row() {
	          TextInput({ text: this.appointmentBufferBeforeInput, placeholder: "前缓冲" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentBufferBeforeInput = value;
	            })
	          Blank().width(8)
	          TextInput({ text: this.appointmentBufferAfterInput, placeholder: "后缓冲" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.appointmentBufferAfterInput = value;
	            })
	        }
	        .margin({ top: 8 })
	        TextInput({ text: this.appointmentDeadlineInput, placeholder: "提前截止分钟，例如 120" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.appointmentDeadlineInput = value;
	          })
	        TextInput({ text: this.appointmentPublicUrlInput, placeholder: "预约公开链接" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.appointmentPublicUrlInput = value;
	          })
	        TextInput({ text: this.appointmentFormJsonInput, placeholder: "预约表单 JSON，例如 [{\"name\":\"company\"}]" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.appointmentFormJsonInput = value;
	          })
	        Row() {
	          TextInput({ text: this.bookingContactNameInput, placeholder: "预订人" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.bookingContactNameInput = value;
	            })
	          Blank().width(8)
	          TextInput({ text: this.bookingStatusInput, placeholder: "预订状态" })
	            .height(44)
	            .fontSize(12)
	            .fontColor(TEXT_PRIMARY)
	            .backgroundColor(SOFT_SURFACE_COLOR)
	            .borderRadius(CONTROL_RADIUS)
	            .layoutWeight(1)
	            .onChange((value: string) => {
	              this.bookingStatusInput = value;
	            })
	        }
	        .margin({ top: 8 })
	        TextInput({ text: this.bookingContactEmailInput, placeholder: "预订人邮箱" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.bookingContactEmailInput = value;
	          })
	        TextInput({ text: this.bookingContactPhoneInput, placeholder: "预订人电话" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.bookingContactPhoneInput = value;
	          })
	        TextInput({ text: this.bookingJsonInput, placeholder: "预订详情 JSON，保留外部 booking 数据" })
	          .height(44)
	          .fontSize(12)
	          .fontColor(TEXT_PRIMARY)
	          .backgroundColor(SOFT_SURFACE_COLOR)
	          .borderRadius(CONTROL_RADIUS)
	          .margin({ top: 8 })
	          .onChange((value: string) => {
	            this.bookingJsonInput = value;
	          })
	      }

	      this.FieldLabel("高级兼容")
      Row() {
        TextInput({ text: this.eventBackgroundColorInput, placeholder: "事件背景色" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.eventBackgroundColorInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.eventTextColorInput, placeholder: "文字色" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.eventTextColorInput = value;
          })
      }
      .margin({ top: 8 })
      Row() {
        TextInput({ text: this.eventBorderColorInput, placeholder: "边框色" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.eventBorderColorInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.eventDragBackgroundColorInput, placeholder: "拖拽背景色" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.eventDragBackgroundColorInput = value;
          })
      }
      .margin({ top: 8 })
      Row() {
        TextInput({ text: this.milestoneStatusInput, placeholder: "里程碑状态" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.milestoneStatusInput = value;
          })
        Blank().width(8)
        TextInput({ text: this.dueDateClassInput, placeholder: "到期样式类" })
          .height(44)
          .fontSize(12)
          .fontColor(TEXT_PRIMARY)
          .backgroundColor(SOFT_SURFACE_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.dueDateClassInput = value;
          })
      }
      .margin({ top: 8 })
      TextInput({ text: this.groupIdInput, placeholder: "分组 ID / FullCalendar groupId" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.groupIdInput = value;
        })
      TextInput({ text: this.displayModeInput, placeholder: "显示模式 display，例如 auto/background/inverse-background" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.displayModeInput = value;
        })
	      Row() {
	        this.SwitchMark(this.overlapInput)
	        Text(this.overlapInput ? "允许重叠" : "不允许重叠")
          .fontSize(12)
          .fontColor(TEXT_SECONDARY)
          .margin({ left: 8 })
      }
      .height(42)
      .margin({ top: 8 })
      .onClick(() => {
	        this.overlapInput = !this.overlapInput;
	      })
	      Row() {
	        this.SwitchMark(this.editableInput)
	        Text(this.editableInput ? "允许编辑" : "禁止编辑")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.editableInput = !this.editableInput;
	      })
	      Row() {
	        this.SwitchMark(this.interactiveInput)
	        Text(this.interactiveInput ? "可交互" : "不响应点击")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.interactiveInput = !this.interactiveInput;
	      })
	      Row() {
	        this.SwitchMark(this.startEditableInput)
	        Text(this.startEditableInput ? "可改开始" : "锁定开始")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.startEditableInput = !this.startEditableInput;
	      })
	      Row() {
	        this.SwitchMark(this.durationEditableInput)
	        Text(this.durationEditableInput ? "可改时长" : "锁定时长")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.durationEditableInput = !this.durationEditableInput;
	      })
	      Row() {
	        this.SwitchMark(this.resourceEditableInput)
	        Text(this.resourceEditableInput ? "可改资源" : "锁定资源")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.resourceEditableInput = !this.resourceEditableInput;
	      })
	      Row() {
	        this.SwitchMark(!this.eventReadOnlyInput)
	        Text(this.eventReadOnlyInput ? "事件只读" : "事件可写")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.eventReadOnlyInput = !this.eventReadOnlyInput;
	      })
	      Row() {
	        this.SwitchMark(this.isPendingInput)
	        Text(this.isPendingInput ? "保存中/待确认" : "非待确认")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.isPendingInput = !this.isPendingInput;
	      })
	      Row() {
	        this.SwitchMark(this.isFocusedInput)
	        Text(this.isFocusedInput ? "高亮关注" : "普通显示")
	          .fontSize(12)
	          .fontColor(TEXT_SECONDARY)
	          .margin({ left: 8 })
	      }
	      .height(42)
	      .margin({ top: 8 })
	      .onClick(() => {
	        this.isFocusedInput = !this.isFocusedInput;
	      })
	      TextInput({ text: this.classNamesInput, placeholder: "样式类名 classNames，逗号或空格分隔" })
	        .height(46)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.classNamesInput = value;
	        })
	      TextInput({ text: this.customStyleJsonInput, placeholder: "自定义样式 JSON / customStyle" })
	        .height(46)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.customStyleJsonInput = value;
	        })
	      TextInput({ text: this.constraintJsonInput, placeholder: "约束 JSON / constraintJson" })
	        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.constraintJsonInput = value;
        })
      TextInput({ text: this.extendedPropsJsonInput, placeholder: "扩展属性 JSON，保留服务商私有字段" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.extendedPropsJsonInput = value;
	        })
	      TextInput({ text: this.rawPropsJsonInput, placeholder: "原始私有字段 JSON，保留 TUI/服务商 raw" })
	        .height(46)
	        .fontSize(13)
	        .fontColor(TEXT_PRIMARY)
	        .backgroundColor(SOFT_SURFACE_COLOR)
	        .borderRadius(CONTROL_RADIUS)
	        .margin({ top: 8 })
	        .onChange((value: string) => {
	          this.rawPropsJsonInput = value;
	        })
	      TextInput({ text: this.alarmActionsJsonInput, placeholder: "提醒动作 JSON，例如 [{\"action\":\"DISPLAY\",\"minutes\":10}]" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.alarmActionsJsonInput = value;
        })

      this.FieldLabel("重复规则")
      TextInput({ text: this.rruleInput, placeholder: "RRULE，例如 FREQ=WEEKLY" })
        .height(46)
        .fontSize(13)
        .fontColor(TEXT_PRIMARY)
        .backgroundColor(SOFT_SURFACE_COLOR)
        .borderRadius(CONTROL_RADIUS)
        .margin({ top: 8 })
        .onChange((value: string) => {
          this.rruleInput = value;
        })

      if (this.formConflictSummary().length > 0) {
        Text(this.formConflictSummary())
          .fontSize(12)
          .fontColor(DANGER_COLOR)
          .backgroundColor(DANGER_SOFT_COLOR)
          .borderRadius(CONTROL_RADIUS)
          .padding(10)
	          .margin({ top: 10 })
	      }

	      if (this.editingEventHasConflict()) {
	        this.NewEditingConflictActions()
	      }

	      Button(this.editingEventId.length > 0 ? "保存修改并加入待同步" : "创建并加入待同步")
        .height(54)
        .width("100%")
        .backgroundColor(PRIMARY_COLOR)
        .fontColor("#FFFFFF")
        .fontWeight(FontWeight.Bold)
        .borderRadius(18)
        .margin({ top: 14 })
        .onClick(async () => await this.saveEventForm())
    }
    .padding(16)
    .backgroundColor(SURFACE_COLOR)
    .borderRadius(CARD_RADIUS)
    .border({ width: 0.5, color: BORDER_COLOR })
  }

  @Builder
  EditorPage() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            this.BackButton()
            Column() {
              Text(this.editingEventId.length > 0 ? "编辑" : "新建")
                .fontSize(13)
                .fontColor(TEXT_SECONDARY)
                .fontWeight(FontWeight.Medium)
              Text(this.editingEventId.length > 0 ? "编辑日程" : "添加日程")
                .fontSize(34)
                .fontColor(TEXT_PRIMARY)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 5 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 12 })
            Button("完成")
              .height(44)
              .width(70)
              .backgroundColor("#00000000")
              .fontColor(PRIMARY_STRONG_COLOR)
              .fontWeight(FontWeight.Bold)
              .borderRadius(CONTROL_RADIUS)
              .onClick(async () => await this.saveEventForm())
          }
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 12 })
          this.EventFormCard()
        }
        .padding({ left: 18, right: 18, top: 18, bottom: 28 })
      }
      .layoutWeight(1)
    }
    .height("100%")
  }

  private async loadAccounts(): Promise<void> {
    const service: CalendarSyncService = this.requireService();
    this.accounts = await service.listAccounts();
    const account: CalendarAccount | null = await service.loadAccount();
    if (account === null) {
      return;
    }

    this.accountIdInput = account.id ?? "";
    this.accountNameInput = account.displayName ?? "";
    this.serverUrl = account.serverUrl;
    this.username = account.username;
    this.password = account.password;
  }

  private async loadSources(): Promise<void> {
    this.sources = await this.requireService().listSources();
    if (this.selectedSourceIdInput.length === 0) {
      this.selectedSourceIdInput = this.defaultWritableSourceId();
    }
    if (this.resourceSourceIdInput.length === 0) {
      this.resourceSourceIdInput = this.defaultWritableSourceId();
    }
  }

  private async loadResources(): Promise<void> {
    this.resources = await this.requireService().listResources();
  }

  private async saveResource(): Promise<void> {
    const name: string = this.resourceNameInput.trim();
    if (name.length === 0) {
      this.syncStatus = "请填写资源名称";
      return;
    }

    const capacity: number = this.parseOptionalMinutes(this.resourceCapacityInput);
    if (capacity < 0) {
      this.syncStatus = "资源容量必须是 0 或正整数";
      return;
    }

    await this.requireService().upsertResource({
      sourceId: this.resourceSourceIdInput,
      resourceType: this.resourceTypeInput,
      name,
      email: this.resourceEmailInput.trim(),
      externalId: this.resourceEmailInput.trim(),
      capacity,
      location: this.resourceLocationInput.trim(),
      color: this.resourceTypeInput === "room" ? BLUE_COLOR : PRIMARY_COLOR,
      isBookable: true,
      isVisible: true,
      availabilityJson: "",
      permissionsJson: "",
      rawPropsJson: "",
      lastSyncAt: 0
    });
    this.resourceNameInput = "";
    this.resourceEmailInput = "";
    this.resourceCapacityInput = "0";
    this.resourceLocationInput = "";
    await this.loadResources();
    this.syncStatus = "资源已保存";
  }

  private async removeResource(resource: CalendarResource): Promise<void> {
    const id: string = resource.id ?? "";
    if (id.length === 0) {
      return;
    }
    await this.requireService().removeResource(id);
    await this.loadResources();
    this.syncStatus = `资源已删除：${resource.name}`;
  }

  private cycleResourceType(): void {
    if (this.resourceTypeInput === "room") {
      this.resourceTypeInput = "equipment";
    } else if (this.resourceTypeInput === "equipment") {
      this.resourceTypeInput = "person";
    } else if (this.resourceTypeInput === "person") {
      this.resourceTypeInput = "resource";
    } else {
      this.resourceTypeInput = "room";
    }
  }

  private cycleResourceSource(): void {
    if (this.sources.length === 0) {
      this.resourceSourceIdInput = "";
      return;
    }

    const ids: string[] = this.sources.map((source: CalendarSource) => source.id ?? "").filter((id: string) => id.length > 0);
    if (ids.length === 0) {
      this.resourceSourceIdInput = "";
      return;
    }

    const currentIndex: number = ids.indexOf(this.resourceSourceIdInput);
    this.resourceSourceIdInput = ids[(currentIndex + 1) % ids.length];
  }

  private visibleResources(): CalendarResource[] {
    return this.resources.filter((resource: CalendarResource) => resource.isVisible !== false);
  }

  private resourcesForSource(sourceId: string): CalendarResource[] {
    return this.resources.filter((resource: CalendarResource) => (resource.sourceId ?? "") === sourceId);
  }

  private resourceSourceName(): string {
    if (this.resourceSourceIdInput.length === 0) {
      return "不绑定源";
    }

    const found: CalendarSource | undefined = this.sources.find((source: CalendarSource) => (source.id ?? "") === this.resourceSourceIdInput);
    return found !== undefined ? found.name : "不绑定源";
  }

  private sourceResourceMeta(source: CalendarSource): string {
    const count: number = this.resourcesForSource(source!.id ?? "").length;
    return count > 0 ? `资源：${count} 个会议室/设备` : "资源：未配置";
  }

  private resourceMeta(resource: CalendarResource): string {
    const parts: string[] = [this.resourceTypeLabel(resource.resourceType)];
    if ((resource.email ?? "").length > 0) {
      parts.push(resource.email ?? "");
    }
    if ((resource.location ?? "").length > 0) {
      parts.push(resource.location ?? "");
    }
    if ((resource.capacity ?? 0) > 0) {
      parts.push(`${resource.capacity ?? 0} 人`);
    }
    return parts.join(" · ");
  }

  private resourceTypeLabel(value: CalendarResourceType): string {
    if (value === "room") {
      return "会议室";
    }
    if (value === "equipment") {
      return "设备";
    }
    if (value === "person") {
      return "人员";
    }
    return "资源";
  }

  private resourceAvailabilityLabel(resource: CalendarResource): string {
    const startAt: number = this.parseInputDate(this.startInput);
    const endAt: number = this.parseInputDate(this.endInput);
    if (startAt <= 0 || endAt <= startAt) {
      return resource.isBookable === false ? "不可预订" : "可选";
    }

    if (resource.isBookable === false) {
      return "不可预订";
    }

    if (!this.resourceMatchesAvailabilityWindow(resource, startAt, endAt)) {
      return "不在开放时间";
    }

    const conflicts: CalendarEvent[] = this.localResourceConflicts(resource, startAt, endAt);
    if (conflicts.length > 0) {
      return `本地冲突 ${conflicts.length}`;
    }

    return "本地可用";
  }

  private resourceAvailabilityColor(resource: CalendarResource): string {
    const label: string = this.resourceAvailabilityLabel(resource);
    if (label.indexOf("冲突") >= 0 || label.indexOf("不可") >= 0 || label.indexOf("不在") >= 0) {
      return DANGER_COLOR;
    }
    if (label.indexOf("可用") >= 0) {
      return SUCCESS_COLOR;
    }
    return TEXT_SECONDARY;
  }

  private useResourceInForm(resource: CalendarResource): void {
    const value: string = (resource.email ?? "").length > 0 ? resource.email ?? "" : resource.name;
    if (resource.resourceType === "room") {
      this.roomIdsJsonInput = this.appendStringJson(this.roomIdsJsonInput, value);
      this.resourceStatusJsonInput = this.appendResourceStatusJson(this.resourceStatusJsonInput, value, "room");
    } else {
      this.resourceIdsJsonInput = this.appendStringJson(this.resourceIdsJsonInput, value);
      this.resourceStatusJsonInput = this.appendResourceStatusJson(this.resourceStatusJsonInput, value, "resource");
    }
    this.syncStatus = `已加入事件资源：${resource.name}`;
  }

  private resourceLocalConflictSummary(): string {
    const startAt: number = this.parseInputDate(this.startInput);
    const endAt: number = this.parseInputDate(this.endInput);
    if (startAt <= 0 || endAt <= startAt) {
      return "";
    }

    const selected: CalendarResource[] = this.selectedFormResources();
    const parts: string[] = [];
    selected.forEach((resource: CalendarResource) => {
      if (resource.isBookable === false) {
        parts.push(`${resource.name} 不可预订`);
        return;
      }
      if (!this.resourceMatchesAvailabilityWindow(resource, startAt, endAt)) {
        parts.push(`${resource.name} 不在开放时间`);
        return;
      }
      const conflicts: CalendarEvent[] = this.localResourceConflicts(resource, startAt, endAt);
      if (conflicts.length > 0) {
        parts.push(`${resource.name} 与「${conflicts[0].title}」重叠`);
      }
    });

    return parts.length > 0 ? parts.slice(0, 3).join("；") : "";
  }

  private selectedFormResources(): CalendarResource[] {
    const ids: string[] = [];
    this.parseStringArrayJson(this.roomIdsJsonInput).forEach((item: string) => ids.push(item.toLowerCase()));
    this.parseStringArrayJson(this.resourceIdsJsonInput).forEach((item: string) => ids.push(item.toLowerCase()));
    return this.resources.filter((resource: CalendarResource) => {
      const email: string = (resource.email ?? "").toLowerCase();
      const name: string = resource.name.toLowerCase();
      const externalId: string = (resource.externalId ?? "").toLowerCase();
      return ids.indexOf(email) >= 0 || ids.indexOf(name) >= 0 || ids.indexOf(externalId) >= 0;
    });
  }

  private localResourceConflicts(resource: CalendarResource, startAt: number, endAt: number): CalendarEvent[] {
    const tokens: string[] = this.resourceMatchTokens(resource);
    if (tokens.length === 0) {
      return [];
    }

    return this.events.filter((event: CalendarEvent) => {
      if (event.id === this.editingEventId || !this.eventsOverlap(startAt, endAt, event.startAt, event.endAt)) {
        return false;
      }
      const eventTokens: string[] = [];
      this.parseStringArrayJson(event.roomIdsJson ?? "").forEach((item: string) => eventTokens.push(item.toLowerCase()));
      this.parseStringArrayJson(event.resourceIdsJson ?? "").forEach((item: string) => eventTokens.push(item.toLowerCase()));
      return eventTokens.find((item: string) => tokens.indexOf(item) >= 0) !== undefined;
    });
  }

  private resourceMatchTokens(resource: CalendarResource): string[] {
    const tokens: string[] = [];
    const append = (value: string): void => {
      const normalized: string = value.trim().toLowerCase();
      if (normalized.length > 0 && tokens.indexOf(normalized) < 0) {
        tokens.push(normalized);
      }
    };
    append(resource.name);
    append(resource.email ?? "");
    append(resource.externalId ?? "");
    return tokens;
  }

  private resourceMatchesAvailabilityWindow(resource: CalendarResource, startAt: number, endAt: number): boolean {
    const windows: ResourceAvailabilityWindow[] = this.parseResourceAvailability(resource.availabilityJson ?? "");
    if (windows.length === 0) {
      return true;
    }

    const date = new Date(startAt);
    const day: number = date.getDay();
    const minutesStart: number = date.getHours() * 60 + date.getMinutes();
    const endDate = new Date(endAt);
    if (!sameDay(startAt, endAt)) {
      return false;
    }
    const minutesEnd: number = endDate.getHours() * 60 + endDate.getMinutes();
    return windows.find((window: ResourceAvailabilityWindow) => {
      const days: number[] = window.days ?? [];
      if (days.length > 0 && days.indexOf(day) < 0) {
        return false;
      }
      const windowStart: number = this.parseClockMinutes(window.start);
      const windowEnd: number = this.parseClockMinutes(window.end);
      return windowStart >= 0 && windowEnd > windowStart && minutesStart >= windowStart && minutesEnd <= windowEnd;
    }) !== undefined;
  }

  private parseResourceAvailability(value: string): ResourceAvailabilityWindow[] {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return [];
    }

    try {
      const parsed = JSON.parse(trimmed) as Object;
      const items: Object[] = Array.isArray(parsed) ? parsed : [parsed];
      return items.map((item: Object) => {
        const holder = item as Record<string, Object>;
        const daysRaw = holder["days"] as number[] | undefined;
        return {
          days: Array.isArray(daysRaw) ? daysRaw.map((day: number) => Number(day)) : undefined,
          start: `${holder["start"] ?? holder["startTime"] ?? ""}`,
          end: `${holder["end"] ?? holder["endTime"] ?? ""}`
        } as ResourceAvailabilityWindow;
      }).filter((item: ResourceAvailabilityWindow) => item.start.length > 0 && item.end.length > 0);
    } catch {
      return [];
    }
  }

  private parseClockMinutes(value: string): number {
    const match: RegExpMatchArray | null = value.trim().match(/^(\d{1,2}):(\d{2})$/);
    if (match === null) {
      return -1;
    }
    const hour: number = Number(match![1]);
    const minute: number = Number(match![2]);
    if (Number.isNaN(hour) || Number.isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return -1;
    }
    return hour * 60 + minute;
  }

  private async loadViewConfig(): Promise<void> {
    this.viewConfig = await this.requireService().loadViewConfig();
    if (this.viewConfig.defaultView === "day") {
      this.viewConfig = withViewConfig(this.viewConfig, "defaultView", "month");
      await this.requireService().saveViewConfig(this.viewConfig);
    }
    if (this.viewConfig.minHour === 8 && this.viewConfig.maxHour === 21) {
      this.viewConfig = withMinMaxHour(this.viewConfig, TIME_GRID_START_HOUR, TIME_GRID_END_HOUR);
      await this.requireService().saveViewConfig(this.viewConfig);
    }
    if (this.scheduleView === "month" && this.viewConfig.defaultView.length > 0) {
      this.scheduleView = this.viewConfig.defaultView;
    }
  }

  private async loadDateMarkers(): Promise<void> {
    const baseStart: number = this.monthStart(this.visibleMonth);
    this.dateMarkers = await this.requireService().listDateMarkers(baseStart - 31 * DAY_MS, addMonths(baseStart, 13));
  }

	private async updateViewConfig(value: string): Promise<void> {
    if (value.startsWith("auth:")) {
      this.authTypeInput = this.authTypeValue(value.split(":")[1]);
      return;
    }

    try {
	    let next: CalendarViewConfig = this.viewConfig;
    if (value === "setting:defaultView") {
      next = withViewConfig(this.viewConfig, "defaultView", this.nextDefaultView(this.viewConfig.defaultView));
    } else if (value === "setting:weekStart") {
      const nextStart: number = this.viewConfig.weekStartsOn === 0 ? 1 : 0;
      next = withViewConfig(this.viewConfig, "weekStartsOn", nextStart);
      next = withViewConfig(next, "weekEndsOn", this.defaultWeekEndsOn(nextStart));
    } else if (value === "setting:defaultReminder") {
      next = withViewConfig(this.viewConfig, "defaultReminderMinutes",
        this.nextDefaultReminder(this.viewConfig.defaultReminderMinutes ?? 15));
    } else if (value === "setting:timeZone") {
      const nextZone: string = this.nextTimeZone(this.currentTimeZoneValue());
      next = withViewConfig(this.viewConfig, "timeZone", nextZone);
      if (this.editingEventId.length === 0) {
        this.timeZoneInput = nextZone;
      }
    } else if (value === "day" || value === "week" || value === "month") {
      next = withViewConfig(this.viewConfig, "defaultView", value);
    } else if (value.startsWith("hours:")) {
      const parts: string[] = value.split(":");
      next = withMinMaxHour(this.viewConfig, Number(parts[1]),
        Number(parts[2])
        );
    } else if (value.startsWith("dots:")) {
      next = withViewConfig(this.viewConfig, "maxVisibleEventsPerDay", Number(value.split(":")[1]));
	    } else if (value === "swipe") {
	      next = withViewConfig(this.viewConfig, "swipeEnabled", !this.viewConfig.swipeEnabled);
	    } else if (value === "weekEnd") {
	      next = withViewConfig(this.viewConfig, "weekEndsOn", (this.viewConfig.weekEndsOn ?? 0) === 0 ? 6 : 0);
	    } else if (value === "sixWeeks") {
	      next = withViewConfig(this.viewConfig, "showSixWeeks", this.viewConfig.showSixWeeks === false);
	    } else if (value === "hourFormat") {
	      next = withViewConfig(this.viewConfig, "hourFormat", (this.viewConfig.hourFormat ?? "24h") === "24h" ? "12h" : "24h");
	    } else if (value.startsWith("locale:")) {
	      next = withViewConfig(this.viewConfig, "locale", value.split(":")[1]);
	    } else if (value === "views:all") {
	      next = withViewConfig(this.viewConfig, "enabledViewsJson", "");
	    } else if (value.startsWith("kind:")) {
	      next = withViewConfig(this.viewConfig, "eventKindFilter", value.split(":")[1]);
	    } else if (value.startsWith("defaultReminder:")) {
	      next = withViewConfig(this.viewConfig, "defaultReminderMinutes", Number(value.split(":")[1]));
	    } else if (value.startsWith("theme:")) {
	      next = withViewConfig(this.viewConfig, "themeMode", value.split(":")[1]);
	    } else if (value.startsWith("sound:")) {
	      next = withViewConfig(this.viewConfig, "reminderSound", value.split(":")[1]);
	    } else if (value === "vibrate") {
	      next = withViewConfig(this.viewConfig, "reminderVibrate", this.viewConfig.reminderVibrate === false);
	    } else if (value === "hideCancelled") {
	      next = withViewConfig(this.viewConfig, "hideCancelledEvents", this.viewConfig.hideCancelledEvents !== true);
	    } else if (value === "incompleteTasks") {
	      next = withViewConfig(this.viewConfig, "showIncompleteTasksOnly", this.viewConfig.showIncompleteTasksOnly !== true);
	    } else if (value === "clearSourceFilter") {
	      next = withViewConfig(this.viewConfig, "sourceFilterJson", "");
	    } else if (value === "adjacentMonths") {
	      next = withViewConfig(this.viewConfig, "showAdjacentMonths", this.viewConfig.showAdjacentMonths === false);
	    } else if (value === "nowIndicator") {
	      next = withViewConfig(this.viewConfig, "nowIndicatorVisible", this.viewConfig.nowIndicatorVisible === false);
	    } else if (value === "scrollOffset") {
	      next = withViewConfig(this.viewConfig, "scrollOffsetMinutes", (this.viewConfig.scrollOffsetMinutes ?? 480) === 480 ? 360 : 480);
	    } else if (value === "monthMoreLabel") {
	      next = withViewConfig(this.viewConfig, "monthMoreLabel", (this.viewConfig.monthMoreLabel ?? "更多") === "更多" ? "+N" : "更多");
	    } else if (value === "eventOrder") {
	      next = withViewConfig(this.viewConfig, "eventOrder", (this.viewConfig.eventOrder ?? "start,title") === "start,title" ? "title,start" : "start,title");
	    } else if (value === "agendaPast") {
	      next = withViewConfig(this.viewConfig, "agendaShowPastDays", this.viewConfig.agendaShowPastDays !== true);
	    } else if (value === "agendaGroup") {
	      next = withViewConfig(this.viewConfig, "agendaGroupMode", (this.viewConfig.agendaGroupMode ?? "day") === "day" ? "source" : "day");
	    } else if (value === "agendaEmpty") {
	      next = withViewConfig(this.viewConfig, "agendaEmptyText", (this.viewConfig.agendaEmptyText ?? "当天没有日程") === "当天没有日程" ? "没有符合条件的日程" : "当天没有日程");
	    }

    this.commitViewConfig(next);
    } catch (e) {
      console.error("updateViewConfig error: " + JSON.stringify(e));
      this.syncStatus = "保存失败: " + (typeof e === 'object' ? JSON.stringify(e) : String(e));
    }
  }

  private updateSettingSelect(action: string, index: number): void {
    try {
      let next: CalendarViewConfig = this.viewConfig;
      if (action === "defaultView") {
        const views: string[] = ["month", "week"];
        next = withViewConfig(this.viewConfig, "defaultView", views[Math.max(0, Math.min(1, index))]);
      } else if (action === "weekStart") {
        const weekStartsOn: number = index === 1 ? 0 : 1;
        next = withViewConfig(this.viewConfig, "weekStartsOn", weekStartsOn);
        next = withViewConfig(next, "weekEndsOn", this.defaultWeekEndsOn(weekStartsOn));
      } else if (action === "defaultReminder") {
        const reminders: number[] = [15, 30, 0];
        next = withViewConfig(this.viewConfig, "defaultReminderMinutes", reminders[Math.max(0, Math.min(2, index))]);
      } else if (action === "timeZone") {
        const zones: string[] = this.timeZoneValues();
        const nextZone: string = zones[Math.max(0, Math.min(zones.length - 1, index))];
        next = withViewConfig(this.viewConfig, "timeZone", nextZone);
        if (this.editingEventId.length === 0) {
          this.timeZoneInput = nextZone;
        }
      }

      this.commitViewConfig(next);
    } catch (e) {
      console.error("updateSettingSelect error: " + JSON.stringify(e));
      this.syncStatus = "保存失败: " + (typeof e === 'object' ? JSON.stringify(e) : String(e));
    }
  }

  private commitViewConfig(next: CalendarViewConfig): void {
    this.viewConfig = next;
    this.appPage = "settings";
    this.settingsRenderKey++;
    this.syncStatus = "视图配置已保存";
    this.requireService().saveViewConfig(next).then((saved: CalendarViewConfig) => {
      this.viewConfig = saved;
      this.appPage = "settings";
      this.settingsRenderKey++;
    }).catch((e: Error) => {
      console.error("saveViewConfig error: " + JSON.stringify(e));
      this.syncStatus = "保存失败: " + JSON.stringify(e);
      this.appPage = "settings";
      this.settingsRenderKey++;
    });
  }

  private defaultViewLabel(): string {
    if (this.viewConfig.defaultView === "week") {
      return "周";
    }

    return "月";
  }

  private defaultViewSelectOptions(): SelectOption[] {
    return [
      { value: "月" },
      { value: "周" }
    ];
  }

  private defaultViewSelectIndex(): number {
    if (this.viewConfig.defaultView === "week") {
      return 1;
    }

    return 0;
  }

  private weekStartLabel(): string {
    return this.viewConfig.weekStartsOn === 0 ? "周日" : "周一";
  }

  private weekStartSelectOptions(): SelectOption[] {
    return [
      { value: "周一" },
      { value: "周日" }
    ];
  }

  private weekStartSelectIndex(): number {
    return this.viewConfig.weekStartsOn === 0 ? 1 : 0;
  }

  private defaultReminderLabel(): string {
    const minutes: number = this.viewConfig.defaultReminderMinutes ?? 15;
    return minutes <= 0 ? "不提醒" : `提前 ${minutes} 分钟`;
  }

  private defaultReminderSelectOptions(): SelectOption[] {
    return [
      { value: "提前 15 分钟" },
      { value: "提前 30 分钟" },
      { value: "不提醒" }
    ];
  }

  private defaultReminderSelectIndex(): number {
    const minutes: number = this.viewConfig.defaultReminderMinutes ?? 15;
    if (minutes === 30) {
      return 1;
    }
    if (minutes <= 0) {
      return 2;
    }

    return 0;
  }

  private currentTimeZoneValue(): string {
    const timeZone: string = (this.viewConfig.timeZone ?? "Asia/Shanghai").trim();
    return timeZone.length > 0 ? timeZone : "Asia/Shanghai";
  }

  private currentTimeZoneLabel(): string {
    return this.currentTimeZoneValue();
  }

  private timeZoneSelectOptions(): SelectOption[] {
    return this.timeZoneValues().map((value: string): SelectOption => {
      return { value };
    });
  }

  private timeZoneSelectIndex(): number {
    const index: number = this.timeZoneValues().indexOf(this.currentTimeZoneValue());
    return index >= 0 ? index : 0;
  }

  private nextDefaultView(value: string): string {
    return value === "month" ? "week" : "month";
  }

  private nextDefaultReminder(value: number): number {
    if (value <= 0) {
      return 15;
    }
    if (value === 15) {
      return 30;
    }

    return 0;
  }

  private nextTimeZone(value: string): string {
    const zones: string[] = this.timeZoneValues();
    const index: number = zones.indexOf(value);
    return zones[(index + 1) % zones.length];
  }

  private timeZoneValues(): string[] {
    return ["Asia/Shanghai", "UTC", "America/Los_Angeles", "Europe/London", "Asia/Tokyo"];
  }

  private defaultWeekEndsOn(weekStartsOn: number): number {
    return weekStartsOn === 0 ? 6 : 0;
  }

  private async addDateMarkerFromForm(): Promise<void> {
    const markerDate: number = this.parseInputDate(`${this.markerDateInput.trim()} 00:00`);
    const markerEnd: number = this.markerEndDateInput.trim().length > 0 ?
      this.parseInputDate(`${this.markerEndDateInput.trim()} 00:00`) : markerDate;
    if (markerDate <= 0) {
      this.syncStatus = "日期标记需要有效开始日期";
      return;
    }

    await this.requireService().upsertDateMarker({
      markerDate,
      markingType: this.dateMarkerTypeValue(),
      title: this.markerTitleInput.trim(),
      color: this.normalizedCategoryColor(this.markerColorInput),
      selected: false,
      disabled: false,
      disableTouchEvent: false,
      dotColorsJson: this.markerTypeInput === "multi-dot" ? JSON.stringify([this.markerColorInput, BLUE_COLOR]) : "",
      multiPeriodJson: this.markerTypeInput === "multi-period" ?
        JSON.stringify([{ start: markerDate, end: Math.max(markerDate, markerEnd), color: this.markerColorInput }]) : "",
      periodStart: this.markerTypeInput === "period" ? markerDate : 0,
      periodEnd: this.markerTypeInput === "period" ? Math.max(markerDate, markerEnd) : 0,
      periodColor: this.markerTypeInput === "period" ? this.markerColorInput : "",
      selectedColor: this.markerColorInput,
      selectedDotColor: this.markerColorInput,
      accessibilityLabel: this.markerTitleInput.trim(),
      customMarkJson: this.markerTypeInput === "custom" ? JSON.stringify({ color: this.markerColorInput }) : ""
    });
    this.markerTitleInput = "";
    await this.loadDateMarkers();
    this.syncStatus = "日期标记已添加";
  }

  private async removeDateMarker(marker: CalendarDateMarker): Promise<void> {
    const markerId: string = marker.id ?? "";
    if (markerId.length === 0) {
      return;
    }

    await this.requireService().removeDateMarker(markerId);
    await this.loadDateMarkers();
    this.syncStatus = "日期标记已删除";
  }

  private async saveAccount(): Promise<void> {
    if (this.isSavingAccount) {
      return;
    }

    this.isSavingAccount = true;
    this.accountFormStatus = "正在保存 CalDAV 账号";
    this.syncStatus = "正在保存 CalDAV 账号";

	    try {
        const providerType: string = this.providerTypeFromServerUrl(this.serverUrl);
        const normalizedServerUrl: string = normalizeProviderServerUrl(providerType, this.serverUrl, this.username);
	      const saved: CalendarAccount = await this.requireService().saveCalDavAccount({
	        id: this.accountIdInput,
	        displayName: this.accountNameInput,
	        providerType,
	        providerPresetJson: buildProviderPresetJson(providerType, normalizedServerUrl),
	        serverUrl: normalizedServerUrl,
	        username: this.username,
	        password: this.password,
	        authType: this.authTypeInput,
	        bearerToken: this.bearerTokenInput,
	        customHeadersJson: this.customHeadersJsonInput,
	        isActive: true
	      });
      this.upsertSavedAccount(saved);
      this.accountIdInput = saved.id ?? "";
      this.accountNameInput = saved.displayName ?? "";
      this.serverUrl = saved.serverUrl;
	      this.username = saved.username;
	      this.password = saved.password;
	      this.authTypeInput = this.authTypeValue(saved.authType);
	      this.bearerTokenInput = saved.bearerToken ?? "";
	      this.customHeadersJsonInput = saved.customHeadersJson ?? "";
      this.accountFormStatus = "CalDAV 账号已保存";
      this.syncStatus = "CalDAV 已保存";
      this.showAccountForm = false;
      await this.loadSources();
    } catch (error) {
      this.accountFormStatus = this.describeError(error);
      this.syncStatus = this.accountFormStatus;
    } finally {
      this.isSavingAccount = false;
    }
  }

  private upsertSavedAccount(saved: CalendarAccount): void {
    const savedId: string = saved.id ?? "";
    const normalized: CalendarAccount[] = [];
    let replaced: boolean = false;

    this.accounts.forEach((account: CalendarAccount) => {
      if ((account.id ?? "") === savedId && savedId.length > 0) {
        normalized.push(saved);
        replaced = true;
        return;
      }

      normalized.push({
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
	        isActive: saved.isActive === true ? false : account.isActive
	      });
    });

    if (!replaced) {
      normalized.unshift(saved);
    }

    this.accounts = normalized.sort((left: CalendarAccount, right: CalendarAccount) => {
      if (left.isActive === right.isActive) {
        return 0;
      }

      return left.isActive === true ? -1 : 1;
    });
  }

  private async activateAccount(account: CalendarAccount): Promise<void> {
    if ((account.id ?? "").length === 0) {
      return;
    }

    await this.requireService().activateAccount(account.id ?? "");
    await this.loadAccounts();
    await this.loadSources();
    this.syncStatus = "CalDAV 已切换";
  }

  private async removeAccount(account: CalendarAccount): Promise<void> {
    if ((account.id ?? "").length === 0) {
      return;
    }

    await this.requireService().removeAccount(account.id ?? "");
    await this.loadAccounts();
    await this.loadSources();
    if (this.accountIdInput === (account.id ?? "")) {
      this.newAccountForm();
    }
    this.syncStatus = "CalDAV 账号已删除";
  }

  private async toggleSourceVisibility(source: CalendarSource): Promise<void> {
    const sourceId: string = source.id ?? "";
    if (sourceId.length === 0) {
      return;
    }

    await this.requireService().updateSourceVisibility(sourceId, !source.isVisible);
    await this.loadSources();
    await this.loadEvents();
    this.syncStatus = source.isVisible ? "日历源已隐藏" : "日历源已显示";
  }

  private async cycleSourceColor(source: CalendarSource): Promise<void> {
    const sourceId: string = source.id ?? "";
    if (sourceId.length === 0) {
      return;
    }

    const colors: string[] = this.sourceColorPalette();
    const current: string = this.sourceColor(source);
    const currentIndex: number = colors.indexOf(current);
    const nextColor: string = colors[(currentIndex + 1) % colors.length];
    try {
      await this.requireService().updateSourceMetadata(sourceId, source.name, nextColor);
      await this.loadSources();
      this.syncStatus = `${source.name} 已切换为 ${nextColor}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    }
  }

	  private async setDefaultSource(source: CalendarSource): Promise<void> {
    const sourceId: string = source.id ?? "";
    if (sourceId.length === 0 || source.isReadOnly) {
      return;
    }

    await this.requireService().setDefaultSource(sourceId);
    await this.loadSources();
	    this.syncStatus = "默认日历源已更新";
	  }

	  private async refreshSource(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }

	    try {
	      const result: CalendarSyncResult = await this.requireService().refreshSource(sourceId);
	      await this.loadSources();
	      await this.loadEvents();
	      this.syncStatus = `${source.name} 已刷新：拉取 ${result.pulled}，上传 ${result.pushed}，删除 ${result.deleted}，失败 ${result.failed}`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private async removeSource(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }

	    try {
	      await this.requireService().removeSource(sourceId);
	      await this.loadSources();
	      await this.loadEvents();
	      this.syncStatus = `日历源已删除：${source.name}`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private async removeRemoteSource(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }
	    if (source.sourceType !== "caldav") {
	      this.syncStatus = "只有 CalDAV 日历源支持远端删除";
	      return;
	    }

	    this.remoteDeleteConfirmSourceId = sourceId;
	    this.syncStatus = `再次点击「确认删」将删除远端日历源：${source.name}`;
	  }

  private async confirmRemoveRemoteSource(source: CalendarSource): Promise<void> {
    const sourceId: string = source.id ?? "";
    if (sourceId.length === 0) {
      return;
    }

    try {
      await this.requireService().removeRemoteSource(sourceId);
      this.remoteDeleteConfirmSourceId = "";
      await this.loadSources();
      await this.loadEvents();
      this.syncStatus = `远端日历源已删除：${source.name}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    }
  }

	  private async addSourceShareMember(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    const email: string = this.sourceShareEmailInput.trim();
	    if (source.sourceType !== "caldav") {
	      this.syncStatus = "只有 CalDAV 日历源支持共享权限";
	      return;
	    }
	    if (sourceId.length === 0 || email.length === 0) {
	      this.syncStatus = "请先填写共享成员邮箱";
	      return;
    }

    const members: Object[] = this.parseShareMembers(source.sharePermissionsJson ?? "");
    const normalized: string = email.toLowerCase();
    const filtered: Object[] = members.filter((item: Object) => {
      const holder = item as Record<string, string>;
      return (holder["email"] ?? "").toLowerCase() !== normalized;
    });
    filtered.push(JSON.parse(JSON.stringify({
      email,
      role: this.sourceShareRoleInput === "write" ? "write" : "read",
      addedAt: Date.now()
    })));

    try {
      await this.requireService().updateSourceSharePermissions(sourceId, JSON.stringify(filtered));
      this.sourceShareEmailInput = "";
      await this.loadSources();
      this.syncStatus = `共享成员已保存：${email}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    }
  }

	  private async renameRemoteSource(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }
	    if (source.sourceType !== "caldav") {
	      this.syncStatus = "只有 CalDAV 日历源支持远端改名";
	      return;
	    }

    const nextName: string = this.remoteSourceNameInput.trim().length > 0 ? this.remoteSourceNameInput.trim() : source.name;
    try {
      await this.requireService().updateRemoteSourceMetadata(sourceId, nextName, this.categoryColorInput);
      this.remoteSourceNameInput = "";
      await this.loadSources();
      this.syncStatus = `日历源已更新：${nextName}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    }
  }

	  private async cycleSourceRefreshPolicy(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }

	    const current: number = source.refreshIntervalMinutes ?? 15;
	    let nextInterval: number = 15;
	    let nextPolicy: string = "manualAndInterval";
	    if ((source.refreshPolicy ?? "manualAndInterval") === "manualOnly") {
	      nextInterval = 15;
	    } else if (current <= 15) {
	      nextInterval = 60;
	    } else {
	      nextInterval = 0;
	      nextPolicy = "manualOnly";
	    }

	    try {
	      await this.requireService().updateSourceRefreshPolicy(sourceId, nextInterval, nextPolicy);
	      await this.loadSources();
	      this.syncStatus = nextPolicy === "manualOnly" ? `${source.name} 已改为手动刷新` : `${source.name} 每 ${nextInterval} 分钟刷新`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private async saveSubscriptionSource(): Promise<void> {
	    try {
	      const source: CalendarSource = await this.requireService().saveSubscriptionSource(
	        this.subscriptionNameInput,
	        this.subscriptionUrlInput,
	        this.categoryColorInput
	      );
	      this.subscriptionNameInput = "";
	      this.subscriptionUrlInput = "";
	      await this.loadSources();
	      this.syncStatus = `订阅源已添加：${source.name}`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

  private async createRemoteSource(): Promise<void> {
    const account: CalendarAccount | null = await this.requireService().loadAccount();
    const accountId: string = account?.id ?? "";
    if (accountId.length === 0) {
      this.syncStatus = "请先选择一个 CalDAV 账号";
      return;
    }

    try {
      const source: CalendarSource = await this.requireService().createRemoteCalDavSource(
        accountId,
        this.remoteSourceNameInput.trim().length > 0 ? this.remoteSourceNameInput.trim() : "新日历",
        this.categoryColorInput
      );
      this.remoteSourceNameInput = "";
      await this.loadSources();
      this.syncStatus = `远端日历已创建：${source.name}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    }
  }

	  private async importIcsText(): Promise<void> {
	    try {
	      const imported: number = await this.requireService().importIcs(this.icsTextInput, this.defaultWritableSourceId());
	      await this.loadEvents();
	      this.syncStatus = `ICS 已导入 ${imported} 项`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private async exportIcsText(): Promise<void> {
	    try {
	      this.icsTextInput = await this.requireService().exportIcs();
	      this.syncStatus = `ICS 已导出 ${this.visibleEvents().length} 项`;
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private openSettings(): void {
    this.appPage = "settings";
  }

  private closeAccountForm(): void {
    this.showAccountForm = false;
    this.accountFormStatus = "";
    this.isSavingAccount = false;
    this.isTestingConnection = false;
  }

  private newAccountForm(): void {
    this.resetAccountFormState();
    this.accountIdInput = "";
    this.accountNameInput = "";
	    this.serverUrl = DEFAULT_ZOHO_CALDAV_URL;
	    this.username = "";
	    this.password = "";
	    this.authTypeInput = "basic";
	    this.bearerTokenInput = "";
	    this.customHeadersJsonInput = "";
	    this.showAccountForm = true;
	  }

  private editAccount(account: CalendarAccount): void {
    this.resetAccountFormState();
    this.accountIdInput = account.id ?? "";
    this.accountNameInput = account.displayName ?? "";
	    this.serverUrl = account.serverUrl;
	    this.username = account.username;
	    this.password = account.password;
	    this.authTypeInput = this.authTypeValue(account.authType);
	    this.bearerTokenInput = account.bearerToken ?? "";
	    this.customHeadersJsonInput = account.customHeadersJson ?? "";
	    this.showAccountForm = true;
	  }

	  private resetAccountFormState(): void {
	    this.accountFormStatus = "";
	    this.isSavingAccount = false;
	    this.isTestingConnection = false;
	  }

	  private authTypeValue(value: string | undefined): CalendarAuthType {
	    if (value === "bearer" || value === "none" || value === "custom") {
	      return value;
	    }
	    return "basic";
	  }

  private applyProviderPreset(value: string): void {
    if (value === "custom") {
      this.serverUrl = "";
      this.accountFormStatus = "";
      return;
    }

    const preset = providerPresetFor(value);
    this.applyAccountPreset(preset.displayName, preset.serverUrl, `已应用 ${preset.displayName} 预设，${preset.authHint}`);
  }

  private applyAccountPreset(name: string, url: string, message: string): void {
    if (this.accountNameInput.trim().length === 0) {
      this.accountNameInput = name;
    }
    this.serverUrl = url;
    this.accountFormStatus = message;
  }

  private providerTypeFromServerUrl(url: string): string {
    return inferCalendarProviderType(url);
  }

  private currentAccountProviderType(): string {
    return this.providerTypeFromServerUrl(this.serverUrl);
  }

  private accountUsernamePlaceholder(): string {
    return this.currentAccountProviderType() === "icloud" ? "完整 Apple ID 邮箱" : "name@example.com";
  }

  private accountPasswordPlaceholder(): string {
    return this.currentAccountProviderType() === "icloud" ? "Apple 应用专用密码，不是登录密码" : "应用专用密码";
  }

  private providerDiagnosticHint(providerType: string, message: string = ""): string {
    return providerDiagnosticHint(providerType, message);
  }

  private connectionDiagnosticSummary(value: string): string {
    try {
      const parsed = JSON.parse(value) as Record<string, Object>;
      const roots = parsed["rootsTried"] as Object[];
      const principals = parsed["principalUrls"] as Object[];
      const homes = parsed["homeSetUrls"] as Object[];
      const errors = parsed["discoveryErrors"] as Object[];
      return `roots ${Array.isArray(roots) ? roots.length : 0}，principal ${Array.isArray(principals) ? principals.length : 0}，home ${Array.isArray(homes) ? homes.length : 0}，错误 ${Array.isArray(errors) ? errors.length : 0}`;
    } catch {
      return value;
    }
  }

  private accountTitle(account: CalendarAccount): string {
    const name: string = (account.displayName ?? "").trim();
    if (name.length > 0) {
      return name;
    }

    return account.username.length > 0 ? account.username : "CalDAV 账号";
  }

  private accountProviderMeta(account: CalendarAccount): string {
    const providerType: string = account.providerType ?? this.providerTypeFromServerUrl(account.serverUrl);
    const preset = providerPresetFor(providerType);
    return `${preset.displayName} · ${preset.authHint}`;
  }

  private visibleSourceCount(): number {
    return this.sources.filter((source: CalendarSource) => source.isVisible).length;
  }

  private defaultWritableSourceId(): string {
    const source: CalendarSource | null = this.defaultWritableSourceForKind(this.eventKindInput);
    return source === null ? "" : source.id ?? "";
  }

  private defaultWritableSource(): CalendarSource | null {
    return this.defaultWritableSourceForKind("calendar");
  }

  private defaultWritableSourceForKind(kind: CalendarEventKind): CalendarSource | null {
	    const defaults: CalendarSource[] = this.sources.filter((source: CalendarSource) =>
      source.isDefault && this.sourceCanWrite(source) && this.sourceSupportsEventKind(source, kind));
    if (defaults.length > 0) {
      return defaults[0];
    }

	    const writable: CalendarSource[] = this.sources.filter((source: CalendarSource) =>
      this.sourceCanWrite(source) && this.sourceSupportsEventKind(source, kind));
    if (writable.length > 0) {
      return writable[0];
    }

    const fallback: CalendarSource[] = this.sources.filter((source: CalendarSource) => this.sourceSupportsEventKind(source, kind));
    return fallback.length > 0 ? fallback[0] : this.sources.length > 0 ? this.sources[0] : null;
  }

  private defaultSourceTitle(): string {
    const source: CalendarSource | null = this.defaultWritableSourceForKind(this.eventKindInput);
    return source === null ? "本地默认日历" : source.name;
  }

  private defaultSourceSubtitle(): string {
    const source: CalendarSource | null = this.defaultWritableSourceForKind(this.eventKindInput);
    return source === null ? "添加 CalDAV 后会同步" : source.collectionUrl;
  }

  private defaultSourceColor(): string {
    const source: CalendarSource | null = this.defaultWritableSourceForKind(this.eventKindInput);
    return source === null ? PRIMARY_COLOR : this.sourceColor(source);
  }

  private selectedFormSource(): CalendarSource | null {
    if (this.selectedSourceIdInput.length > 0) {
      const selected: CalendarSource | undefined = this.sources.find((source: CalendarSource) =>
        (source.id ?? "") === this.selectedSourceIdInput &&
          this.sourceCanWrite(source) &&
          this.sourceSupportsEventKind(source, this.eventKindInput));
      if (selected !== undefined) {
        return selected;
      }
    }

    return this.defaultWritableSourceForKind(this.eventKindInput);
  }

  private formSource(): CalendarSource | null {
    const event: CalendarEvent | null = this.editingEvent();
    if (event !== null) {
      return this.sourceForEvent(event);
    }

    return this.selectedFormSource();
  }

  private formSourceTitle(): string {
    const source: CalendarSource | null = this.formSource();
    return source === null ? "本地默认日历" : source.name;
  }

  private formSourceSubtitle(): string {
    const source: CalendarSource | null = this.formSource();
    if (source === null) {
      return "添加 CalDAV 后会同步";
    }

    const prefix: string = this.editingEventId.length > 0 ? "当前来源" : "点击切换";
    return `${prefix} · ${this.sourceTypeLabel(source)} · ${source.collectionUrl}`;
  }

  private formSourceColor(): string {
    const source: CalendarSource | null = this.formSource();
    return source === null ? PRIMARY_COLOR : this.sourceColor(source);
  }

  private cycleFormSource(): void {
    const writable: CalendarSource[] = this.sources.filter((source: CalendarSource) =>
      this.sourceCanWrite(source) && this.sourceSupportsEventKind(source, this.eventKindInput));
    if (writable.length === 0) {
      this.syncStatus = this.eventKindInput === "task" ? "当前没有支持 VTODO 任务的可写日历源" : "当前没有可写日历源";
      return;
    }

    const ids: string[] = writable.map((source: CalendarSource) => source.id ?? "").filter((id: string) => id.length > 0);
    if (ids.length === 0) {
      return;
    }

    const currentIndex: number = ids.indexOf(this.selectedSourceIdInput);
    this.selectedSourceIdInput = ids[(currentIndex + 1) % ids.length];
    const selected: CalendarSource | null = this.selectedFormSource();
    if (selected !== null) {
      this.syncStatus = `保存到：${selected.name}`;
    }
  }

	  private sourceColor(source: CalendarSource): string {
	    return this.normalizedCategoryColor(source.color);
	  }

	  private sourceBackgroundColor(source: CalendarSource): string {
	    return this.normalizedCategoryColor(source.backgroundColor ?? source.color);
	  }

  private sourceColorPalette(): string[] {
    return COLOR_PALETTE_CLASSIC;
  }

  private sourceForEvent(event: CalendarEvent): CalendarSource | null {
    const found: CalendarSource | undefined = this.sources.find((source: CalendarSource) => (source.id ?? "") === event.sourceId);
    return found === undefined ? null : found;
  }

  private sourceEventCount(source: CalendarSource): number {
    const sourceId: string = source.id ?? "";
    return this.events.filter((event: CalendarEvent) => event.sourceId === sourceId && event.syncStatus !== "deleted").length;
  }

	  private sourceTypeLabel(source: CalendarSource): string {
	    if (source.sourceType === "subscription") {
	      return "订阅";
	    }

	    if (source.sourceType === "local") {
	      return "本地";
	    }

	    return "CalDAV";
	  }

	  private sourceSyncMeta(source: CalendarSource): string {
	    if ((source.sourceLoadingState ?? "") === "loading") {
	      return "正在同步/发现日历源";
	    }

	    if ((source.lastSyncError ?? "").length > 0) {
	      const status: string = (source.lastSyncHttpStatus ?? 0) > 0 ? ` HTTP ${source.lastSyncHttpStatus}` : "";
	      const retry: string = (source.retryAfterSeconds ?? 0) > 0 ? ` · 建议 ${source.retryAfterSeconds} 秒后重试` : "";
	      return `同步异常${status}：${source.lastSyncError ?? ""}${retry}`;
	    }

	    if ((source.lastDiscoveryError ?? "").length > 0) {
	      return `发现提示：${source.lastDiscoveryError ?? ""}`;
	    }

	    const owner: string = (source.ownerEmail ?? "").length > 0 ? ` · ${source.ownerEmail}` : "";
	    const successAt: number = source.lastSuccessfulSyncAt ?? source.lastSyncAt ?? 0;
	    if (successAt > 0) {
	      return `上次同步 ${formatDateTime(successAt)}${owner}`;
	    }

	    return `等待同步${owner}`;
	  }

	  private sourceCapabilityMeta(source: CalendarSource): string {
	    if (source.sourceType === "subscription") {
	      return "能力：ICS 订阅 · 只读 · 定时刷新";
	    }
	    if (source.sourceType === "local") {
	      return "能力：本地日历 · 离线可写";
	    }

	    const parts: string[] = [];
	    const reports: string[] = this.parseReportListJson(source.supportedReportsJson ?? "");
	    const components: string[] = this.parseComponentListJson(source.supportedComponentsJson ?? "");
	    if (reports.indexOf("sync-collection") >= 0) {
	      parts.push("增量同步");
	    }
	    if (reports.indexOf("free-busy-query") >= 0 || (source.scheduleOutboxUrl ?? "").length > 0) {
	      parts.push("忙闲");
	    }
	    if (components.indexOf("VEVENT") >= 0 || components.length === 0) {
	      parts.push("事件");
	    }
	    if (components.indexOf("VTODO") >= 0) {
	      parts.push("任务");
	    }
	    if ((source.scheduleInboxUrl ?? "").length > 0 || (source.scheduleOutboxUrl ?? "").length > 0) {
	      parts.push("日程邀请");
	    }
	    if ((source.principalUrl ?? "").length > 0) {
	      parts.push("Principal");
	    }
	    if ((source.homeSetUrl ?? "").length > 0) {
	      parts.push("HomeSet");
	    }
	    if ((source.syncStrategy ?? "").length > 0) {
	      parts.push(`策略 ${source.syncStrategy ?? ""}`);
	    }
	    if ((source.lastSyncHttpStatus ?? 0) > 0) {
	      parts.push(`HTTP ${source.lastSyncHttpStatus}`);
	    }
	    if ((source.retryAfterSeconds ?? 0) > 0) {
	      parts.push(`Retry-After ${source.retryAfterSeconds}s`);
	    }
	    if ((source.lastSyncDiagnosticJson ?? "").length > 0) {
	      const diagnostic: string = this.sourceDiagnosticSummary(source.lastSyncDiagnosticJson ?? "");
	      if (diagnostic.length > 0) {
	        parts.push(diagnostic);
	      }
	    }
	    if ((source.capabilitySource ?? "").length > 0) {
	      parts.push(this.capabilitySourceLabel(source.capabilitySource ?? ""));
	    }
	    if ((source.discoveryTraceJson ?? "").length > 0) {
	      const traceSummary: string = this.sourceDiscoverySummary(source.discoveryTraceJson ?? "");
	      if (traceSummary.length > 0) {
	        parts.push(traceSummary);
	      }
	    }
	    if ((source.nativeCalendarSyncState ?? "").length > 0) {
	      parts.push(`系统 ${source.nativeCalendarSyncState ?? ""}`);
	    }
	    if ((source.widgetConfigJson ?? "").length > 0) {
	      parts.push("Widget");
	    }
		    const permissionParts: string[] = this.sourcePermissionLabels(source);
		    permissionParts.forEach((part: string) => parts.push(part));

	    return parts.length > 0 ? `能力：${parts.join(" · ")}` : "能力：等待服务端发现";
	  }

  private capabilitySourceLabel(value: string): string {
    if (value === "server-propfind") {
      return "服务端能力";
    }
    if (value === "principal-propfind") {
      return "Principal 能力";
    }
    if (value === "provider-hint") {
      return "预设能力";
    }
    if (value === "ics-subscription") {
      return "订阅能力";
    }
    if (value === "not-discovered") {
      return "未发现";
    }
    return value;
  }

  private sourceDiscoverySummary(value: string): string {
    try {
      const parsed = JSON.parse(value) as Record<string, Object>;
      const sourceCount: number = Number(parsed["discoveredSources"] ?? 0);
      const principalUrls = parsed["principalUrls"] as Object[];
      const homeSetUrls = parsed["homeSetUrls"] as Object[];
      return `发现 ${sourceCount >= 0 ? sourceCount : 0}/${Array.isArray(principalUrls) ? principalUrls.length : 0}/${Array.isArray(homeSetUrls) ? homeSetUrls.length : 0}`;
    } catch {
      return "";
    }
  }

  private sourceDiagnosticSummary(value: string): string {
    try {
      const parsed = JSON.parse(value) as Record<string, Object>;
      const code: string = `${parsed["code"] ?? ""}`;
      const hint: string = `${parsed["hint"] ?? ""}`;
      const status: number = Number(parsed["httpStatus"] ?? 0);
      if (code.length > 0) {
        return `诊断 ${code}`;
      }
      if (hint.length > 0) {
        return `诊断 ${hint}`;
      }
      if (status > 0) {
        return `诊断 HTTP ${status}`;
      }
      return "诊断已记录";
    } catch {
      return "";
    }
  }

  private sourceShareMeta(source: CalendarSource): string {
    const members: Object[] = this.parseShareMembers((source.shareUsersJson ?? "").length > 0 ?
      source.shareUsersJson ?? "" : source.sharePermissionsJson ?? "");
    if (members.length === 0) {
      if ((source.publicShareUrl ?? "").length > 0) {
        return `共享：公开链接 ${source.publicShareUrl ?? ""}`;
      }
      return "共享：未配置";
    }

    const first = members[0] as Record<string, string>;
    const suffix: string = members.length > 1 ? ` +${members.length - 1}` : "";
    const diagnostic: string = (first["diagnostic"] ?? "").length > 0 ? ` · ${first["diagnostic"]}` : "";
    return `共享：${first["email"] ?? "成员"} ${this.shareRoleLabel(first["role"] ?? "read")}${suffix}${diagnostic}`;
  }

  private parseShareMembers(value: string): Object[] {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return [];
    }

    try {
      const parsed: Object = JSON.parse(trimmed);
      return Array.isArray(parsed) ? parsed as Object[] : [];
    } catch {
      return [];
    }
  }

  private shareRoleLabel(role: string): string {
    return role === "write" ? "可写" : "只读";
  }

  private parseReportListJson(value: string): string[] {
    return this.parseStringListJson(value, false);
  }

  private parseComponentListJson(value: string): string[] {
    return this.parseStringListJson(value, true);
  }

  private parseStringListJson(value: string, uppercase: boolean): string[] {
	    const trimmed: string = value.trim();
	    if (trimmed.length === 0) {
	      return [];
	    }
    const normalize = (item: string): string => uppercase ? `${item}`.toUpperCase() : `${item}`.toLowerCase();

	    try {
	      const parsed = JSON.parse(trimmed) as string[];
	      if (!Array.isArray(parsed)) {
	        return [];
	      }
	      return parsed.map((item: string) => normalize(item));
	    } catch {
	      return trimmed.split(/[,\n;]/).map((item: string) => normalize(item.trim())).filter((item: string) => item.length > 0);
	    }
	  }

  private parseStringArrayJson(value: string): string[] {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return [];
    }

    try {
      const parsed = JSON.parse(trimmed) as string[];
      if (!Array.isArray(parsed)) {
        return [];
      }
      return parsed.map((item: string) => `${item}`.trim()).filter((item: string) => item.length > 0);
    } catch {
      return trimmed.split(/[,\n;]/).map((item: string) => item.trim()).filter((item: string) => item.length > 0);
    }
  }

  private parseObjectArrayJson(value: string): Object[] {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return [];
    }

    try {
      const parsed: Object = JSON.parse(trimmed);
      return Array.isArray(parsed) ? parsed as Object[] : [];
    } catch {
      return [];
    }
  }

	  private sourceRefreshButtonLabel(source: CalendarSource): string {
	    if ((source.refreshPolicy ?? "manualAndInterval") === "manualOnly") {
	      return "手动";
	    }

	    const minutes: number = source.refreshIntervalMinutes ?? 15;
	    if (minutes >= 60) {
	      return "1小时";
	    }
	    return `${minutes}分`;
	  }

  private recentDateMarkers(): CalendarDateMarker[] {
    return this.dateMarkers.slice(0, 5);
  }

  private markerTypeLabel(value: string): string {
    if (value === "multi-dot") {
      return "多点标记";
    }
    if (value === "period" || value === "multi-period") {
      return "区间标记";
    }
    if (value === "custom") {
      return "自定义标记";
    }
    return "日期标记";
  }

  private markerDateLabel(marker: CalendarDateMarker): string {
    const start: string = this.formatFullDate(marker.markerDate);
    if ((marker.periodStart ?? 0) > 0 && (marker.periodEnd ?? 0) > 0 && !sameDay(marker.periodStart ?? 0, marker.periodEnd ?? 0)) {
      return `${this.formatFullDate(marker.periodStart ?? marker.markerDate)} 至 ${this.formatFullDate(marker.periodEnd ?? marker.markerDate)}`;
    }
    return start;
  }

  private async testConnection(): Promise<void> {
    if (this.isTestingConnection) {
      return;
    }

    this.isTestingConnection = true;
    this.accountFormStatus = "正在测试 CalDAV";

    try {
      const providerType: string = this.providerTypeFromServerUrl(this.serverUrl);
      const normalizedServerUrl: string = normalizeProviderServerUrl(providerType, this.serverUrl, this.username);
      const result: CalendarConnectionTestResult = await this.requireService().testConnection({
        providerType,
	        providerPresetJson: buildProviderPresetJson(providerType, normalizedServerUrl),
	        serverUrl: normalizedServerUrl,
	        username: this.username,
	        password: this.password,
	        authType: this.authTypeInput,
	        bearerToken: this.bearerTokenInput,
	        customHeadersJson: this.customHeadersJsonInput
	      });
      this.accountFormStatus = `连接成功：${result.providerType} · ${result.capabilities} · 标准地址 ${result.normalizedServerUrl} · ` +
        `collection ${result.collectionUrl} · 策略 ${result.syncStrategy ?? "未知"} · ` +
        `发现 ${result.sources} 个源，首个源 ${result.total} 个对象，已解析 ${result.parsed}，失败 ${result.failed}。` +
        `${result.authHint}；${result.discoveryHint}；${result.diagnosticHint}；发现轨迹：${result.discoveryTrace}`;
      if ((result.diagnosticJson ?? "").length > 0) {
        this.accountFormStatus = `${this.accountFormStatus}；诊断：${this.connectionDiagnosticSummary(result.diagnosticJson ?? "")}`;
      }
      this.syncStatus = "CalDAV 连接成功";
    } catch (error) {
      const providerType: string = this.providerTypeFromServerUrl(this.serverUrl);
      this.accountFormStatus = `${this.describeError(error)}。${this.providerDiagnosticHint(providerType, this.describeError(error))}`;
      this.syncStatus = this.accountFormStatus;
    } finally {
      this.isTestingConnection = false;
    }
  }

  private async loadEvents(): Promise<void> {
    await this.loadSources();
    this.events = await this.requireService().listEvents();
  }

  private async syncNow(): Promise<void> {
    if (this.isSyncing) {
      return;
    }

    this.isSyncing = true;
    this.syncStatus = "正在同步 CalDAV";

    try {
      const result: CalendarSyncResult = await this.requireService().sync();
      await this.loadSources();
      await this.loadEvents();
      this.syncStatus = `同步完成：拉取 ${result.pulled}，上传 ${result.pushed}，删除 ${result.deleted}，失败 ${result.failed}`;
    } catch (error) {
      this.syncStatus = this.describeError(error);
    } finally {
      this.isSyncing = false;
    }
  }

	  private async syncAfterMutation(successMessage: string): Promise<void> {
    if (this.accounts.length === 0) {
      this.syncStatus = successMessage;
      return;
    }

    this.syncStatus = successMessage;
	    await this.syncNow();
	  }

	  private async checkFreeBusyForForm(): Promise<void> {
	    const startAt: number = this.parseInputDate(this.startInput);
	    const endAt: number = this.parseInputDate(this.endInput);
	    this.freeBusyConflictSummary = "";
	    this.scheduleSuggestionStatus = "";
	    this.scheduleSuggestions = [];
	    if (startAt <= 0 || endAt <= startAt) {
	      this.freeBusyStatus = "请先填写有效开始和结束时间";
	      return;
	    }

	    const sourceIds: string[] = this.freeBusySourceIdsForForm();
	    if (sourceIds.length === 0) {
	      this.freeBusyStatus = "当前没有可查询的 CalDAV 日历源";
	      return;
	    }

	    try {
	      const results: CalendarFreeBusyResult[] = await this.requireService().queryFreeBusy(startAt, endAt, sourceIds);
	      this.freeBusyStatus = this.freeBusySummary(results);
	      this.freeBusyConflictSummary = this.freeBusyConflictDetails(results, startAt, endAt);
	      this.scheduleSuggestions = this.buildScheduleSuggestions(results, startAt, endAt);
	      this.scheduleSuggestionStatus = this.scheduleSuggestions.length > 0 ?
	        `推荐 ${this.scheduleSuggestions.length} 个可用时段` : "当前查询窗口内未找到可用时段";
	    } catch (error) {
	      this.freeBusyStatus = `忙闲查询失败：${this.describeError(error)}`;
	    }
	  }

	  private freeBusySourceIdsForForm(): string[] {
	    const ids: string[] = [];
	    const append = (sourceId: string): void => {
	      const source: CalendarSource | undefined = this.sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
	      if (sourceId.length > 0 && ids.indexOf(sourceId) < 0 && source?.freeBusyTransparent !== true) {
	        ids.push(sourceId);
	      }
	    };
	    append(this.currentFormSourceId());

	    const attendees: string[] = this.normalizedInputList(this.attendeesInput).split(",")
	      .map((item: string) => item.trim().toLowerCase())
	      .filter((item: string) => item.length > 0);
	    this.parseStringArrayJson(this.roomIdsJsonInput).forEach((item: string) => attendees.push(item.toLowerCase()));
	    this.parseStringArrayJson(this.resourceIdsJsonInput).forEach((item: string) => attendees.push(item.toLowerCase()));

	    this.sources.forEach((source: CalendarSource) => {
	      const owner: string = (source.ownerEmail ?? "").toLowerCase();
	      const addresses: string = (source.calendarUserAddressSet ?? "").toLowerCase();
	      if (source.sourceType === "caldav" && source.freeBusyTransparent !== true &&
	        attendees.find((email: string) => owner === email || addresses.indexOf(email) >= 0) !== undefined) {
	        append(source.id ?? "");
	      }
	    });

	    return ids;
	  }

	  private freeBusySummary(results: CalendarFreeBusyResult[]): string {
	    if (results.length === 0) {
	      return "未找到可查询的 CalDAV 源";
	    }

	    const failed: CalendarFreeBusyResult[] = results.filter((result: CalendarFreeBusyResult) => result.failed);
	    const busySlots: number = results.reduce((sum: number, result: CalendarFreeBusyResult) => sum + result.slots.length, 0);
	    if (failed.length > 0) {
	      return `忙闲查询失败 ${failed.length} 个源：${failed[0].error ?? "未知错误"}`;
	    }

	    if (busySlots === 0) {
	      return "忙闲查询完成：该时段未返回占用";
	    }

	    const firstBusy: CalendarFreeBusyResult | undefined = results.find((result: CalendarFreeBusyResult) => result.slots.length > 0);
	    if (firstBusy === undefined) {
	      return `忙闲查询完成：发现 ${busySlots} 个占用时段`;
	    }

	    const firstSlot: CalendarFreeBusySlot = firstBusy.slots[0];
	    return `忙闲查询完成：${results.length} 个源，发现 ${busySlots} 个占用；最近 ${formatTime(firstSlot.startAt)}-${formatTime(firstSlot.endAt)} ${firstBusy.ownerEmail}`;
	  }

	  private freeBusyConflictDetails(results: CalendarFreeBusyResult[], startAt: number, endAt: number): string {
	    const items: ScheduleBusyItem[] = this.busyItemsInRange(results, startAt, endAt);
	    if (items.length === 0) {
	      return "";
	    }

	    return items.slice(0, 4).map((item: ScheduleBusyItem) => {
	      const owner: string = item.ownerEmail.length > 0 ? item.ownerEmail : item.sourceId;
	      return `${formatTime(item.startAt)}-${formatTime(item.endAt)} ${owner}`;
	    }).join("；");
	  }

	  private busyItemsInRange(results: CalendarFreeBusyResult[], startAt: number, endAt: number): ScheduleBusyItem[] {
	    const items: ScheduleBusyItem[] = [];
	    results.forEach((result: CalendarFreeBusyResult) => {
	      result.slots.forEach((slot: CalendarFreeBusySlot) => {
	        if (slot.endAt > startAt && slot.startAt < endAt) {
	          items.push({
	            sourceId: result.sourceId,
	            ownerEmail: result.ownerEmail,
	            startAt: Math.max(slot.startAt, startAt),
	            endAt: Math.min(slot.endAt, endAt),
	            busyType: slot.busyType
	          });
	        }
	      });
	    });
	    return items.sort((left: ScheduleBusyItem, right: ScheduleBusyItem) => left.startAt - right.startAt);
	  }

	  private buildScheduleSuggestions(results: CalendarFreeBusyResult[], startAt: number, endAt: number): ScheduleSuggestion[] {
	    const duration: number = endAt - startAt;
	    const dayStart: number = startOfDay(startAt);
	    const minHour: number = Math.max(0, Math.min(23, this.viewConfig.minHour));
	    const maxHour: number = Math.max(minHour + 1, Math.min(24, this.viewConfig.maxHour));
	    let windowStart: number = Math.max(startAt, dayStart + minHour * 60 * 60 * 1000);
	    let windowEnd: number = dayStart + maxHour * 60 * 60 * 1000;
	    if (windowEnd <= windowStart + duration) {
	      windowEnd = startAt + 8 * 60 * 60 * 1000;
	    }

	    const busy: ScheduleBusyItem[] = this.busyItemsInRange(results, windowStart, windowEnd);
	    const merged: ScheduleBusyItem[] = [];
	    busy.forEach((item: ScheduleBusyItem) => {
	      const last: ScheduleBusyItem | undefined = merged.length > 0 ? merged[merged.length - 1] : undefined;
	      if (last !== undefined && item.startAt <= last.endAt) {
	        merged[merged.length - 1] = {
	          sourceId: last.sourceId,
	          ownerEmail: last.ownerEmail,
	          startAt: last.startAt,
	          endAt: Math.max(last.endAt, item.endAt),
	          busyType: last.busyType
	        };
	      } else {
	        merged.push(item);
	      }
	    });

	    const suggestions: ScheduleSuggestion[] = [];
	    let cursor: number = this.roundUpToSlot(windowStart, this.viewConfig.timeSlotMinutes);
	    merged.forEach((item: ScheduleBusyItem) => {
	      this.appendScheduleSuggestions(suggestions, cursor, item.startAt, duration);
	      cursor = Math.max(cursor, this.roundUpToSlot(item.endAt, this.viewConfig.timeSlotMinutes));
	    });
	    this.appendScheduleSuggestions(suggestions, cursor, windowEnd, duration);
	    return suggestions.slice(0, 3);
	  }

	  private appendScheduleSuggestions(
	    suggestions: ScheduleSuggestion[],
	    rangeStart: number,
	    rangeEnd: number,
	    duration: number
	  ): void {
	    const slotMs: number = Math.max(15, this.viewConfig.timeSlotMinutes) * 60 * 1000;
	    let candidate: number = this.roundUpToSlot(rangeStart, this.viewConfig.timeSlotMinutes);
	    while (candidate + duration <= rangeEnd && suggestions.length < 3) {
	      const suggestionEnd: number = candidate + duration;
	      suggestions.push({
	        startAt: candidate,
	        endAt: suggestionEnd,
	        label: `${formatTime(candidate)}-${formatTime(suggestionEnd)}`
	      });
	      candidate += slotMs;
	    }
	  }

	  private roundUpToSlot(timestamp: number, slotMinutes: number): number {
	    const slotMs: number = Math.max(15, slotMinutes) * 60 * 1000;
	    return Math.ceil(timestamp / slotMs) * slotMs;
	  }

	  private applyScheduleSuggestion(suggestion: ScheduleSuggestion): void {
	    this.startInput = formatDateTime(suggestion.startAt);
	    this.endInput = formatDateTime(suggestion.endAt);
	    this.freeBusyStatus = `已应用推荐时段：${suggestion.label}`;
	    this.clearFormError();
	  }

	  private async createEvent(): Promise<void> {
	    let draft: CalendarEventDraft | null = this.buildDraftFromForm();
    if (draft === null) {
      return;
	    }

	    try {
	      if (this.currentFormSourceReadOnly()) {
	        this.formError = "当前日历源为只读，不能修改";
	        this.syncStatus = this.formError;
	        return;
	      }

      if (!this.currentFormSourceSupportsDraft(draft)) {
        return;
      }

	      await this.requireService().createEvent(draft);
      this.resetEventForm();
      this.appPage = "calendar";
      await this.loadEvents();
      await this.syncAfterMutation("已创建本地日程");
    } catch (error) {
      this.formError = `保存失败：${this.describeError(error)}`;
      this.syncStatus = this.formError;
    }
  }

  private async updateEvent(): Promise<void> {
    const event: CalendarEvent | null = this.editingEvent();
    if (event === null) {
      this.syncStatus = "编辑的日程不存在";
      this.cancelEditing();
      return;
    }

    const draft: CalendarEventDraft | null = this.buildDraftFromForm();
    if (draft === null) {
      return;
	    }

		    try {
		      if (this.currentFormSourceReadOnly()) {
		        this.formError = "当前日历源为只读，不能修改";
		        this.syncStatus = this.formError;
		        return;
		      }

      if (!this.currentFormSourceSupportsDraft(draft)) {
        return;
      }

		      if (this.recurrenceEditScope === "instance" && this.editingOccurrenceStartAt > 0 && (event.rrule ?? "").trim().length > 0) {
	        await this.updateRecurringInstance(event, draft);
	        this.resetEventForm();
	        this.appPage = "calendar";
	        await this.loadEvents();
	        await this.syncAfterMutation("已保存本次重复日程");
	        return;
	      }

	      if (this.recurrenceEditScope === "future" && this.editingOccurrenceStartAt > 0 && (event.rrule ?? "").trim().length > 0) {
	        await this.updateFutureRecurringEvents(event, draft);
	        this.resetEventForm();
	        this.appPage = "calendar";
	        await this.loadEvents();
	        await this.syncAfterMutation("已保存未来重复日程");
	        return;
	      }

	      await this.requireService().updateEvent(event, draft);
      this.resetEventForm();
      this.appPage = "calendar";
      await this.loadEvents();
      await this.syncAfterMutation("已保存修改");
    } catch (error) {
      this.formError = `保存失败：${this.describeError(error)}`;
      this.syncStatus = this.formError;
    }
  }

	  private async saveEventForm(): Promise<void> {
    if (this.editingEventId.length > 0) {
      await this.updateEvent();
      return;
    }

	    await this.createEvent();
	  }

	  private async updateRecurringInstance(event: CalendarEvent, draft: CalendarEventDraft): Promise<void> {
	    const occurrenceStart: number = this.editingOccurrenceStartAt;
	    const exdate: string = this.appendDateToken(event.exdate ?? "", toUtcIcsDate(occurrenceStart));
	    await this.requireService().updateEvent(event, {
	      sourceId: event.sourceId,
	      eventSourceId: event.eventSourceId,
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
		      exdate,
	      rdate: event.rdate,
	      recurrenceId: event.recurrenceId,
	      sequence: (event.sequence ?? 0) + 1,
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
      constraintJson: event.constraintJson,
      extendedPropsJson: event.extendedPropsJson,
      resourceIdsJson: event.resourceIdsJson,
      roomIdsJson: event.roomIdsJson,
      resourceStatusJson: event.resourceStatusJson,
      alarmAction: event.alarmAction,
      snoozeMinutes: event.snoozeMinutes,
      snoozeTimes: event.snoozeTimes,
      allDayReminderAt: event.allDayReminderAt,
      alarmActionsJson: event.alarmActionsJson
	    });

		    await this.requireService().saveLocalEvent({
		      id: `${event.id}_instance_${occurrenceStart}`,
		      sourceId: event.sourceId,
		      eventSourceId: draft.eventSourceId ?? event.eventSourceId ?? event.sourceId,
	      uid: event.uid,
	      href: "",
	      etag: "",
	      title: draft.title,
	      startAt: draft.startAt,
	      endAt: draft.endAt,
	      allDay: draft.allDay,
	      location: draft.location,
	      notes: draft.notes,
	      reminderMinutes: draft.reminderMinutes,
	      secondReminderMinutes: draft.secondReminderMinutes,
	      rrule: "",
	      categoryColor: draft.categoryColor,
	      backgroundColor: draft.backgroundColor,
	      borderColor: draft.borderColor,
	      textColor: draft.textColor,
	      dragBackgroundColor: draft.dragBackgroundColor,
	      eventCategory: draft.eventCategory,
	      eventKind: draft.eventKind,
	      url: draft.url,
	      attendees: draft.attendees,
	      attendeeJson: draft.attendeeJson,
	      organizerName: draft.organizerName,
	      organizerEmail: draft.organizerEmail,
	      conferenceUrl: draft.conferenceUrl,
      attachmentUrl: draft.attachmentUrl,
      attachmentsJson: draft.attachmentsJson,
      travelMinutes: draft.travelMinutes,
      comingDuration: draft.comingDuration,
			      availability: draft.availability,
			      freeBusyTransparent: draft.freeBusyTransparent,
		      privacy: draft.privacy,
		      timeZone: draft.timeZone,
		      eventStatus: draft.eventStatus,
		      appointmentStatus: draft.appointmentStatus,
		      appointmentCapacity: draft.appointmentCapacity,
		      appointmentBookedCount: draft.appointmentBookedCount,
		      appointmentMinDurationMinutes: draft.appointmentMinDurationMinutes,
		      appointmentMaxDurationMinutes: draft.appointmentMaxDurationMinutes,
		      appointmentBufferBeforeMinutes: draft.appointmentBufferBeforeMinutes,
		      appointmentBufferAfterMinutes: draft.appointmentBufferAfterMinutes,
			      appointmentDeadlineMinutes: draft.appointmentDeadlineMinutes,
			      appointmentPublicUrl: draft.appointmentPublicUrl,
			      appointmentFormJson: draft.appointmentFormJson,
			      appointmentTimezone: draft.appointmentTimezone,
			      appointmentSlotIntervalMinutes: draft.appointmentSlotIntervalMinutes,
			      appointmentApprovalRequired: draft.appointmentApprovalRequired,
			      bookingJson: draft.bookingJson,
			      bookingContactName: draft.bookingContactName,
			      bookingContactEmail: draft.bookingContactEmail,
			      bookingContactPhone: draft.bookingContactPhone,
			      bookingConfirmationStatus: draft.bookingConfirmationStatus,
			      bookingStatus: draft.bookingStatus,
		      exdate: "",
	      rdate: "",
	      recurrenceId: toUtcIcsDate(occurrenceStart),
	      sequence: (event.sequence ?? 0) + 1,
	      reminderOffsets: draft.reminderOffsets,
	      dueAt: draft.dueAt,
	      completedAt: draft.completedAt,
	      priority: draft.priority,
      percentComplete: draft.percentComplete,
      milestoneStatus: draft.milestoneStatus,
      dueDateClass: draft.dueDateClass,
      groupId: draft.groupId,
      displayMode: draft.displayMode,
      overlap: draft.overlap,
      constraintJson: draft.constraintJson,
      extendedPropsJson: draft.extendedPropsJson,
      resourceIdsJson: draft.resourceIdsJson,
      roomIdsJson: draft.roomIdsJson,
      resourceStatusJson: draft.resourceStatusJson,
      alarmAction: draft.alarmAction,
      snoozeMinutes: draft.snoozeMinutes,
      snoozeTimes: draft.snoozeTimes,
      allDayReminderAt: draft.allDayReminderAt,
      alarmActionsJson: draft.alarmActionsJson,
      lastModified: Date.now(),
	      syncStatus: "dirty"
	    });
	  }

	  private async updateFutureRecurringEvents(event: CalendarEvent, draft: CalendarEventDraft): Promise<void> {
	    await this.requireService().updateEvent(event, this.truncatedOriginalDraft(event));
	    await this.requireService().createEvent(this.futureSeriesDraft(event, draft));
	  }

	  private truncatedOriginalDraft(event: CalendarEvent): CalendarEventDraft {
	    const until: number = this.editingOccurrenceStartAt - 1000;
		    return {
		      sourceId: event.sourceId,
		      eventSourceId: event.eventSourceId,
	      title: event.title,
	      startAt: event.startAt,
	      endAt: event.endAt,
	      allDay: event.allDay,
	      location: event.location,
	      notes: event.notes,
	      reminderMinutes: event.reminderMinutes,
	      secondReminderMinutes: event.secondReminderMinutes,
	      rrule: this.withUntil(event.rrule ?? "", until),
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
	      sequence: (event.sequence ?? 0) + 1,
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
      constraintJson: event.constraintJson,
      extendedPropsJson: event.extendedPropsJson,
      resourceIdsJson: event.resourceIdsJson,
      roomIdsJson: event.roomIdsJson,
      resourceStatusJson: event.resourceStatusJson,
      alarmAction: event.alarmAction,
      snoozeMinutes: event.snoozeMinutes,
      snoozeTimes: event.snoozeTimes,
      allDayReminderAt: event.allDayReminderAt,
      alarmActionsJson: event.alarmActionsJson
	    };
	  }

	  private futureSeriesDraft(event: CalendarEvent, draft: CalendarEventDraft): CalendarEventDraft {
		    return {
		      sourceId: event.sourceId,
		      eventSourceId: draft.eventSourceId ?? event.eventSourceId ?? event.sourceId,
	      title: draft.title,
	      startAt: draft.startAt,
	      endAt: draft.endAt,
	      allDay: draft.allDay,
	      location: draft.location,
	      notes: draft.notes,
	      reminderMinutes: draft.reminderMinutes,
	      secondReminderMinutes: draft.secondReminderMinutes,
	      rrule: draft.rrule,
	      categoryColor: draft.categoryColor,
	      backgroundColor: draft.backgroundColor,
	      borderColor: draft.borderColor,
	      textColor: draft.textColor,
	      dragBackgroundColor: draft.dragBackgroundColor,
	      eventCategory: draft.eventCategory,
	      eventKind: draft.eventKind,
	      url: draft.url,
	      attendees: draft.attendees,
	      attendeeJson: draft.attendeeJson,
	      organizerName: draft.organizerName,
	      organizerEmail: draft.organizerEmail,
	      conferenceUrl: draft.conferenceUrl,
      attachmentUrl: draft.attachmentUrl,
      attachmentsJson: draft.attachmentsJson,
      travelMinutes: draft.travelMinutes,
      comingDuration: draft.comingDuration,
			      availability: draft.availability,
			      freeBusyTransparent: draft.freeBusyTransparent,
		      privacy: draft.privacy,
		      timeZone: draft.timeZone,
		      eventStatus: draft.eventStatus,
		      appointmentStatus: draft.appointmentStatus,
		      appointmentCapacity: draft.appointmentCapacity,
		      appointmentBookedCount: draft.appointmentBookedCount,
		      appointmentMinDurationMinutes: draft.appointmentMinDurationMinutes,
		      appointmentMaxDurationMinutes: draft.appointmentMaxDurationMinutes,
		      appointmentBufferBeforeMinutes: draft.appointmentBufferBeforeMinutes,
		      appointmentBufferAfterMinutes: draft.appointmentBufferAfterMinutes,
			      appointmentDeadlineMinutes: draft.appointmentDeadlineMinutes,
			      appointmentPublicUrl: draft.appointmentPublicUrl,
			      appointmentFormJson: draft.appointmentFormJson,
			      appointmentTimezone: draft.appointmentTimezone,
			      appointmentSlotIntervalMinutes: draft.appointmentSlotIntervalMinutes,
			      appointmentApprovalRequired: draft.appointmentApprovalRequired,
			      bookingJson: draft.bookingJson,
			      bookingContactName: draft.bookingContactName,
			      bookingContactEmail: draft.bookingContactEmail,
			      bookingContactPhone: draft.bookingContactPhone,
			      bookingConfirmationStatus: draft.bookingConfirmationStatus,
			      bookingStatus: draft.bookingStatus,
		      exdate: "",
	      rdate: draft.rdate,
	      recurrenceId: "",
	      sequence: 0,
	      reminderOffsets: draft.reminderOffsets,
	      dueAt: draft.dueAt,
	      completedAt: draft.completedAt,
	      priority: draft.priority,
      percentComplete: draft.percentComplete,
      milestoneStatus: draft.milestoneStatus,
      dueDateClass: draft.dueDateClass,
      groupId: draft.groupId,
      displayMode: draft.displayMode,
      overlap: draft.overlap,
      constraintJson: draft.constraintJson,
      extendedPropsJson: draft.extendedPropsJson,
      resourceIdsJson: draft.resourceIdsJson,
      roomIdsJson: draft.roomIdsJson,
      resourceStatusJson: draft.resourceStatusJson,
      alarmAction: draft.alarmAction,
      snoozeMinutes: draft.snoozeMinutes,
      snoozeTimes: draft.snoozeTimes,
      allDayReminderAt: draft.allDayReminderAt,
      alarmActionsJson: draft.alarmActionsJson
	    };
	  }

	  private buildDraftFromForm(): CalendarEventDraft | null {
    const startAt: number = this.parseInputDate(this.startInput);
    const endAt: number = this.parseInputDate(this.endInput);
    const reminderMinutes: number = this.parseOptionalMinutes(this.reminderInput);
    const secondReminderMinutes: number = this.parseOptionalMinutes(this.secondReminderInput);
    const travelMinutes: number = this.parseOptionalMinutes(this.travelMinutesInput);
    const comingDuration: number = this.parseOptionalMinutes(this.comingDurationInput);
    const dueAt: number = this.dueInput.trim().length > 0 ? this.parseInputDate(this.dueInput) : 0;
    const completedAt: number = this.completedInput.trim().length > 0 ? this.parseInputDate(this.completedInput) : 0;
	    const priority: number = this.parseOptionalMinutes(this.priorityInput);
	    const percentComplete: number = this.parseOptionalMinutes(this.percentCompleteInput);
	    const appointmentCapacity: number = this.parseOptionalMinutes(this.appointmentCapacityInput);
	    const appointmentBookedCount: number = this.parseOptionalMinutes(this.appointmentBookedCountInput);
	    const appointmentMinDuration: number = this.parseOptionalMinutes(this.appointmentMinDurationInput);
	    const appointmentMaxDuration: number = this.parseOptionalMinutes(this.appointmentMaxDurationInput);
	    const appointmentBufferBefore: number = this.parseOptionalMinutes(this.appointmentBufferBeforeInput);
	    const appointmentBufferAfter: number = this.parseOptionalMinutes(this.appointmentBufferAfterInput);
	    const appointmentDeadline: number = this.parseOptionalMinutes(this.appointmentDeadlineInput);

    if (this.titleInput.trim().length === 0) {
      this.formError = "请填写标题";
      return null;
    }

    if (startAt <= 0 || endAt <= startAt) {
      this.formError = "请填写有效开始和结束时间";
      return null;
    }

    if (reminderMinutes < 0) {
      this.formError = "提醒分钟必须是 0 或正整数";
      return null;
    }

    if (secondReminderMinutes < 0) {
      this.formError = "第二提醒分钟必须是 0 或正整数";
      return null;
    }

    if (travelMinutes < 0) {
      this.formError = "旅行时间分钟必须是 0 或正整数";
      return null;
    }

    if (comingDuration < 0) {
      this.formError = "返回/收尾时间分钟必须是 0 或正整数";
      return null;
    }

    if (!this.formJsonFieldsValid()) {
      return null;
    }

    if (this.dueInput.trim().length > 0 && dueAt <= 0) {
      this.formError = "请填写有效截止时间";
      return null;
    }

    if (this.completedInput.trim().length > 0 && completedAt <= 0) {
      this.formError = "请填写有效完成时间";
      return null;
    }

    if (priority < 0 || priority > 9) {
      this.formError = "优先级必须是 0 到 9";
      return null;
    }

	    if (percentComplete < 0 || percentComplete > 100) {
	      this.formError = "完成进度必须是 0 到 100";
	      return null;
	    }

	    if (this.eventKindInput === "appointment" && appointmentCapacity <= 0) {
	      this.formError = "预约容量必须大于 0";
	      return null;
	    }

	    if (appointmentBookedCount < 0 || appointmentMinDuration < 0 || appointmentMaxDuration < 0 ||
	      appointmentBufferBefore < 0 || appointmentBufferAfter < 0 || appointmentDeadline < 0) {
	      this.formError = "预约数字字段必须是 0 或正整数";
	      return null;
	    }

		    const attendeeJson: string = this.mergedAttendeeJson();
		    const draft: CalendarEventDraft = {
		      sourceId: this.currentFormSourceId(),
		      eventSourceId: this.currentFormSourceId(),
      title: this.titleInput.trim(),
      startAt,
      endAt: this.allDayInput ? startOfDay(endAt) + DAY_MS : endAt,
      allDay: this.allDayInput,
      location: this.eventKindInput === "reminder" ? "" : this.locationInput.trim(),
      notes: this.notesInput.trim(),
      reminderMinutes,
      secondReminderMinutes,
      rrule: this.rruleInput.trim(),
      categoryColor: this.normalizedCategoryColor(this.categoryColorInput),
      backgroundColor: this.eventBackgroundColorInput.trim(),
      borderColor: this.eventBorderColorInput.trim(),
      textColor: this.eventTextColorInput.trim(),
      dragBackgroundColor: this.eventDragBackgroundColorInput.trim(),
      eventCategory: this.eventKindInput,
      eventKind: this.eventKindInput,
	      url: this.urlInput.trim(),
	      attendees: this.normalizedInputList(this.attendeesInput),
	      attendeeJson,
	      organizerName: this.organizerNameInput.trim(),
      organizerEmail: this.organizerEmailInput.trim(),
      conferenceUrl: this.conferenceUrlInput.trim(),
      attachmentUrl: this.attachmentUrlInput.trim(),
      attachmentsJson: this.attachmentsJsonInput.trim(),
      travelMinutes,
	      comingDuration,
	      availability: this.availabilityInput,
	      freeBusyTransparent: this.availabilityInput === "free",
	      privacy: this.privacyInput,
	      timeZone: this.timeZoneInput.trim(),
	      eventStatus: this.eventStatusInput,
	      appointmentStatus: this.eventKindInput === "appointment" ? this.appointmentStatusInput : "available",
	      appointmentCapacity: this.eventKindInput === "appointment" ? appointmentCapacity : 0,
	      appointmentBookedCount: this.eventKindInput === "appointment" ? appointmentBookedCount : 0,
	      appointmentMinDurationMinutes: this.eventKindInput === "appointment" ? appointmentMinDuration : 0,
	      appointmentMaxDurationMinutes: this.eventKindInput === "appointment" ? appointmentMaxDuration : 0,
	      appointmentBufferBeforeMinutes: this.eventKindInput === "appointment" ? appointmentBufferBefore : 0,
	      appointmentBufferAfterMinutes: this.eventKindInput === "appointment" ? appointmentBufferAfter : 0,
		      appointmentDeadlineMinutes: this.eventKindInput === "appointment" ? appointmentDeadline : 0,
		      appointmentPublicUrl: this.eventKindInput === "appointment" ? this.appointmentPublicUrlInput.trim() : "",
		      appointmentFormJson: this.eventKindInput === "appointment" ? this.appointmentFormJsonInput.trim() : "",
		      appointmentTimezone: this.eventKindInput === "appointment" ? this.timeZoneInput.trim() : "",
		      appointmentSlotIntervalMinutes: this.eventKindInput === "appointment" ? appointmentMinDuration : 0,
		      appointmentApprovalRequired: this.eventKindInput === "appointment" && this.bookingStatusInput.trim() === "approvalRequired",
		      bookingJson: this.eventKindInput === "appointment" ? this.bookingJsonInput.trim() : "",
		      bookingContactName: this.eventKindInput === "appointment" ? this.bookingContactNameInput.trim() : "",
		      bookingContactEmail: this.eventKindInput === "appointment" ? this.bookingContactEmailInput.trim() : "",
		      bookingContactPhone: this.eventKindInput === "appointment" ? this.bookingContactPhoneInput.trim() : "",
		      bookingConfirmationStatus: this.eventKindInput === "appointment" ? this.bookingStatusInput.trim() : "",
		      bookingStatus: this.eventKindInput === "appointment" ? this.bookingStatusInput.trim() : "",
	      exdate: this.normalizedInputList(this.exdateInput),
      rdate: this.normalizedInputList(this.rdateInput),
      reminderOffsets: this.normalizedInputList(this.reminderOffsetsInput),
      dueAt,
      completedAt,
      priority,
	      percentComplete,
	      milestoneStatus: this.milestoneStatusInput.trim(),
	      dueDateClass: this.dueDateClassInput.trim(),
	      groupId: this.groupIdInput.trim(),
	      displayMode: this.displayModeInput.trim(),
	      overlap: this.overlapInput,
	      editable: this.editableInput,
	      startEditable: this.startEditableInput,
	      durationEditable: this.durationEditableInput,
		      resourceEditable: this.resourceEditableInput,
		      interactive: this.interactiveInput,
		      eventReadOnly: this.eventReadOnlyInput,
		      isVisible: true,
		      isPending: this.isPendingInput,
		      isFocused: this.isFocusedInput,
		      overlapPosition: 0,
		      overlapCount: 1,
	      classNames: this.normalizedInputList(this.classNamesInput),
	      customStyleJson: this.customStyleJsonInput.trim(),
	      constraintJson: this.constraintJsonInput.trim(),
	      extendedPropsJson: this.extendedPropsJsonInput.trim(),
	      rawPropsJson: this.rawPropsJsonInput.trim(),
	      resourceIdsJson: this.resourceIdsJsonInput.trim(),
      roomIdsJson: this.roomIdsJsonInput.trim(),
      resourceStatusJson: this.resourceStatusJsonInput.trim(),
      alarmAction: this.alarmActionInput.trim(),
      snoozeMinutes: this.parseOptionalMinutes(this.snoozeMinutesInput),
      snoozeTimes: this.parseOptionalMinutes(this.snoozeTimesInput),
      allDayReminderAt: this.allDayReminderAtInput.trim(),
      alarmActionsJson: this.alarmActionsJsonInput.trim()
    };
	    return draft;
	  }

	  private formJsonFieldsValid(): boolean {
		    const fields: string[] = [
			      this.attachmentsJsonInput,
		      this.appointmentFormJsonInput,
		      this.bookingJsonInput,
			      this.customStyleJsonInput,
		      this.constraintJsonInput,
		      this.extendedPropsJsonInput,
		      this.rawPropsJsonInput,
		      this.resourceIdsJsonInput,
		      this.roomIdsJsonInput,
		      this.resourceStatusJsonInput,
		      this.alarmActionsJsonInput
		    ];
		    const names: string[] = ["多附件", "预约表单", "预订详情", "自定义样式", "约束", "扩展属性", "原始私有字段", "资源", "会议室", "资源状态", "提醒动作"];

	    for (let index = 0; index < fields.length; index += 1) {
	      const value: string = fields[index].trim();
	      if (value.length === 0) {
	        continue;
	      }

	      try {
	        JSON.parse(value);
	      } catch {
	        this.formError = `${names[index]} JSON 格式不正确`;
	        return false;
	      }
	    }

	    return true;
	  }

		  private currentFormSourceId(): string {
		    const event: CalendarEvent | null = this.editingEvent();
		    if (event !== null) {
		      return event.sourceId;
		    }

		    const selected: CalendarSource | null = this.selectedFormSource();
		    if (selected !== null) {
		      return selected.id ?? "";
		    }

		    return this.defaultWritableSourceId();
		  }

		  private currentFormSourceReadOnly(): boolean {
		    return this.sourceIsReadOnly(this.currentFormSourceId());
		  }

  private currentFormSourceSupportsDraft(draft: CalendarEventDraft): boolean {
    const sourceId: string = draft.sourceId ?? this.currentFormSourceId();
    const source: CalendarSource | undefined = this.sources.find((item: CalendarSource) => (item.id ?? "") === sourceId);
    if (source === undefined || source.sourceType !== "caldav") {
      return true;
    }

    const components: string[] = this.parseComponentListJson(source.supportedComponentsJson ?? "");
    if (components.length === 0) {
      return true;
    }

    const required: string = (draft.eventKind ?? "calendar") === "task" ? "VTODO" : "VEVENT";
    if (components.indexOf(required) >= 0) {
      return true;
    }

    this.formError = `${source.name} 不支持 ${required === "VTODO" ? "任务 VTODO" : "事件 VEVENT"}，请切换到支持该组件的日历源`;
    this.syncStatus = this.formError;
    return false;
  }

		  private sourceIsReadOnly(sourceId: string): boolean {
		    if (sourceId.length === 0) {
		      return false;
		    }

	    const found: CalendarSource[] = this.sources.filter((source: CalendarSource) => (source.id ?? "") === sourceId);
	    const event: CalendarEvent | null = this.editingEvent();
		    return found.length > 0 ? (event === null ? !this.sourceCanWrite(found[0]) : !this.sourceCanUpdate(found[0])) : false;
		  }

	  private sourceCanWrite(source: CalendarSource): boolean {
		    if (source.sourceType !== "caldav" || source.isReadOnly) {
		      return false;
		    }

		    const permissions: string = (source.permissionsJson ?? "").toLowerCase();
		    if (permissions.length === 0) {
		      return true;
		    }

    return this.hasDavPrivilege(permissions, "write") || this.hasDavPrivilege(permissions, "bind");
		  }

  private sourceCanDelete(source: CalendarSource): boolean {
    return this.sourceHasWritePrivileges(source, ["write", "unbind"]);
  }

  private sourcePermissionLabels(source: CalendarSource): string[] {
    if (source.sourceType !== "caldav") {
      return source.sourceType === "local" ? ["可写"] : ["只读"];
    }

    if (source.isReadOnly) {
      return ["只读"];
    }

    const labels: string[] = [];
    if (this.sourceCanWrite(source)) {
      labels.push("可新建");
    }
    if (this.sourceCanUpdate(source)) {
      labels.push("可更新");
    }
    if (this.sourceCanDelete(source)) {
      labels.push("可删除");
    }

    return labels.length > 0 ? labels : ["只读"];
  }

  private sourceCanUpdate(source: CalendarSource): boolean {
    return this.sourceHasWritePrivileges(source, ["write", "write-content"]);
  }

  private sourceHasWritePrivileges(source: CalendarSource, required: string[]): boolean {
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

  private sourceSupportsEventKind(source: CalendarSource, kind: CalendarEventKind): boolean {
    if (source.sourceType !== "caldav") {
      return true;
    }

    const components: string[] = this.parseComponentListJson(source.supportedComponentsJson ?? "");
    if (components.length === 0) {
      return true;
    }

    const required: string = kind === "task" ? "VTODO" : "VEVENT";
    return components.indexOf(required) >= 0;
  }

	  private activeSourceFilterIds(): string[] {
	    return this.parseStringArrayJson(this.viewConfig.sourceFilterJson ?? "");
	  }

	  private sourceFilterActive(source: CalendarSource): boolean {
	    return this.activeSourceFilterIds().indexOf(source.id ?? "") >= 0;
	  }

	  private async toggleSourceFilter(source: CalendarSource): Promise<void> {
	    const sourceId: string = source.id ?? "";
	    if (sourceId.length === 0) {
	      return;
	    }

	    const ids: string[] = this.activeSourceFilterIds();
	    const index: number = ids.indexOf(sourceId);
	    if (index >= 0) {
	      ids.splice(index, 1);
	    } else {
	      ids.push(sourceId);
	    }

	    this.viewConfig = await this.requireService().saveViewConfig(withViewConfig(this.viewConfig, "sourceFilterJson", ids.length > 0 ? JSON.stringify(ids) : ""));
	    this.syncStatus = ids.length > 0 ? `已按 ${ids.length} 个日历源过滤` : "已清除日历源过滤";
	  }

		  private addStructuredAttendee(): void {
	    const email: string = this.attendeeEmailInput.trim();
	    if (email.length === 0) {
	      this.formError = "请填写参会人邮箱";
	      return;
	    }

	    const current: string = this.normalizedInputList(this.attendeesInput);
	    const emails: string[] = current.length > 0 ? current.split(",") : [];
	    if (emails.indexOf(email) < 0) {
	      emails.push(email);
	      this.attendeesInput = emails.join(", ");
	    }

	    this.attendeeJsonInput = this.appendAttendeeJson(this.attendeeJsonInput, JSON.parse(JSON.stringify({
	      email,
	      name: this.attendeeNameInput.trim(),
	      role: this.attendeeRoleInput,
	      status: this.attendeeStatusInput,
	      rsvp: this.attendeeRsvpInput
	    })));
	    this.attendeeNameInput = "";
	    this.attendeeEmailInput = "";
	    this.clearFormError();
	  }

	  private mergedAttendeeJson(): string {
	    return this.attendeeJsonInput.trim();
	  }

	  private appointmentStatusValue(value: string | undefined): CalendarAppointmentStatus {
	    if (value === "held" || value === "booked" || value === "cancelled") {
	      return value;
	    }
	    return "available";
	  }

		  private attendeeSummary(): string {
	    const parsed: Object[] = this.parseAttendeeJsonInput(this.attendeeJsonInput);
	    return parsed.length > 0 ? `${parsed.length} 个结构化参会人` : "";
	  }

  private addQuickRoom(): void {
    const value: string = this.quickRoomInput.trim();
    if (value.length === 0) {
      return;
    }

    this.roomIdsJsonInput = this.appendStringJson(this.roomIdsJsonInput, value);
    this.resourceStatusJsonInput = this.appendResourceStatusJson(this.resourceStatusJsonInput, value, "room");
    this.quickRoomInput = "";
    this.clearFormError();
  }

  private addQuickResource(): void {
    const value: string = this.quickResourceInput.trim();
    if (value.length === 0) {
      return;
    }

    this.resourceIdsJsonInput = this.appendStringJson(this.resourceIdsJsonInput, value);
    this.resourceStatusJsonInput = this.appendResourceStatusJson(this.resourceStatusJsonInput, value, "resource");
    this.quickResourceInput = "";
    this.clearFormError();
  }

  private appendStringJson(current: string, value: string): string {
    const items: string[] = this.parseStringArrayJson(current);
    if (items.indexOf(value) < 0) {
      items.push(value);
    }
    return JSON.stringify(items);
  }

  private appendResourceStatusJson(current: string, id: string, type: string): string {
    const items: Object[] = this.parseObjectArrayJson(current).filter((item: Object) => {
      const holder = item as Record<string, string>;
      return (holder["id"] ?? "") !== id;
    });
    items.push(JSON.parse(JSON.stringify({
      id,
      type,
      status: "NEEDS-ACTION",
      role: "REQ-PARTICIPANT",
      rsvp: true
    })));
    return JSON.stringify(items);
  }

	  private appendAttendeeJson(current: string, attendee: Object): string {
	    const attendees: Object[] = this.parseAttendeeJsonInput(current);
	    attendees.push(attendee);
	    return JSON.stringify(attendees);
	  }

	  private parseAttendeeJsonInput(value: string): Object[] {
	    if (value.trim().length === 0) {
	      return [];
	    }

	    try {
	      const parsed: Object = JSON.parse(value);
	      if (Array.isArray(parsed)) {
	        return parsed as Object[];
	      }
	    } catch {
	      return [];
	    }

	    return [];
	  }

	  private appendDateToken(current: string, token: string): string {
	    const value: string = this.normalizedInputList(current);
	    if (value.length === 0) {
	      return token;
	    }

	    const parts: string[] = value.split(",");
	    return parts.indexOf(token) >= 0 ? value : `${value},${token}`;
	  }

	  private withUntil(rrule: string, until: number): string {
	    const untilToken: string = `UNTIL=${toUtcIcsDate(until)}`;
	    const parts: string[] = rrule.split(";").filter((part: string) => part.trim().length > 0 && !part.toUpperCase().startsWith("UNTIL="));
	    parts.push(untilToken);
	    return parts.join(";");
	  }

	  private async deleteEvent(event: CalendarEvent): Promise<void> {
	    const original: CalendarEvent = this.originalEventFor(event);
	    if (this.sourceIsReadOnly(original.sourceId)) {
	      this.syncStatus = "当前日历源为只读，不能删除";
	      return;
	    }
	    await this.requireService().deleteEvent(original);
    if (original.id === this.editingEventId) {
      this.resetEventForm();
    }
	    await this.loadEvents();
	    await this.syncAfterMutation("已标记删除");
	  }

	  private async resolveConflict(event: CalendarEvent, mode: string): Promise<void> {
	    try {
	      if (mode === "remote") {
	        await this.requireService().resolveConflictUseRemote(event);
	        this.syncStatus = "已使用远端版本解决冲突";
	      } else {
	        await this.requireService().resolveConflictUseLocal(event);
	        this.syncStatus = "已保留本地版本，等待上传";
	      }

	      await this.loadEvents();
	      this.resetEventForm();
	      this.appPage = "calendar";
	    } catch (error) {
	      this.syncStatus = this.describeError(error);
	    }
	  }

	  private startEditing(event: CalendarEvent): void {
	    const original: CalendarEvent = this.originalEventFor(event);
	    this.editingEventId = original.id;
	    this.titleInput = original.title;
	    this.editingOccurrenceStartAt = event.startAt;
	    this.recurrenceEditScope = (original.rrule ?? "").trim().length > 0 && event.id !== original.id ? "instance" : "series";
	    this.startInput = formatDateTime(event.startAt);
	    this.endInput = formatDateTime(event.allDay ? event.endAt - DAY_MS : event.endAt);
	    this.allDayInput = original.allDay;
    this.locationInput = original.location;
    this.notesInput = original.notes;
    this.categoryColorInput = this.eventCategoryColor(original);
    this.reminderInput = `${original.reminderMinutes ?? 0}`;
    this.secondReminderInput = `${original.secondReminderMinutes ?? 0}`;
    this.rruleInput = original.rrule ?? "";
    this.eventKindInput = original.eventKind ?? "calendar";
	    this.urlInput = original.url ?? "";
	    this.attendeesInput = original.attendees ?? "";
	    this.attendeeJsonInput = original.attendeeJson ?? "";
	    this.attendeeNameInput = "";
	    this.attendeeEmailInput = "";
	    this.attendeeRoleInput = "REQ-PARTICIPANT";
	    this.attendeeStatusInput = "NEEDS-ACTION";
	    this.attendeeRsvpInput = true;
    this.organizerNameInput = original.organizerName ?? "";
	    this.organizerEmailInput = original.organizerEmail ?? "";
	    this.conferenceUrlInput = original.conferenceUrl ?? "";
	    this.attachmentUrlInput = original.attachmentUrl ?? "";
	    this.attachmentsJsonInput = original.attachmentsJson ?? "";
	    this.travelMinutesInput = `${original.travelMinutes ?? 0}`;
	    this.comingDurationInput = `${original.comingDuration ?? 0}`;
	    this.availabilityInput = original.availability ?? "busy";
	    this.privacyInput = original.privacy ?? "default";
	    this.eventStatusInput = original.eventStatus ?? "confirmed";
	    this.appointmentStatusInput = this.appointmentStatusValue(original.appointmentStatus);
	    this.appointmentCapacityInput = `${original.appointmentCapacity ?? 1}`;
	    this.appointmentBookedCountInput = `${original.appointmentBookedCount ?? 0}`;
	    this.appointmentMinDurationInput = `${original.appointmentMinDurationMinutes ?? 0}`;
	    this.appointmentMaxDurationInput = `${original.appointmentMaxDurationMinutes ?? 0}`;
	    this.appointmentBufferBeforeInput = `${original.appointmentBufferBeforeMinutes ?? 0}`;
	    this.appointmentBufferAfterInput = `${original.appointmentBufferAfterMinutes ?? 0}`;
	    this.appointmentDeadlineInput = `${original.appointmentDeadlineMinutes ?? 0}`;
	    this.appointmentPublicUrlInput = original.appointmentPublicUrl ?? "";
	    this.appointmentFormJsonInput = original.appointmentFormJson ?? "";
	    this.bookingJsonInput = original.bookingJson ?? "";
	    this.bookingContactNameInput = original.bookingContactName ?? "";
	    this.bookingContactEmailInput = original.bookingContactEmail ?? "";
	    this.bookingContactPhoneInput = original.bookingContactPhone ?? "";
	    this.bookingStatusInput = original.bookingStatus ?? "";
	    this.exdateInput = original.exdate ?? "";
    this.rdateInput = original.rdate ?? "";
    this.reminderOffsetsInput = original.reminderOffsets ?? "";
    this.dueInput = (original.dueAt ?? 0) > 0 ? formatDateTime(original.dueAt ?? 0) : "";
    this.completedInput = (original.completedAt ?? 0) > 0 ? formatDateTime(original.completedAt ?? 0) : "";
	    this.priorityInput = `${original.priority ?? 0}`;
	    this.percentCompleteInput = `${original.percentComplete ?? 0}`;
	    this.eventBackgroundColorInput = original.backgroundColor ?? "";
	    this.eventBorderColorInput = original.borderColor ?? "";
	    this.eventTextColorInput = original.textColor ?? "";
	    this.eventDragBackgroundColorInput = original.dragBackgroundColor ?? "";
	    this.milestoneStatusInput = original.milestoneStatus ?? "";
	    this.dueDateClassInput = original.dueDateClass ?? "";
		    this.groupIdInput = original.groupId ?? "";
		    this.displayModeInput = original.displayMode ?? "";
		    this.overlapInput = original.overlap ?? true;
		    this.editableInput = original.editable ?? true;
		    this.startEditableInput = original.startEditable ?? true;
		    this.durationEditableInput = original.durationEditable ?? true;
		    this.resourceEditableInput = original.resourceEditable ?? true;
		    this.interactiveInput = original.interactive ?? true;
		    this.eventReadOnlyInput = original.eventReadOnly ?? false;
		    this.isPendingInput = original.isPending ?? false;
		    this.isFocusedInput = original.isFocused ?? false;
		    this.classNamesInput = original.classNames ?? "";
		    this.customStyleJsonInput = original.customStyleJson ?? "";
		    this.constraintJsonInput = original.constraintJson ?? "";
		    this.extendedPropsJsonInput = original.extendedPropsJson ?? "";
		    this.rawPropsJsonInput = original.rawPropsJson ?? "";
		    this.resourceIdsJsonInput = original.resourceIdsJson ?? "";
	    this.roomIdsJsonInput = original.roomIdsJson ?? "";
	    this.resourceStatusJsonInput = original.resourceStatusJson ?? "";
	    this.quickRoomInput = "";
		    this.quickResourceInput = "";
		    this.alarmActionInput = original.alarmAction ?? "";
		    this.snoozeMinutesInput = `${original.snoozeMinutes ?? 0}`;
		    this.snoozeTimesInput = `${original.snoozeTimes ?? 0}`;
		    this.allDayReminderAtInput = original.allDayReminderAt ?? "";
		    this.alarmActionsJsonInput = original.alarmActionsJson ?? "";
		    this.freeBusyStatus = "";
		    this.freeBusyConflictSummary = "";
		    this.scheduleSuggestionStatus = "";
		    this.scheduleSuggestions = [];
		    this.timeZoneInput = original.timeZone ?? "";
    this.selectedDay = startOfDay(event.startAt);
    this.visibleMonth = startOfDay(event.startAt);
  }

  private cancelEditing(): void {
    if (this.editingEventId.length === 0) {
      return;
    }

    this.resetEventForm();
  }

	  private resetEventForm(): void {
	    this.editingEventId = "";
	    this.editingOccurrenceStartAt = 0;
	    this.recurrenceEditScope = "series";
    this.clearFormError();
    this.titleInput = "";
    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.allDayInput = false;
    this.locationInput = "";
    this.notesInput = "";
    this.categoryColorInput = DEFAULT_CATEGORY_COLOR;
    this.colorPaletteInput = "classic";
	    this.reminderInput = `${this.viewConfig.defaultReminderMinutes ?? 15}`;
    this.secondReminderInput = "0";
    this.rruleInput = "";
    this.eventKindInput = "calendar";
	    this.urlInput = "";
	    this.attendeesInput = "";
	    this.attendeeJsonInput = "";
	    this.attendeeNameInput = "";
	    this.attendeeEmailInput = "";
	    this.attendeeRoleInput = "REQ-PARTICIPANT";
	    this.attendeeStatusInput = "NEEDS-ACTION";
	    this.attendeeRsvpInput = true;
    this.organizerNameInput = "";
	    this.organizerEmailInput = "";
	    this.conferenceUrlInput = "";
	    this.attachmentUrlInput = "";
	    this.attachmentsJsonInput = "";
	    this.travelMinutesInput = "0";
	    this.comingDurationInput = "0";
	    this.availabilityInput = "busy";
	    this.privacyInput = "default";
	    this.eventStatusInput = "confirmed";
	    this.appointmentStatusInput = "available";
	    this.appointmentCapacityInput = "1";
	    this.appointmentBookedCountInput = "0";
	    this.appointmentMinDurationInput = "0";
	    this.appointmentMaxDurationInput = "0";
	    this.appointmentBufferBeforeInput = "0";
	    this.appointmentBufferAfterInput = "0";
	    this.appointmentDeadlineInput = "0";
	    this.appointmentPublicUrlInput = "";
	    this.appointmentFormJsonInput = "";
	    this.bookingJsonInput = "";
	    this.bookingContactNameInput = "";
	    this.bookingContactEmailInput = "";
	    this.bookingContactPhoneInput = "";
	    this.bookingStatusInput = "";
	    this.exdateInput = "";
    this.rdateInput = "";
    this.reminderOffsetsInput = "";
    this.dueInput = "";
    this.completedInput = "";
	    this.priorityInput = "0";
	    this.percentCompleteInput = "0";
		    this.eventBackgroundColorInput = "";
		    this.eventBorderColorInput = "";
		    this.eventTextColorInput = "";
		    this.eventDragBackgroundColorInput = "";
		    this.milestoneStatusInput = "";
		    this.dueDateClassInput = "";
		    this.groupIdInput = "";
		    this.displayModeInput = "";
		    this.overlapInput = true;
		    this.editableInput = true;
		    this.startEditableInput = true;
		    this.durationEditableInput = true;
		    this.resourceEditableInput = true;
		    this.interactiveInput = true;
		    this.eventReadOnlyInput = false;
		    this.isPendingInput = false;
		    this.isFocusedInput = false;
		    this.classNamesInput = "";
		    this.customStyleJsonInput = "";
		    this.constraintJsonInput = "";
		    this.extendedPropsJsonInput = "";
		    this.rawPropsJsonInput = "";
		    this.resourceIdsJsonInput = "";
	    this.roomIdsJsonInput = "";
	    this.resourceStatusJsonInput = "";
	    this.quickRoomInput = "";
		    this.quickResourceInput = "";
		    this.alarmActionInput = "";
		    this.snoozeMinutesInput = "0";
		    this.snoozeTimesInput = "0";
		    this.allDayReminderAtInput = "";
		    this.alarmActionsJsonInput = "";
		    this.freeBusyStatus = "";
		    this.freeBusyConflictSummary = "";
		    this.scheduleSuggestionStatus = "";
		    this.scheduleSuggestions = [];
		    this.timeZoneInput = this.currentTimeZoneValue();
  }

  private openNewEvent(): void {
    this.resetEventForm();
    this.clearFormError();
    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.appPage = "editor";
  }

  private selectCalendarDay(day: number, nextView?: string): void {
    this.selectedDay = startOfDay(day);
    this.visibleMonth = this.monthStart(day);
    if (nextView !== undefined && nextView.length > 0) {
      this.scheduleView = nextView;
    }
    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.cancelEditing();
  }

  private closeEditor(): void {
    this.clearFormError();
    this.cancelEditing();
    this.appPage = "calendar";
  }

  private async goToday(): Promise<void> {
    const today: number = startOfDay(Date.now());
    this.selectedDay = today;
    this.visibleMonth = today;
    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.cancelEditing();
    await this.loadDateMarkers();
  }

  private async moveVisibleRange(direction: number): Promise<void> {
	    if (this.scheduleView === "day") {
	      this.selectedDay = this.selectedDay + direction * DAY_MS;
	      this.visibleMonth = this.monthStart(this.selectedDay);
	    } else if (this.scheduleView === "3days") {
	      this.selectedDay = this.selectedDay + direction * 3 * DAY_MS;
	      this.visibleMonth = this.monthStart(this.selectedDay);
	    } else if (this.scheduleView === "workweek") {
	      this.selectedDay = this.selectedDay + direction * 7 * DAY_MS;
	      this.visibleMonth = this.monthStart(this.selectedDay);
	    } else if (this.scheduleView === "week") {
	      this.selectedDay = this.selectedDay + direction * 7 * DAY_MS;
	      this.visibleMonth = this.monthStart(this.selectedDay);
    } else if (this.scheduleView === "year") {
      const date = new Date(this.visibleMonth);
      this.visibleMonth = startOfDay(new Date(date.getFullYear() + direction, 0, 1).getTime());
      this.selectedDay = this.visibleMonth;
    } else {
      this.visibleMonth = addMonths(this.visibleMonth, direction);
      this.selectedDay = this.visibleMonth;
    }

    this.startInput = this.defaultStartText();
    this.endInput = this.defaultEndText();
    this.cancelEditing();
    await this.loadDateMarkers();
  }

	  private visibleEvents(): CalendarEvent[] {
    let scoped: CalendarEvent[] = this.eventsForListWindow();
    if (this.scheduleView === "day") {
      scoped = this.eventsForSelectedDay();
	    } else if (this.isTimeGridView()) {
	      scoped = this.eventsForSelectedRange();
	    } else if (this.scheduleView === "month") {
	      scoped = this.eventsForSelectedDay();
    } else if (this.scheduleView === "year") {
      scoped = this.eventsForVisibleMonth();
    }

	    return this.sortConfiguredEvents(scoped
	      .filter((event: CalendarEvent) => this.matchesConfiguredFilters(event))
	      .filter((event: CalendarEvent) => this.matchesSearch(event)));
	  }

  private eventsForSelectedDay(): CalendarEvent[] {
    const dayStart: number = startOfDay(this.selectedDay);
    return this.expandedEventsInRange(dayStart, dayStart + DAY_MS);
  }

  private eventsForSelectedWeek(): CalendarEvent[] {
	    const weekStart: number = this.weekStart(this.selectedDay);
	    const weekEnd: number = weekStart + 7 * DAY_MS;
	    return this.expandedEventsInRange(weekStart, weekEnd);
	  }

  private eventsForSelectedRange(): CalendarEvent[] {
	    const days: number[] = this.rangeDaysForSelectedView();
	    if (days.length === 0) {
	      return [];
	    }

	    const rangeStart: number = startOfDay(days[0]);
	    const rangeEnd: number = startOfDay(days[days.length - 1]) + DAY_MS;
	    return this.expandedEventsInRange(rangeStart, rangeEnd);
	  }

  private eventsForVisibleMonth(): CalendarEvent[] {
    const monthStart: number = this.monthStart(this.visibleMonth);
    const monthEnd: number = addMonths(monthStart, 1);
    return this.expandedEventsInRange(monthStart, monthEnd);
  }

	  private eventCountForVisibleMonth(): number {
	    return this.eventsForVisibleMonth()
	      .filter((event: CalendarEvent) => this.matchesConfiguredFilters(event))
	      .filter((event: CalendarEvent) => this.matchesSearch(event))
	      .length;
	  }

  private eventCountForDay(day: number): number {
    return this.eventsForDay(day).length;
  }

  private eventsForDay(day: number): CalendarEvent[] {
	    const dayStart: number = startOfDay(day);
	    return this.sortConfiguredEvents(this.expandedEventsInRange(dayStart, dayStart + DAY_MS)
	      .filter((event: CalendarEvent) => this.eventTouchesDay(event, day) && this.matchesConfiguredFilters(event) && this.matchesSearch(event)));
	  }

  private sortConfiguredEvents(events: CalendarEvent[]): CalendarEvent[] {
    const eventOrder: string = this.viewConfig.eventOrder ?? "start,title";
    return events.sort((left: CalendarEvent, right: CalendarEvent) => {
      if (eventOrder === "title,start") {
        const byTitle: number = left.title.localeCompare(right.title);
        if (byTitle !== 0) {
          return byTitle;
        }
      }

      if (left.startAt !== right.startAt) {
        return left.startAt - right.startAt;
      }

      return left.title.localeCompare(right.title);
    });
  }

  private eventTouchesDay(event: CalendarEvent, day: number): boolean {
    const dayStart: number = startOfDay(day);
    const dayEnd: number = dayStart + DAY_MS;
    return event.startAt < dayEnd && event.endAt > dayStart;
  }

  private scheduleSubtitle(): string {
    if (this.scheduleView === "day") {
      return `${this.formatFullDate(this.selectedDay)} · ${this.visibleEvents().length} 项`;
    }

	    if (this.isTimeGridView()) {
	      const days: number[] = this.rangeDaysForSelectedView();
	      const first: number = days[0];
	      const last: number = days[days.length - 1];
	      return `${this.formatShortDate(first)} 至 ${this.formatShortDate(last)} · ${this.visibleEvents().length} 项`;
	    }

    if (this.scheduleView === "month") {
      return `${formatMonthTitle(this.visibleMonth)} · ${this.visibleEvents().length} 项`;
    }

    if (this.scheduleView === "year") {
      return `${new Date(this.visibleMonth).getFullYear()} 年当前月份 · ${this.visibleEvents().length} 项`;
    }

    return `全部本地日程 · ${this.visibleEvents().length} 项`;
  }

  private scheduleTitle(): string {
    if (this.scheduleView === "day") {
      return sameDay(this.selectedDay, Date.now()) ? "今日议程" : `${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日议程`;
    }

	    if (this.scheduleView === "week") {
	      return "本周日程";
	    }

	    if (this.scheduleView === "3days") {
	      return "未来 3 日";
	    }

	    if (this.scheduleView === "workweek") {
	      return "工作周";
	    }

    if (this.scheduleView === "month") {
      return `${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日安排`;
    }

    if (this.scheduleView === "year") {
      return "所选月份日程";
    }

    return "全部日程";
  }

  private homeScheduleTitle(): string {
    if (sameDay(this.selectedDay, Date.now())) {
      return "今日日程";
    }

    return `${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日`;
  }

  private agendaEmptyText(): string {
    const text: string = (this.viewConfig.agendaEmptyText ?? "").trim();
    return text.length > 0 ? text : "当前日期没有日程";
  }

  private headerTitle(): string {
    if (this.scheduleView === "year") {
      return `${new Date(this.visibleMonth).getFullYear()}年`;
    }

	    if (this.scheduleView === "day") {
	      return this.formatFullDate(this.selectedDay);
	    }

	    if (this.isTimeGridView()) {
	      const days: number[] = this.rangeDaysForSelectedView();
	      return `${this.formatShortDate(days[0])} - ${this.formatShortDate(days[days.length - 1])}`;
	    }

	    return formatMonthTitle(this.visibleMonth);
	  }

  private yearMonths(): number[] {
    const year: number = new Date(this.visibleMonth).getFullYear();
    const months: number[] = [];
    for (let month = 0; month < 12; month += 1) {
      months.push(startOfDay(new Date(year, month, 1).getTime()));
    }

    return months;
  }

  private compactMonthDays(month: number): number[] {
    const days: number[] = monthGridDays(month);
    return days.slice(0, 35);
  }

  private sameMonth(left: number, right: number): boolean {
    const leftDate = new Date(left);
    const rightDate = new Date(right);
    return leftDate.getFullYear() === rightDate.getFullYear() && leftDate.getMonth() === rightDate.getMonth();
  }

  private compactDayColor(day: number, month: number): string {
    if (!this.sameMonth(day, month)) {
      return "#CBD5E1";
    }

    if (this.eventCountForDay(day) > 0) {
      return PRIMARY_COLOR;
    }

    const marker: CalendarDateMarker | null = this.primaryDateMarker(day);
    if (marker !== null) {
      return this.normalizedCategoryColor(marker.color ?? marker.periodColor ?? PRIMARY_COLOR);
    }

    return TEXT_PRIMARY;
  }

  private hasEventsForMiniMonthDay(day: number, month: number): boolean {
    return this.sameMonth(day, month) && this.hasEventsForDay(day);
  }

  private miniMonthDotColor(day: number, month: number): string {
    if (!this.sameMonth(day, month)) {
      return "#CBD5E1";
    }

    const colors: string[] = this.dayEventColors(day);
    if (colors.length > 0) {
      return colors[0];
    }

    const marker: CalendarDateMarker | null = this.primaryDateMarker(day);
    if (marker !== null) {
      return this.normalizedCategoryColor(marker.color ?? marker.periodColor ?? PRIMARY_COLOR);
    }

    return "#00000000";
  }

  private weekEventHeight(event: CalendarEvent): number {
	    const durationMinutes: number = Math.max(30, Math.floor((event.endAt - event.startAt) / (60 * 1000)));
	    const height: number = Math.floor(durationMinutes / 3);
    if (height < 34) {
      return 34;
    }

    if (height > 96) {
      return 96;
    }

	    return height;
	  }

  private isTimeGridView(): boolean {
	    return this.scheduleView === "week" || this.scheduleView === "3days" || this.scheduleView === "workweek";
	  }

  private timeGridHourLabels(): string[] {
	    const labels: string[] = [];
	    for (let hour = this.timeGridStartHour(); hour <= this.timeGridEndHour(); hour += 1) {
	      labels.push(hour < 10 ? `0${hour}` : `${hour}`);
	    }

	    return labels;
	  }

  private timeGridTotalHeight(): number {
	    return TIME_GRID_HEADER_HEIGHT + (this.timeGridEndHour() - this.timeGridStartHour() + 1) * TIME_GRID_HOUR_HEIGHT;
	  }

  private hourIndex(hour: string): number {
	    const parsed: number = Number.parseInt(hour, 10);
	    if (Number.isNaN(parsed)) {
	      return 0;
	    }

	    return Math.max(0, parsed - this.timeGridStartHour());
	  }

  private dayHourLabel(hour: string): string {
    const parsed: number = Number.parseInt(hour, 10);
    if (Number.isNaN(parsed)) {
      return hour;
    }
    if (parsed === 12) {
      return "12";
    }
    if (parsed > 12) {
      return `${parsed - 12}`;
    }

    return `${parsed}`;
  }

  private nowTimeLabel(): string {
    return formatTime(Date.now());
  }

  private dayNowIndicatorTop(): number {
    return Math.max(0, this.nowIndicatorTop(this.selectedDay) - TIME_GRID_HEADER_HEIGHT);
  }

  private timeGridDayStart(day: number): number {
	    return startOfDay(day) + this.timeGridStartHour() * 60 * 60 * 1000;
	  }

  private timeGridDayEnd(day: number): number {
	    return startOfDay(day) + (this.timeGridEndHour() + 1) * 60 * 60 * 1000;
	  }

  private eventLayoutsForDay(day: number): TimeGridEventLayout[] {
	    const dayStart: number = this.timeGridDayStart(day);
	    const dayEnd: number = this.timeGridDayEnd(day);
	    const timedEvents: CalendarEvent[] = this.eventsForDay(day)
	      .filter((event: CalendarEvent) => !event.allDay && event.startAt < dayEnd && event.endAt > dayStart)
	      .sort((left: CalendarEvent, right: CalendarEvent) => {
	        if (left.startAt !== right.startAt) {
	          return left.startAt - right.startAt;
	        }

	        return right.endAt - left.endAt;
	      });
	    const layouts: TimeGridEventLayout[] = [];
	    let group: CalendarEvent[] = [];
	    let groupEnd: number = 0;

	    timedEvents.forEach((event: CalendarEvent) => {
	      if (group.length > 0 && event.startAt >= groupEnd) {
	        this.appendLayoutGroup(layouts, group, dayStart, dayEnd);
	        group = [];
	        groupEnd = 0;
	      }

	      group.push(event);
	      groupEnd = Math.max(groupEnd, event.endAt);
	    });

	    if (group.length > 0) {
	      this.appendLayoutGroup(layouts, group, dayStart, dayEnd);
	    }

	    return layouts;
	  }

  private allDayEventsForDay(day: number): CalendarEvent[] {
    return this.eventsForDay(day).filter((event: CalendarEvent) => event.allDay);
  }

  private allDaySummary(day: number): string {
    const events: CalendarEvent[] = this.allDayEventsForDay(day);
    if (events.length === 0) {
      return "";
    }

    const first: CalendarEvent = events[0];
    return events.length === 1 ? first.title : `${first.title} +${events.length - 1}`;
  }

  private appendLayoutGroup(layouts: TimeGridEventLayout[], group: CalendarEvent[], dayStart: number, dayEnd: number): void {
    const columnEnds: number[] = [];
    const groupColumns: number[] = [];
    group.forEach((event: CalendarEvent) => {
      let column: number = -1;
      for (let index = 0; index < columnEnds.length; index += 1) {
        if (event.startAt >= columnEnds[index]) {
          column = index;
          break;
        }
      }

      if (column < 0) {
        column = columnEnds.length;
        columnEnds.push(0);
      }

      columnEnds[column] = Math.max(event.endAt, dayStart);
      groupColumns.push(column);
    });

    const columnCount: number = Math.max(1, columnEnds.length);
    group.forEach((event: CalendarEvent, index: number) => {
      const clippedStart: number = Math.max(dayStart, event.startAt);
      const clippedEnd: number = Math.min(dayEnd, event.endAt);
      const minutesFromGridStart: number = Math.floor((clippedStart - dayStart) / (60 * 1000));
      const durationMinutes: number = Math.max(15, Math.floor((clippedEnd - clippedStart) / (60 * 1000)));
      layouts.push({
        event,
        top: TIME_GRID_HEADER_HEIGHT + Math.floor(minutesFromGridStart * TIME_GRID_HOUR_HEIGHT / 60),
        height: Math.max(TIME_GRID_MIN_EVENT_HEIGHT, Math.floor(durationMinutes * TIME_GRID_HOUR_HEIGHT / 60) - 2),
        column: groupColumns[index],
        columnCount
      });
    });
  }

  private nowIndicatorVisibleForDay(day: number): boolean {
    return this.viewConfig.nowIndicatorVisible !== false && sameDay(day, Date.now()) &&
      Date.now() >= this.timeGridDayStart(day) && Date.now() <= this.timeGridDayEnd(day);
  }

  private nowIndicatorTop(day: number): number {
    const elapsedMinutes: number = Math.max(0, Math.min(
      (this.timeGridEndHour() - this.timeGridStartHour() + 1) * 60,
      Math.floor((Date.now() - this.timeGridDayStart(day)) / 60000)
    ));
    return TIME_GRID_HEADER_HEIGHT + elapsedMinutes * TIME_GRID_HOUR_HEIGHT / 60;
  }

  private dayTextColor(day: number): string {
    const current = new Date(day);
    const visible = new Date(this.visibleMonth);
    if (current.getMonth() !== visible.getMonth()) {
      return "#9CA3AF";
    }

    if (sameDay(day, Date.now())) {
      return TODAY_COLOR;
    }

    return "#111827";
  }

  private dayCellBackground(day: number): string {
    if (sameDay(day, this.selectedDay)) {
      return PRIMARY_SOFT_COLOR;
    }

    const marker: CalendarDateMarker | null = this.primaryDateMarker(day);
    if (marker !== null && marker.markingType.indexOf("period") >= 0) {
      return marker.periodColor !== undefined && marker.periodColor.length > 0 ? this.softColor(marker.periodColor) : PRIMARY_SOFT_COLOR;
    }

    if (sameDay(day, Date.now())) {
      return TODAY_SOFT_COLOR;
    }

    return SURFACE_COLOR;
  }

  private dayCellBorderWidth(day: number): number {
    if (sameDay(day, this.selectedDay)) {
      return 1.5;
    }

    if (this.eventCountForDay(day) > 0 || this.markersForDay(day).length > 0) {
      return 0.5;
    }

    return 0;
  }

  private dayCellBorderColor(day: number): string {
    if (sameDay(day, this.selectedDay)) {
      return PRIMARY_COLOR;
    }

    if (this.eventCountForDay(day) > 0 || this.markersForDay(day).length > 0) {
      return BORDER_COLOR;
    }

    return "#00000000";
  }

  private hasEventsForDay(day: number): boolean {
    return this.eventCountForDay(day) > 0;
  }

  private monthCellBackground(day: number): string {
    if (sameDay(day, this.selectedDay)) {
      return PRIMARY_COLOR;
    }

    if (sameDay(day, Date.now())) {
      return PRIMARY_SOFT_COLOR;
    }

    return "#FBFCFD";
  }

  private monthCellBorderColor(day: number): string {
    if (sameDay(day, this.selectedDay)) {
      return PRIMARY_COLOR;
    }

    if (sameDay(day, Date.now())) {
      return PRIMARY_COLOR;
    }

    return "#EDF2F7";
  }

  private eventMeta(event: CalendarEvent): string {
    const status: string = this.syncStatusLabel(event);
    const dateLabel: string = this.formatShortDate(event.startAt);
    const extras: string = this.eventExtraMeta(event);
    if (event.allDay) {
      return `${dateLabel} · 全天 · ${status}${extras}`;
    }

    return `${dateLabel} ${formatTime(event.startAt)}-${formatTime(event.endAt)} · ${status}${extras}`;
  }

  private eventTimeChip(event: CalendarEvent): string {
    if (event.allDay) {
      return "全天";
    }

    return formatTime(event.startAt);
  }

  private eventChipBackground(event: CalendarEvent): string {
    if (event.isPending === true) {
      return WARNING_SOFT_COLOR;
    }

    if (event.isFocused === true) {
      return PRIMARY_SOFT_COLOR;
    }

    const color: string = this.eventCategoryColor(event);
    if (color === "#FF3B30" || color === TODAY_COLOR || color === DANGER_COLOR) {
      return DANGER_SOFT_COLOR;
    }

    if (color === "#34C759" || color === "#14B8A6") {
      return SUCCESS_SOFT_COLOR;
    }

    if (color === "#FF9500" || color === "#F59E0B" || color === "#D97706") {
      return WARNING_SOFT_COLOR;
    }

    return PRIMARY_SOFT_COLOR;
  }

  private monthCellButtonText(day: number): string {
    return `${new Date(day).getDate()}`;
  }

  private dayEventColors(day: number): string[] {
    const colors: string[] = [];
    const dayEvents: CalendarEvent[] = this.eventsForDay(day);
    const maxDots: number = Math.min(dayEvents.length, this.maxVisibleEventsPerDay());
    for (let index = 0; index < maxDots; index += 1) {
      const color: string = this.eventCategoryColor(dayEvents[index]);
      if (colors.indexOf(color) < 0 || colors.length === 0) {
        colors.push(color);
      }
      if (colors.length >= this.maxVisibleEventsPerDay()) {
        break;
      }
    }

    if (colors.length === 0) {
      this.markersForDay(day).forEach((marker: CalendarDateMarker) => {
        if (colors.length < this.maxVisibleEventsPerDay()) {
          colors.push(this.normalizedCategoryColor(marker.color ?? marker.periodColor ?? PRIMARY_COLOR));
        }
      });
    }

    return colors;
  }

  private monthMoreLabel(count: number): string {
    const label: string = this.viewConfig.monthMoreLabel ?? "更多";
    return label === "+N" ? `+${count}` : `+${count} ${label}`;
  }

  private timeGridStartHour(): number {
    return Math.min(23, Math.max(0, Math.floor(this.viewConfig.minHour)));
  }

  private timeGridEndHour(): number {
    return Math.min(23, Math.max(this.timeGridStartHour(), Math.floor(this.viewConfig.maxHour)));
  }

  private maxVisibleEventsPerDay(): number {
    return Math.max(1, Math.floor(this.viewConfig.maxVisibleEventsPerDay));
  }

  private markersForDay(day: number): CalendarDateMarker[] {
    return this.dateMarkers.filter((marker: CalendarDateMarker) =>
      sameDay(marker.markerDate, day) ||
        ((marker.periodStart ?? 0) > 0 && (marker.periodEnd ?? 0) > 0 && day >= startOfDay(marker.periodStart ?? 0) && day <= startOfDay(marker.periodEnd ?? 0)));
  }

  private primaryDateMarker(day: number): CalendarDateMarker | null {
    const markers: CalendarDateMarker[] = this.markersForDay(day);
    return markers.length > 0 ? markers[0] : null;
  }

  private softColor(color: string): string {
    const normalized: string = this.normalizedCategoryColor(color);
    if (normalized === DANGER_COLOR || normalized === "#FF3B30") {
      return DANGER_SOFT_COLOR;
    }
    if (normalized === WARNING_COLOR || normalized === "#FF9500") {
      return WARNING_SOFT_COLOR;
    }
    if (normalized === BLUE_COLOR || normalized === "#2F6FDB") {
      return BLUE_SOFT_COLOR;
    }
    return PRIMARY_SOFT_COLOR;
  }

  private defaultStartText(): string {
    return formatDateTime(this.defaultStartAt());
  }

  private defaultEndText(): string {
    return formatDateTime(this.defaultStartAt() + 60 * 60 * 1000);
  }

  private defaultStartAt(): number {
    const now: Date = new Date();
    const roundedMinute: number = Math.ceil(now.getMinutes() / 15) * 15;
    const hour: number = roundedMinute >= 60 ? Math.min(23, now.getHours() + 1) : now.getHours();
    const minute: number = roundedMinute >= 60 ? 0 : roundedMinute;
    const selected: Date = new Date(this.selectedDay);
    const date: Date = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate(), hour, minute, 0, 0);
    return date.getTime();
  }

  private pickDateTime(target: string): void {
    const currentValue: string = target === "start" ? this.startInput : this.endInput;
    const currentTime: number = this.parseInputDate(currentValue);
    const initialDate: Date = new Date(currentTime > 0 ? currentTime : Date.now());

    DatePickerDialog.show({
      start: new Date(2000, 0, 1),
      end: new Date(2100, 11, 31),
      selected: initialDate,
      onAccept: (dateValue: DatePickerResult) => {
        const pickedDate: Date = new Date(
          dateValue.year,
          dateValue.month,
          dateValue.day,
          initialDate.getHours(),
          initialDate.getMinutes()
        );
        this.pickTimeForDate(target, pickedDate);
      }
    });
  }

  private pickTimeForDate(target: string, pickedDate: Date): void {
    TimePickerDialog.show({
      selected: pickedDate,
      useMilitaryTime: true,
      onAccept: (timeValue: TimePickerResult) => {
        const nextDate: Date = new Date(
          pickedDate.getFullYear(),
          pickedDate.getMonth(),
          pickedDate.getDate(),
          timeValue.hour,
          timeValue.minute
        );
        this.setDateTimeInput(target, nextDate.getTime());
      }
    });
  }

  private setDateTimeInput(target: string, timestamp: number): void {
    if (target === "start") {
      this.startInput = formatDateTime(timestamp);
      const endAt: number = this.parseInputDate(this.endInput);
      if (endAt <= timestamp) {
        this.endInput = formatDateTime(timestamp + 60 * 60 * 1000);
      }
    } else {
      this.endInput = formatDateTime(timestamp);
    }

    this.clearFormError();
  }

  private parseInputDate(value: string): number {
    const normalized: string = value.trim().replace("T", " ");
    const match: RegExpMatchArray | null = normalized.match(/^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2})$/);
    if (match === null) {
      return 0;
    }

    return new Date(
      Number(match[1]),
      Number(match[2]) - 1,
      Number(match[3]),
      Number(match[4]),
      Number(match[5])
    ).getTime();
  }

  private parseOptionalMinutes(value: string): number {
    const trimmed: string = value.trim();
    if (trimmed.length === 0) {
      return 0;
    }

    const parsed: number = Number(trimmed);
    if (!Number.isInteger(parsed)) {
      return -1;
    }

    return parsed;
  }

  private normalizedInputList(value: string): string {
    const parts: string[] = [];
    value.split(/[,\n;]/).forEach((item: string) => {
      const trimmed: string = item.trim();
      if (trimmed.length > 0 && parts.indexOf(trimmed) < 0) {
        parts.push(trimmed);
      }
    });
    return parts.join(", ");
  }

	  private selectEventKind(value: CalendarEventKind): void {
	    this.eventKindInput = value;
    if (value === "important") {
      this.allDayInput = true;
      if (this.reminderInput === "0") {
        this.reminderInput = "1440";
      }
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#FF9500";
      }
    } else if (value === "reminder") {
      this.allDayInput = false;
      if (this.reminderInput === "0") {
        this.reminderInput = "10";
      }
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#34C759";
      }
    } else if (value === "task") {
      this.allDayInput = false;
      this.availabilityInput = "free";
      if (this.reminderInput === "0") {
        this.reminderInput = "30";
      }
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#14B8A6";
      }
    } else if (value === "focus") {
      this.availabilityInput = "busy";
      this.privacyInput = "private";
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#5856D6";
      }
    } else if (value === "outOfOffice") {
      this.availabilityInput = "busy";
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#FF3B30";
      }
    } else if (value === "workingLocation") {
      this.availabilityInput = "free";
      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
        this.categoryColorInput = "#64748B";
      }
	    } else if (value === "appointment") {
	      this.availabilityInput = "busy";
	      this.appointmentStatusInput = "available";
	      if (this.appointmentCapacityInput === "0") {
	        this.appointmentCapacityInput = "1";
	      }
	      if (this.categoryColorInput === DEFAULT_CATEGORY_COLOR) {
	        this.categoryColorInput = "#AF52DE";
	      }
    }
    const source: CalendarSource | null = this.defaultWritableSourceForKind(value);
    if (source === null || !this.sourceCanWrite(source) || !this.sourceSupportsEventKind(source, value)) {
      this.syncStatus = value === "task" ? "当前没有支持 VTODO 任务的可写日历源" : "当前没有支持 VEVENT 事件的可写日历源";
    } else {
      this.selectedSourceIdInput = source.id ?? "";
      this.syncStatus = `当前默认写入：${source.name}`;
    }
  }

  private activeColorPalette(): string[] {
    if (this.colorPaletteInput === "soft") {
      return COLOR_PALETTE_SOFT;
    }

    if (this.colorPaletteInput === "focus") {
      return COLOR_PALETTE_FOCUS;
    }

    return COLOR_PALETTE_CLASSIC;
  }

  private async openLocationInMap(): Promise<void> {
    const keyword: string = this.locationInput.trim();
    const uri: string = keyword.length > 0 ? `geo:0,0?q=${encodeURIComponent(keyword)}` : "geo:0,0?q=";
    try {
      const context = getContext(this) as common.UIAbilityContext;
      await context.startAbility({
        action: "ohos.want.action.viewData",
        uri
      });
    } catch (error) {
      this.formError = `无法打开地图：${this.describeError(error)}`;
    }
  }

  private requireService(): CalendarSyncService {
    if (this.syncService === null) {
      throw new Error("同步服务未初始化");
    }

    return this.syncService;
  }

  private autoSyncOptions(): SelectOption[] {
    return [
      { value: "30 秒" },
      { value: "1 分钟" },
      { value: "5 分钟" },
      { value: "10 分钟" },
      { value: "30 分钟" },
      { value: "1 小时" }
    ];
  }

  private autoSyncIntervalLabel(): string {
    const labels: string[] = ["30 秒", "1 分钟", "5 分钟", "10 分钟", "30 分钟", "1 小时"];
    if (this.autoSyncIntervalIndex < 0 || this.autoSyncIntervalIndex >= labels.length) {
      return "5 分钟";
    }

    return labels[this.autoSyncIntervalIndex];
  }

  private autoSyncIntervalMs(): number {
    const values: number[] = [
      30 * 1000,
      60 * 1000,
      5 * 60 * 1000,
      10 * 60 * 1000,
      30 * 60 * 1000,
      60 * 60 * 1000
    ];
    if (this.autoSyncIntervalIndex < 0 || this.autoSyncIntervalIndex >= values.length) {
      return 5 * 60 * 1000;
    }

    return values[this.autoSyncIntervalIndex];
  }

  private clearAutoSyncTimer(): void {
    if (this.autoSyncTimerId >= 0) {
      clearInterval(this.autoSyncTimerId);
      this.autoSyncTimerId = -1;
    }
  }

  private resetAutoSyncTimer(): void {
    this.clearAutoSyncTimer();
    this.autoSyncTimerId = setInterval(async () => {
      if (this.accounts.length > 0) {
        await this.syncNow();
      }
    }, this.autoSyncIntervalMs());
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

  private pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private editingEvent(): CalendarEvent | null {
    const found: CalendarEvent[] = this.events.filter((event: CalendarEvent) => event.id === this.editingEventId);
    return found.length > 0 ? found[0] : null;
  }

  private monthStart(value: number): number {
    const date = new Date(value);
    return startOfDay(new Date(date.getFullYear(), date.getMonth(), 1).getTime());
  }

	  private matchesSearch(event: CalendarEvent): boolean {
    const keyword: string = this.searchKeyword.trim().toLowerCase();
    if (keyword.length === 0) {
      return true;
    }

    return event.title.toLowerCase().includes(keyword) ||
      event.location.toLowerCase().includes(keyword) ||
      event.notes.toLowerCase().includes(keyword) ||
      (event.attendees ?? "").toLowerCase().includes(keyword) ||
	      (event.url ?? "").toLowerCase().includes(keyword) ||
	      (event.conferenceUrl ?? "").toLowerCase().includes(keyword);
	  }

	  private matchesConfiguredFilters(event: CalendarEvent): boolean {
	    if (event.isVisible === false) {
	      return false;
	    }

	    const sourceFilter: string[] = this.activeSourceFilterIds();
	    if (sourceFilter.length > 0 && sourceFilter.indexOf(event.sourceId) < 0) {
	      return false;
	    }

	    const kindFilter: string = this.viewConfig.eventKindFilter ?? "all";
	    if (kindFilter !== "all" && (event.eventKind ?? "calendar") !== kindFilter) {
	      return false;
	    }

	    if (this.viewConfig.hideCancelledEvents === true && (event.eventStatus ?? "confirmed") === "cancelled") {
	      return false;
	    }

	    if (this.viewConfig.showIncompleteTasksOnly === true &&
	      (event.eventKind ?? "calendar") === "task" &&
	      (event.percentComplete ?? 0) >= 100) {
	      return false;
	    }

	    return true;
	  }

	  private weekStart(day: number): number {
    const date = new Date(startOfDay(day));
    const offset: number = (date.getDay() + 6) % 7;
    return startOfDay(day) - offset * DAY_MS;
  }

  private formatShortDate(value: number): string {
    const date = new Date(value);
    return `${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())}`;
  }

  private formatFullDate(value: number): string {
    const date = new Date(value);
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())}`;
  }

  private pendingUploadCount(): number {
    return this.events.filter((event: CalendarEvent) => event.syncStatus === "dirty").length;
  }

  private syncedCount(): number {
    return this.events.filter((event: CalendarEvent) => event.syncStatus === "clean").length;
  }

  private localSyncSummary(): string {
    const pending: number = this.pendingUploadCount();
    if (pending > 0) {
      return `本地待同步 ${pending} 项，已同步 ${this.syncedCount()} 项`;
    }

    return `本地无待同步，已同步 ${this.syncedCount()} 项`;
  }

  private isTodaySelected(): boolean {
    return sameDay(this.selectedDay, Date.now());
  }

  private selectedDayOverview(): string {
    const dayEvents: CalendarEvent[] = this.eventsForDay(this.selectedDay);
    if (dayEvents.length === 0) {
      return "所选日期暂无日程";
    }

    if (dayEvents.length === 1) {
      return dayEvents[0].title;
    }

    return `${dayEvents[0].title} +${dayEvents.length - 1} 项`;
  }

  private dayLabelBadge(): string {
    if (this.isTodaySelected()) {
      return "今天";
    }

    return `${this.eventCountForDay(this.selectedDay)} 项`;
  }

  private shouldShowHeaderStatus(): boolean {
    if (this.syncStatus === "未同步" || this.syncStatus === "CalDAV 连接成功" || this.syncStatus === "CalDAV 已保存" ||
      this.syncStatus === "CalDAV 已切换") {
      return false;
    }

    return this.isSyncing || this.syncStatus.indexOf("失败") >= 0 || this.syncStatus.indexOf("请") >= 0 ||
      this.syncStatus.indexOf("错误") >= 0 || this.syncStatus.indexOf("无法") >= 0;
  }

  private compactSyncStatus(): string {
    if (this.isSyncing) {
      return "同步中";
    }

    return this.syncStatus;
  }

  private compactSyncStatusColor(): string {
    if (this.syncStatus.indexOf("失败") >= 0 || this.syncStatus.indexOf("错误") >= 0 ||
      this.syncStatus.indexOf("无法") >= 0) {
      return DANGER_COLOR;
    }

    return TEXT_SECONDARY;
  }

  private accountFormStatusColor(): string {
    if (this.isPositiveAccountFormStatus()) {
      return SUCCESS_COLOR;
    }

    if (this.isNeutralAccountFormStatus()) {
      return PRIMARY_COLOR;
    }

    return DANGER_COLOR;
  }

  private accountFormStatusBackground(): string {
    if (this.isPositiveAccountFormStatus()) {
      return SUCCESS_SOFT_COLOR;
    }

    if (this.isNeutralAccountFormStatus()) {
      return PRIMARY_SOFT_COLOR;
    }

    return DANGER_SOFT_COLOR;
  }

  private isPositiveAccountFormStatus(): boolean {
    return this.accountFormStatus.indexOf("成功") >= 0 || this.accountFormStatus.indexOf("已保存") >= 0;
  }

  private isNeutralAccountFormStatus(): boolean {
    return this.accountFormStatus.indexOf("正在") >= 0 || this.accountFormStatus.indexOf("已应用") >= 0 ||
      this.accountFormStatus.indexOf("通常填写") >= 0;
  }

  private clearFormError(): void {
    this.formError = "";
  }

	  private syncStatusLabel(event: CalendarEvent): string {
	    if ((event.conflictStatus ?? "none") !== "none") {
	      return "同步冲突";
	    }

	    if (event.syncStatus === "dirty") {
	      return "本地待上传";
    }

    if (event.syncStatus === "deleted") {
      return "待删除";
    }

    return "已同步";
  }

  private eventExtraMeta(event: CalendarEvent): string {
    const parts: string[] = [];
    parts.push(this.eventKindLabel(event.eventKind ?? "calendar"));
    if ((event.reminderMinutes ?? 0) > 0) {
      parts.push(`提醒 ${event.reminderMinutes} 分钟`);
    }
    if ((event.secondReminderMinutes ?? 0) > 0) {
      parts.push(`二次提醒 ${event.secondReminderMinutes} 分钟`);
    }
    if ((event.reminderOffsets ?? "").length > 0) {
      parts.push(`多提醒 ${event.reminderOffsets}`);
    }
    if ((event.attendees ?? "").length > 0) {
      parts.push("有参会人");
    }
    if ((event.organizerEmail ?? "").length > 0) {
      parts.push("有组织者");
    }
    if ((event.conferenceUrl ?? "").length > 0) {
      parts.push("视频会议");
    }
    if ((event.travelMinutes ?? 0) > 0) {
      parts.push(`旅行 ${event.travelMinutes} 分钟`);
    }
    if ((event.comingDuration ?? 0) > 0) {
      parts.push(`返回 ${event.comingDuration} 分钟`);
    }
    if ((event.roomIdsJson ?? "").length > 0) {
      parts.push("有会议室");
    }
    if ((event.resourceIdsJson ?? "").length > 0) {
      parts.push("有资源");
    }
    if ((event.extendedPropsJson ?? "").length > 0) {
      parts.push("有扩展字段");
    }
    if (event.overlap === false) {
      parts.push("禁止重叠");
    }
    if ((event.availability ?? "busy") === "free") {
      parts.push("空闲");
    }
    if ((event.privacy ?? "default") !== "default") {
      parts.push(this.privacyLabel(event.privacy ?? "default"));
    }
    if ((event.eventStatus ?? "confirmed") !== "confirmed") {
      parts.push(this.eventStatusLabel(event.eventStatus ?? "confirmed"));
    }
    if ((event.rrule ?? "").length > 0) {
      parts.push("重复");
    }
    if ((event.exdate ?? "").length > 0) {
      parts.push("有例外");
    }
	    if ((event.percentComplete ?? 0) > 0) {
	      parts.push(`完成 ${event.percentComplete}%`);
	    }
	    if ((event.conflictStatus ?? "none") !== "none") {
	      parts.push("同步冲突");
	    }

		    return parts.length > 0 ? ` · ${parts.join(" · ")}` : "";
	  }

	  private editingEventHasConflict(): boolean {
	    const event: CalendarEvent | null = this.editingEvent();
	    return event !== null && (event.conflictStatus ?? "none") !== "none";
	  }

	  private conflictSummary(event: CalendarEvent): string {
	    const remote: CalendarEvent | null = this.remoteEventFromConflict(event.conflictJson ?? "");
	    if (remote === null) {
	      return "远端版本发生变化；当前仅保留了冲突状态，可选择保留本地后重新上传。";
	    }

	    return `远端版本：「${remote.title}」 ${formatDateTime(remote.startAt)}-${formatDateTime(remote.endAt)}。本地版本：「${event.title}」。`;
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

	  private eventCategoryColor(event: CalendarEvent): string {
	    const source: CalendarSource | null = this.sourceForEvent(event);
	    if (source !== null) {
	      return this.sourceColor(source);
	    }

	    const eventColor: string = (event.backgroundColor ?? "").trim();
	    if (eventColor.length > 0) {
	      return this.normalizedCategoryColor(eventColor);
	    }
    return this.normalizedCategoryColor(event.categoryColor ?? DEFAULT_CATEGORY_COLOR);
  }

  private eventKindLabel(value: CalendarEventKind): string {
    if (value === "important") {
      return "重要日";
    }

    if (value === "reminder") {
      return "提醒事件";
    }

    if (value === "task") {
      return "任务";
    }

    if (value === "focus") {
      return "专注时间";
    }

    if (value === "outOfOffice") {
      return "外出";
    }

    if (value === "workingLocation") {
      return "办公地点";
    }

    if (value === "appointment") {
      return "预约";
    }

    return "日历";
  }

  private privacyLabel(value: CalendarPrivacy): string {
    if (value === "public") {
      return "公开";
    }

    if (value === "private") {
      return "私密";
    }

    if (value === "confidential") {
      return "机密";
    }

    return "默认隐私";
  }

  private eventStatusLabel(value: CalendarEventStatus): string {
    if (value === "tentative") {
      return "暂定";
    }

    if (value === "cancelled") {
      return "已取消";
    }

    return "已确认";
  }

  private normalizedCategoryColor(value: string): string {
    const color: string = value.trim();
    if (color.length === 0) {
      return DEFAULT_CATEGORY_COLOR;
    }

    if (color.match(/^#[0-9a-fA-F]{6}$/) !== null) {
      return color;
    }

    return DEFAULT_CATEGORY_COLOR;
  }

  private conflictCount(event: CalendarEvent): number {
    const originalId: string = this.originalEventId(event);
    return this.expandedEventsInRange(event.startAt, event.endAt).filter((item: CalendarEvent) =>
      this.originalEventId(item) !== originalId &&
        this.eventsOverlap(event.startAt, event.endAt, item.startAt, item.endAt)
    ).length;
  }

  private formConflictSummary(): string {
    const startAt: number = this.parseInputDate(this.startInput);
    const rawEndAt: number = this.parseInputDate(this.endInput);
    if (startAt <= 0 || rawEndAt <= startAt) {
      return "";
    }

    const endAt: number = this.allDayInput ? startOfDay(rawEndAt) + DAY_MS : rawEndAt;
    const conflicts: CalendarEvent[] = this.expandedEventsInRange(startAt, endAt).filter((event: CalendarEvent) =>
      event.id !== this.editingEventId &&
        this.originalEventId(event) !== this.editingEventId &&
        this.eventsOverlap(startAt, endAt, event.startAt, event.endAt)
    );

    if (conflicts.length === 0) {
      return "";
    }

    return `时间冲突：与 ${conflicts.length} 项日程重叠，最近一项为「${conflicts[0].title}」`;
  }

  private eventsOverlap(leftStart: number, leftEnd: number, rightStart: number, rightEnd: number): boolean {
    return leftStart < rightEnd && leftEnd > rightStart;
  }

  private expandedEventsInRange(rangeStart: number, rangeEnd: number): CalendarEvent[] {
    return expandRecurringEvents(this.events, rangeStart, rangeEnd);
  }

  private eventsForListWindow(): CalendarEvent[] {
    const baseStart: number = this.monthStart(this.visibleMonth);
    const rangeStart: number = this.viewConfig.agendaShowPastDays === true ? baseStart - 31 * DAY_MS : startOfDay(Date.now());
    return this.expandedEventsInRange(rangeStart, addMonths(baseStart, 12));
  }

  private originalEventFor(event: CalendarEvent): CalendarEvent {
    const originalId: string = this.originalEventId(event);
    const found: CalendarEvent[] = this.events.filter((item: CalendarEvent) => item.id === originalId);
    return found.length > 0 ? found[0] : event;
  }

  private originalEventId(event: CalendarEvent): string {
    const markerIndex: number = event.id.indexOf(RECURRENCE_ID_MARKER);
    return markerIndex >= 0 ? event.id.substring(0, markerIndex) : event.id;
  }

  private newCalendarKicker(): string {
	    if (this.isTimeGridView()) {
	      const days: number[] = this.rangeDaysForSelectedView();
	      return `${this.formatShortDate(days[0])} 至 ${this.formatShortDate(days[days.length - 1])}`;
	    }

    if (this.scheduleView === "month") {
      return `${new Date(this.visibleMonth).getFullYear()} 年`;
    }

    if (this.scheduleView === "year") {
      return "全年概览";
    }

    if (this.searchKeyword.trim().length > 0 || this.scheduleView === "list") {
      return "全局查找";
    }

    return `${this.formatFullDate(this.selectedDay)} ${this.weekdayFullLabel(this.selectedDay)}`;
  }

  private newCalendarTitle(): string {
    if (this.scheduleView === "day") {
      return `${new Date(this.selectedDay).getMonth() + 1}月`;
    }

	    if (this.scheduleView === "week") {
	      return "本周";
	    }

	    if (this.scheduleView === "3days") {
	      return "3日";
	    }

	    if (this.scheduleView === "workweek") {
	      return "工作周";
	    }

    if (this.scheduleView === "month") {
      return `${new Date(this.visibleMonth).getMonth() + 1}月`;
    }

    if (this.scheduleView === "year") {
      return `${new Date(this.visibleMonth).getFullYear()}`;
    }

    if (this.searchKeyword.trim().length > 0 || this.scheduleView === "list") {
      return "搜索日程";
    }

    return sameDay(this.selectedDay, Date.now()) ? "今天" : `${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日`;
  }

  private topbarDateText(): string {
    return `${new Date(this.selectedDay).getMonth() + 1}月${new Date(this.selectedDay).getDate()}日 ${this.weekdayFullLabel(this.selectedDay)}`;
  }

  private topbarTitle(): string {
    if (sameDay(this.selectedDay, Date.now())) {
      return "今天";
    }

    if (this.scheduleView === "month") {
      return `${new Date(this.selectedDay).getMonth() + 1}月`;
    }

    return `${new Date(this.selectedDay).getDate()}日`;
  }

	  private weekDaysForSelectedDay(): number[] {
	    const first: number = this.weekStart(this.selectedDay);
	    const days: number[] = [];
	    for (let index = 0; index < 7; index += 1) {
	      days.push(addDays(first, index));
    }

	    return days;
	  }

	  private rangeDaysForSelectedView(): number[] {
	    if (this.scheduleView === "3days") {
	      return [startOfDay(this.selectedDay), addDays(this.selectedDay, 1), addDays(this.selectedDay, 2)];
	    }

	    const first: number = this.weekStart(this.selectedDay);
	    const days: number[] = [];
	    const count: number = this.scheduleView === "workweek" ? 5 : 7;
	    for (let index = 0; index < count; index += 1) {
	      days.push(addDays(first, index));
	    }

	    return days;
	  }

  private weekdayLabel(day: number): string {
    return ["日", "一", "二", "三", "四", "五", "六"][new Date(day).getDay()];
  }

  private weekdayFullLabel(day: number): string {
    return `周${this.weekdayLabel(day)}`;
  }

  private monthGridDaysMonday(monthTimestamp: number): number[] {
    const first: Date = new Date(this.monthStart(monthTimestamp));
    const startOffset: number = (first.getDay() + 6) % 7;
    const gridStart: number = addDays(first.getTime(), -startOffset);
    const days: number[] = [];
    const totalDays: number = this.viewConfig.showAdjacentMonths === false && this.viewConfig.showSixWeeks === false ? 35 : 42;
    for (let index = 0; index < totalDays; index += 1) {
      days.push(addDays(gridStart, index));
    }

    return days;
  }

  private todaySummaryTitle(): string {
    const count: number = this.eventCountForDay(this.selectedDay);
    const freeSlots: number = count >= 4 ? 1 : 2;
    return `${count} 个日程，${freeSlots} 段空档`;
  }

  private todayHeroTitle(): string {
    const events: CalendarEvent[] = this.eventsForDay(startOfDay(Date.now()));
    if (events.length === 0) {
      return "今天暂无安排";
    }

    const next: CalendarEvent = events[0];
    return next.allDay ? `全天：${next.title}` : `${formatTime(next.startAt)} ${next.title}`;
  }

  private todayHeroBody(): string {
    const events: CalendarEvent[] = this.eventsForDay(startOfDay(Date.now()));
    if (events.length === 0) {
      return "可以直接点击 + 添加今天的日程，新增后会自动同步到 CalDAV。";
    }

    const next: CalendarEvent = events[0];
    const status: string = this.syncStatusLabel(this.originalEventFor(next));
    return `${this.eventTimelineMeta(next)} · ${status}`;
  }

  private todaySummaryBody(): string {
    const events: CalendarEvent[] = this.eventsForDay(this.selectedDay);
    if (events.length === 0) {
      return "今天没有固定安排，适合添加深度工作或临时沟通。";
    }

    const next: CalendarEvent = events[0];
    const timeLabel: string = next.allDay ? "全天" : formatTime(next.startAt);
    if (events.length === 1) {
      return `下一项 ${timeLabel} 开始。当天节奏较轻，可以继续安排重点工作。`;
    }

    return `下一项 ${timeLabel} 开始。上午集中处理会议，下午适合安排深度工作。`;
  }

  private eventTimelineMeta(event: CalendarEvent): string {
    const source: CalendarSource | null = this.sourceForEvent(event);
    const place: string = event.location.length > 0 ? event.location : this.eventKindLabel(event.eventKind ?? "calendar");
    const sourceLabel: string = source === null ? "" : `${source.name} · `;
    if ((event.reminderMinutes ?? 0) > 0) {
      return `${sourceLabel}${place} · 提前 ${event.reminderMinutes} 分钟提醒`;
    }

    if ((event.conferenceUrl ?? "").length > 0) {
      return `${sourceLabel}${place} · 视频会议`;
    }

    return `${sourceLabel}${place}`;
  }
}


@Component
struct ConfigButton {
  @Prop label: string = ""
  @Prop value: string = ""
  @Prop active: boolean = false
  onClickAction?: (value: string) => void

  build() {
    Button(this.label)
      .height(38)
      .layoutWeight(1)
      .backgroundColor(this.active ? "#E7F5EF" : "#EEF3F6")
      .fontColor(this.active ? "#087A5A" : "#687480")
      .fontWeight(FontWeight.Bold)
      .borderRadius(8)
      .fontSize(13)
      .margin({ right: 6 })
      .onClick(() => {
        if (this.onClickAction) {
          this.onClickAction(this.value);
        }
      })
  }
}
