export type CalendarSyncStatus = "clean" | "dirty" | "deleted";
export type CalendarConflictStatus = "none" | "localDirtyRemoteChanged";
export type CalendarEventKind =
  "calendar" | "important" | "reminder" | "task" | "focus" | "outOfOffice" | "workingLocation" | "appointment";
export type CalendarAvailability = "busy" | "free";
export type CalendarPrivacy = "default" | "public" | "private" | "confidential";
export type CalendarEventStatus = "confirmed" | "tentative" | "cancelled";
export type CalendarDateMarkingType = "dot" | "multi-dot" | "period" | "multi-period" | "custom";
export type CalendarAppointmentStatus = "available" | "held" | "booked" | "cancelled";
export type CalendarAuthType = "basic" | "bearer" | "none" | "custom";

export interface CalendarAccount {
  readonly id?: string;
  readonly displayName?: string;
  readonly providerType?: string;
  readonly providerPresetJson?: string;
  readonly serverUrl: string;
  readonly username: string;
  readonly password: string;
  readonly authType?: CalendarAuthType;
  readonly bearerToken?: string;
  readonly customHeadersJson?: string;
  readonly isActive?: boolean;
}

export type CalendarSourceType = "caldav" | "subscription" | "local";
export type CalendarResourceType = "room" | "equipment" | "person" | "resource";

export interface CalendarSource {
  readonly id?: string;
  readonly accountId: string;
  readonly name: string;
  readonly description?: string;
  readonly collectionUrl: string;
  readonly subscriptionUrl?: string;
  readonly principalUrl?: string;
  readonly homeSetUrl?: string;
  readonly scheduleInboxUrl?: string;
  readonly scheduleOutboxUrl?: string;
  readonly calendarUserAddressSet?: string;
  readonly ownerEmail?: string;
  readonly color: string;
  readonly backgroundColor?: string;
  readonly borderColor?: string;
  readonly textColor?: string;
  readonly isVisible: boolean;
  readonly isDefault: boolean;
  readonly isReadOnly: boolean;
  readonly sourceType: CalendarSourceType;
  readonly freeBusyTransparent?: boolean;
  readonly displayOrder?: number;
  readonly refreshIntervalMinutes?: number;
  readonly refreshPolicy?: string;
  readonly permissionsJson?: string;
  readonly sharePermissionsJson?: string;
  readonly shareUsersJson?: string;
  readonly shareGroupsJson?: string;
  readonly publicShareUrl?: string;
  readonly publicShareToken?: string;
  readonly supportedReportsJson?: string;
  readonly supportedComponentsJson?: string;
  readonly discoveryTraceJson?: string;
  readonly capabilitySource?: string;
  readonly lastDiscoveryError?: string;
  readonly providerType?: string;
  readonly providerPresetJson?: string;
  readonly syncStrategy?: string;
  readonly externalProviderId?: string;
  readonly nativeCalendarId?: string;
  readonly nativeCalendarSyncState?: string;
  readonly widgetConfigJson?: string;
  readonly providerAdapterType?: string;
  readonly sourceLoadingState?: string;
  readonly lastLoadedRangeStart?: number;
  readonly lastLoadedRangeEnd?: number;
  readonly subscriptionEtag?: string;
  readonly subscriptionLastModified?: string;
  readonly ctag?: string;
  readonly syncToken?: string;
  readonly lastSuccessfulSyncAt?: number;
  readonly lastSyncAt?: number;
  readonly lastSyncHttpStatus?: number;
  readonly retryAfterSeconds?: number;
  readonly lastSyncDiagnosticJson?: string;
  readonly lastSyncError?: string;
}

export interface CalendarResource {
  readonly id?: string;
  readonly sourceId?: string;
  readonly resourceType: CalendarResourceType;
  readonly name: string;
  readonly email?: string;
  readonly externalId?: string;
  readonly parentResourceId?: string;
  readonly resourceGroupId?: string;
  readonly capacity?: number;
  readonly location?: string;
  readonly color?: string;
  readonly isBookable?: boolean;
  readonly isVisible?: boolean;
  readonly availabilityJson?: string;
  readonly conflictPolicy?: string;
  readonly autoAccept?: boolean;
  readonly backendId?: string;
  readonly eventConstraintJson?: string;
  readonly eventAllowJson?: string;
  readonly eventClassNames?: string;
  readonly permissionsJson?: string;
  readonly rawPropsJson?: string;
  readonly lastSyncAt?: number;
}

export interface CalendarEventDraft {
  readonly id?: string;
  readonly sourceId?: string;
  readonly eventSourceId?: string;
  readonly title: string;
  readonly startAt: number;
  readonly endAt: number;
  readonly allDay: boolean;
  readonly location: string;
  readonly notes: string;
  readonly reminderMinutes?: number;
  readonly secondReminderMinutes?: number;
  readonly rrule?: string;
  readonly categoryColor?: string;
  readonly backgroundColor?: string;
  readonly borderColor?: string;
  readonly textColor?: string;
  readonly dragBackgroundColor?: string;
  readonly eventCategory?: string;
  readonly eventKind?: CalendarEventKind;
  readonly url?: string;
  readonly attendees?: string;
  readonly attendeeJson?: string;
  readonly organizerName?: string;
  readonly organizerEmail?: string;
  readonly conferenceUrl?: string;
  readonly attachmentUrl?: string;
  readonly attachmentsJson?: string;
  readonly travelMinutes?: number;
  readonly comingDuration?: number;
  readonly availability?: CalendarAvailability;
  readonly freeBusyTransparent?: boolean;
  readonly privacy?: CalendarPrivacy;
  readonly timeZone?: string;
  readonly eventStatus?: CalendarEventStatus;
  readonly appointmentStatus?: CalendarAppointmentStatus;
  readonly appointmentCapacity?: number;
  readonly appointmentBookedCount?: number;
  readonly appointmentMinDurationMinutes?: number;
  readonly appointmentMaxDurationMinutes?: number;
  readonly appointmentBufferBeforeMinutes?: number;
  readonly appointmentBufferAfterMinutes?: number;
  readonly appointmentDeadlineMinutes?: number;
  readonly appointmentPublicUrl?: string;
  readonly appointmentFormJson?: string;
  readonly appointmentTimezone?: string;
  readonly appointmentSlotIntervalMinutes?: number;
  readonly appointmentApprovalRequired?: boolean;
  readonly bookingJson?: string;
  readonly bookingContactName?: string;
  readonly bookingContactEmail?: string;
  readonly bookingContactPhone?: string;
  readonly bookingConfirmationStatus?: string;
  readonly bookingStatus?: string;
  readonly exdate?: string;
  readonly rdate?: string;
  readonly recurrenceId?: string;
  readonly sequence?: number;
  readonly reminderOffsets?: string;
  readonly dueAt?: number;
  readonly completedAt?: number;
  readonly priority?: number;
  readonly percentComplete?: number;
  readonly milestoneStatus?: string;
  readonly dueDateClass?: string;
  readonly groupId?: string;
  readonly displayMode?: string;
  readonly overlap?: boolean;
  readonly editable?: boolean;
  readonly startEditable?: boolean;
  readonly durationEditable?: boolean;
  readonly resourceEditable?: boolean;
  readonly interactive?: boolean;
  readonly eventReadOnly?: boolean;
  readonly isVisible?: boolean;
  readonly isPending?: boolean;
  readonly isFocused?: boolean;
  readonly overlapPosition?: number;
  readonly overlapCount?: number;
  readonly classNames?: string;
  readonly customStyleJson?: string;
  readonly constraintJson?: string;
  readonly extendedPropsJson?: string;
  readonly rawPropsJson?: string;
  readonly resourceIdsJson?: string;
  readonly roomIdsJson?: string;
  readonly resourceStatusJson?: string;
  readonly alarmAction?: string;
  readonly snoozeMinutes?: number;
  readonly snoozeTimes?: number;
  readonly allDayReminderAt?: string;
  readonly alarmActionsJson?: string;
}

export interface CalendarEvent extends CalendarEventDraft {
  readonly id: string;
  readonly sourceId: string;
  readonly uid: string;
  readonly href: string;
  readonly etag: string;
  readonly lastModified: number;
  readonly syncStatus: CalendarSyncStatus;
  readonly conflictStatus?: CalendarConflictStatus;
  readonly conflictJson?: string;
  readonly reminderId?: number;
}

export interface CalendarViewConfig {
  readonly id?: string;
  readonly defaultView: string;
  readonly weekStartsOn: number;
  readonly weekEndsOn?: number;
  readonly minHour: number;
  readonly maxHour: number;
  readonly timeSlotMinutes: number;
  readonly maxVisibleEventsPerDay: number;
  readonly overlapOffset: number;
  readonly swipeEnabled: boolean;
  readonly showWeekNumbers: boolean;
  readonly showSixWeeks?: boolean;
  readonly showAdjacentMonths?: boolean;
  readonly nowIndicatorVisible?: boolean;
  readonly scrollOffsetMinutes?: number;
  readonly hourRowHeight?: number;
  readonly eventMinHeightForMonthView?: number;
  readonly showAllDayEventCell?: boolean;
  readonly timeslots?: number;
  readonly monthMoreLabel?: string;
  readonly eventOrder?: string;
  readonly locale?: string;
  readonly hourFormat?: string;
  readonly timeZone?: string;
  readonly enabledViewsJson?: string;
  readonly agendaEmptyText?: string;
  readonly agendaGroupMode?: string;
  readonly agendaShowPastDays?: boolean;
  readonly agendaPastScrollRange?: number;
  readonly agendaFutureScrollRange?: number;
  readonly agendaShowOnlySelectedDayItems?: boolean;
  readonly themeMode?: string;
  readonly defaultReminderMinutes?: number;
  readonly reminderSound?: string;
  readonly reminderVibrate?: boolean;
  readonly eventKindFilter?: string;
  readonly sourceFilterJson?: string;
  readonly hideCancelledEvents?: boolean;
  readonly showIncompleteTasksOnly?: boolean;
  readonly businessHoursJson?: string;
  readonly minSelectableDate?: number;
  readonly maxSelectableDate?: number;
  readonly disabledDaysIndexesJson?: string;
  readonly displayLoadingIndicator?: boolean;
  readonly loadedDateRangesJson?: string;
}

export interface CalendarDateMarker {
  readonly id?: string;
  readonly markerDate: number;
  readonly markingType: CalendarDateMarkingType;
  readonly title?: string;
  readonly color?: string;
  readonly selected?: boolean;
  readonly disabled?: boolean;
  readonly disableTouchEvent?: boolean;
  readonly dotColorsJson?: string;
  readonly multiPeriodJson?: string;
  readonly periodStart?: number;
  readonly periodEnd?: number;
  readonly periodColor?: string;
  readonly selectedColor?: string;
  readonly selectedDotColor?: string;
  readonly accessibilityLabel?: string;
  readonly customMarkJson?: string;
}

export interface CalendarReminderPreferences {
  readonly defaultReminderMinutes?: number;
  readonly reminderSound?: string;
  readonly reminderVibrate?: boolean;
  readonly snoozeMinutes?: number;
  readonly snoozeTimes?: number;
}

export interface CalendarSyncResult {
  readonly pulled: number;
  readonly pushed: number;
  readonly deleted: number;
  readonly failed: number;
}

export interface CalendarFreeBusySlot {
  readonly startAt: number;
  readonly endAt: number;
  readonly busyType: string;
}

export interface CalendarFreeBusyResult {
  readonly sourceId: string;
  readonly ownerEmail: string;
  readonly slots: CalendarFreeBusySlot[];
  readonly failed: boolean;
  readonly error?: string;
}

export interface CalendarConnectionTestResult {
  readonly providerType: string;
  readonly normalizedServerUrl: string;
  readonly collectionUrl: string;
  readonly authHint: string;
  readonly discoveryHint: string;
  readonly capabilities: string;
  readonly diagnosticHint: string;
  readonly discoveryTrace: string;
  readonly diagnosticJson?: string;
  readonly syncStrategy?: string;
  readonly sources: number;
  readonly total: number;
  readonly parsed: number;
  readonly failed: number;
}

export const DEFAULT_ZOHO_CALDAV_URL: string = "https://calendar.zoho.com/.well-known/caldav";
