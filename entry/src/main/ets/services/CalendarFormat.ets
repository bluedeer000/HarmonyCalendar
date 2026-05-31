import { CalendarEvent, CalendarEventDraft } from "./CalendarTypes";

interface IcsProperty {
  readonly name: string;
  readonly params: string;
  readonly value: string;
}

interface RecurrenceRule {
  readonly freq: string;
  readonly interval: number;
  readonly count: number;
  readonly until: number;
}

interface CalendarAttendee {
  readonly email: string;
  readonly name: string;
  readonly role: string;
  readonly status: string;
  readonly rsvp: boolean;
  readonly cutype?: string;
}

interface AttendeeResourceSummary {
  readonly resourceIdsJson: string;
  readonly roomIdsJson: string;
  readonly resourceStatusJson: string;
}

type CalendarComponentKind = "VEVENT" | "VTODO";

interface CalendarComponentBlock {
  readonly kind: CalendarComponentKind;
  readonly lines: string[];
}

interface PreservedIcsProperty {
  readonly name: string;
  readonly params: string;
  readonly value: string;
}

export const createLocalId = (prefix: string): string =>
  `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 12)}`;

export const createEventUid = (): string => `${createLocalId("uid")}@harmony-calendar`;

export const normalizeCollectionUrl = (url: string): string => {
  const trimmed: string = url.trim();
  if (trimmed.length === 0) {
    return trimmed;
  }

  return trimmed.endsWith("/") ? trimmed : `${trimmed}/`;
};

export const normalizeServerUrl = (url: string): string => {
  const trimmed: string = url.trim();
  if (trimmed.endsWith("/.well-known/caldav/")) {
    return trimmed.substring(0, trimmed.length - 1);
  }

  return trimmed;
};

export const hrefToId = (href: string): string => {
  const cleaned: string = href.replace(/[^A-Za-z0-9_-]/g, "_");
  return cleaned.length > 0 ? cleaned : createLocalId("event");
};

export const basenameFromHref = (href: string): string => {
  const withoutQuery: string = href.split("?")[0];
  const parts: string[] = withoutQuery.split("/").filter((part: string) => part.length > 0);
  return parts.length > 0 ? parts[parts.length - 1] : "";
};

export const buildEventHref = (collectionUrl: string, uid: string): string =>
  `${normalizeCollectionUrl(collectionUrl)}${encodeURIComponent(uid)}.ics`;

export const formatDateTime = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())} ${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
};

export const formatTime = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
};

export const formatMonthTitle = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${date.getFullYear()} 年 ${date.getMonth() + 1} 月`;
};

export const startOfDay = (timestamp: number): number => {
  const date = new Date(timestamp);
  return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
};

export const startOfMonth = (timestamp: number): number => {
  const date = new Date(timestamp);
  return new Date(date.getFullYear(), date.getMonth(), 1).getTime();
};

export const addDays = (timestamp: number, days: number): number => {
  const date = new Date(timestamp);
  date.setDate(date.getDate() + days);
  return date.getTime();
};

export const addMonths = (timestamp: number, months: number): number => {
  const date = new Date(timestamp);
  date.setMonth(date.getMonth() + months);
  return date.getTime();
};

export const sameDay = (left: number, right: number): boolean => startOfDay(left) === startOfDay(right);

export const monthGridDays = (monthTimestamp: number): number[] => {
  const first: Date = new Date(startOfMonth(monthTimestamp));
  const startOffset: number = first.getDay();
  const gridStart: number = addDays(first.getTime(), -startOffset);
  const days: number[] = [];

  for (let index = 0; index < 42; index += 1) {
    days.push(addDays(gridStart, index));
  }

  return days;
};

export const parseIcsEvent = (
  ics: string,
  href: string,
  etag: string,
  fallbackId: string = hrefToId(href)
): CalendarEvent | null => {
  const lines: string[] = unfoldIcsLines(ics);
  const blocks: CalendarComponentBlock[] = extractCalendarComponentBlocks(lines);
  const block: CalendarComponentBlock | undefined = blocks.length > 0 ? blocks[0] : undefined;
  return block === undefined ? null : parseIcsEventLines(block.lines, block.kind, href, etag, fallbackId);
};

const parseIcsEventLines = (
  eventLines: string[],
  componentKind: CalendarComponentKind,
  href: string,
  etag: string,
  fallbackId: string
): CalendarEvent | null => {

  if (eventLines.length === 0) {
    return null;
  }

  const properties: IcsProperty[] = eventLines.map(parseProperty);
  const uid: string = readProperty(properties, "UID") || fallbackId;
  const title: string = readProperty(properties, "SUMMARY") || "无标题";
  const location: string = readProperty(properties, "LOCATION");
  const notes: string = readProperty(properties, "DESCRIPTION");
  const rrule: string = readProperty(properties, "RRULE");
  const exdate: string = readDateListProperties(properties, "EXDATE");
  const rdate: string = readDateListProperties(properties, "RDATE");
  const recurrenceId: string = readProperty(properties, "RECURRENCE-ID");
  const categoryColor: string = readProperty(properties, "X-HARMONY-COLOR");
  const backgroundColor: string = readProperty(properties, "X-HARMONY-BACKGROUND-COLOR");
  const borderColor: string = readProperty(properties, "X-HARMONY-BORDER-COLOR");
  const textColor: string = readProperty(properties, "X-HARMONY-TEXT-COLOR");
  const dragBackgroundColor: string = readProperty(properties, "X-HARMONY-DRAG-BACKGROUND-COLOR");
  const eventSourceId: string = readProperty(properties, "X-HARMONY-EVENT-SOURCE-ID");
  const eventCategory: string = readProperty(properties, "CATEGORIES") || readProperty(properties, "X-HARMONY-EVENT-CATEGORY");
  const eventKind: string = readProperty(properties, "X-HARMONY-KIND");
  const alarmMinutes: number[] = readDisplayAlarmTriggerMinutes(eventLines);
  const url: string = readProperty(properties, "URL");
  const organizer: IcsProperty | null = readPropertyObject(properties, "ORGANIZER");
  const conferenceUrl: string = readProperty(properties, "X-HARMONY-CONFERENCE-URL") ||
    readProperty(properties, "X-GOOGLE-CONFERENCE");
  const attachmentUrl: string = readProperty(properties, "ATTACH");
  const attachmentsJson: string = readAttachmentJson(properties);
  const travelMinutesRaw: string = readProperty(properties, "X-HARMONY-TRAVEL-MINUTES");
  const comingDurationRaw: string = readProperty(properties, "X-HARMONY-COMING-DURATION");
  const availabilityRaw: string = readProperty(properties, "TRANSP");
  const privacyRaw: string = readProperty(properties, "CLASS");
  const statusRaw: string = readProperty(properties, "STATUS");
  const appointmentStatusRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-STATUS");
  const appointmentCapacityRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-CAPACITY");
  const appointmentBookedCountRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-BOOKED-COUNT");
  const appointmentMinDurationRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-MIN-DURATION");
  const appointmentMaxDurationRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-MAX-DURATION");
  const appointmentBufferBeforeRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-BUFFER-BEFORE");
  const appointmentBufferAfterRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-BUFFER-AFTER");
  const appointmentDeadlineRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-DEADLINE");
  const appointmentPublicUrl: string = readProperty(properties, "X-HARMONY-APPOINTMENT-PUBLIC-URL");
  const appointmentFormJson: string = readProperty(properties, "X-HARMONY-APPOINTMENT-FORM-JSON");
  const appointmentTimezone: string = readProperty(properties, "X-HARMONY-APPOINTMENT-TIMEZONE");
  const appointmentSlotIntervalRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-SLOT-INTERVAL");
  const appointmentApprovalRequiredRaw: string = readProperty(properties, "X-HARMONY-APPOINTMENT-APPROVAL-REQUIRED");
  const bookingJson: string = readProperty(properties, "X-HARMONY-BOOKING-JSON");
  const bookingContactName: string = readProperty(properties, "X-HARMONY-BOOKING-CONTACT-NAME");
  const bookingContactEmail: string = readProperty(properties, "X-HARMONY-BOOKING-CONTACT-EMAIL");
  const bookingContactPhone: string = readProperty(properties, "X-HARMONY-BOOKING-CONTACT-PHONE");
  const bookingConfirmationStatus: string = readProperty(properties, "X-HARMONY-BOOKING-CONFIRMATION-STATUS");
  const bookingStatus: string = readProperty(properties, "X-HARMONY-BOOKING-STATUS");
  const sequenceRaw: string = readProperty(properties, "SEQUENCE");
  const due: IcsProperty | null = readPropertyObject(properties, "DUE");
  const completed: IcsProperty | null = readPropertyObject(properties, "COMPLETED");
  const priorityRaw: string = readProperty(properties, "PRIORITY");
  const percentCompleteRaw: string = readProperty(properties, "PERCENT-COMPLETE");
  const milestoneStatus: string = readProperty(properties, "X-HARMONY-MILESTONE-STATUS");
  const dueDateClass: string = readProperty(properties, "X-HARMONY-DUE-DATE-CLASS");
  const groupId: string = readProperty(properties, "X-HARMONY-GROUP-ID");
  const displayMode: string = readProperty(properties, "X-HARMONY-DISPLAY-MODE");
  const overlapRaw: string = readProperty(properties, "X-HARMONY-OVERLAP");
  const editableRaw: string = readProperty(properties, "X-HARMONY-EDITABLE");
  const startEditableRaw: string = readProperty(properties, "X-HARMONY-START-EDITABLE");
  const durationEditableRaw: string = readProperty(properties, "X-HARMONY-DURATION-EDITABLE");
  const resourceEditableRaw: string = readProperty(properties, "X-HARMONY-RESOURCE-EDITABLE");
  const interactiveRaw: string = readProperty(properties, "X-HARMONY-INTERACTIVE");
  const eventReadOnlyRaw: string = readProperty(properties, "X-HARMONY-EVENT-READ-ONLY");
  const isVisibleRaw: string = readProperty(properties, "X-HARMONY-IS-VISIBLE");
  const isPendingRaw: string = readProperty(properties, "X-HARMONY-IS-PENDING");
  const isFocusedRaw: string = readProperty(properties, "X-HARMONY-IS-FOCUSED");
  const overlapPositionRaw: string = readProperty(properties, "X-HARMONY-OVERLAP-POSITION");
  const overlapCountRaw: string = readProperty(properties, "X-HARMONY-OVERLAP-COUNT");
  const classNames: string = readProperty(properties, "X-HARMONY-CLASS-NAMES");
  const customStyleJson: string = readProperty(properties, "X-HARMONY-CUSTOM-STYLE-JSON");
  const constraintJson: string = readProperty(properties, "X-HARMONY-CONSTRAINT-JSON");
  const extendedPropsJson: string = readProperty(properties, "X-HARMONY-EXTENDED-PROPS-JSON");
  const rawPropsJson: string = readRawPropsJson(properties);
  const attendeeResources: AttendeeResourceSummary = readAttendeeResourceSummary(properties);
  const resourceIdsJson: string = readProperty(properties, "X-HARMONY-RESOURCE-IDS-JSON") || attendeeResources.resourceIdsJson;
  const roomIdsJson: string = readProperty(properties, "X-HARMONY-ROOM-IDS-JSON") || attendeeResources.roomIdsJson;
  const resourceStatusJson: string = readProperty(properties, "X-HARMONY-RESOURCE-STATUS-JSON") || attendeeResources.resourceStatusJson;
  const alarmAction: string = readProperty(properties, "X-HARMONY-ALARM-ACTION");
  const snoozeMinutesRaw: string = readProperty(properties, "X-HARMONY-SNOOZE-MINUTES");
  const snoozeTimesRaw: string = readProperty(properties, "X-HARMONY-SNOOZE-TIMES");
  const allDayReminderAt: string = readProperty(properties, "X-HARMONY-ALL-DAY-REMINDER-AT");
  const alarmActionsJson: string = readProperty(properties, "X-HARMONY-ALARM-ACTIONS-JSON");
  const dtStart: IcsProperty | null = readPropertyObject(properties, "DTSTART");
  const dtEnd: IcsProperty | null = readPropertyObject(properties, "DTEND");
  const lastModifiedRaw: string = readProperty(properties, "LAST-MODIFIED") || readProperty(properties, "DTSTAMP");

  if (dtStart === null && componentKind === "VEVENT") {
    return null;
  }

  const dueAtValue: number = due === null ? 0 : parseIcsDate(due.value, due.params.indexOf("VALUE=DATE") >= 0, due.params);
  const completedAtValue: number = completed === null ? 0 : parseIcsDate(completed.value, false, completed.params);
  const fallbackTaskAt: number = lastModifiedRaw.length > 0 ? parseIcsDate(lastModifiedRaw, false, "") : Date.now();
  const allDay: boolean = componentKind === "VTODO" ?
    (dtStart === null || dtStart.params.indexOf("VALUE=DATE") >= 0 || (due !== null && due.params.indexOf("VALUE=DATE") >= 0)) :
    dtStart.params.indexOf("VALUE=DATE") >= 0;
  const startAt: number = dtStart === null ? (dueAtValue > 0 ? dueAtValue : fallbackTaskAt) : parseIcsDate(dtStart.value, allDay, dtStart.params);
  const fallbackEnd: number = componentKind === "VTODO" ? (dueAtValue > 0 ? dueAtValue : startAt) : startAt + 60 * 60 * 1000;
  const endAt: number = dtEnd === null ? fallbackEnd : parseIcsDate(dtEnd.value, allDay, dtEnd.params);

  return {
    id: fallbackId,
    sourceId: "",
    eventSourceId,
    uid,
    href,
    etag,
    title: unescapeIcsText(title),
    startAt,
    endAt,
    allDay,
    location: unescapeIcsText(location),
    notes: unescapeIcsText(notes),
    reminderMinutes: alarmMinutes.length > 0 ? alarmMinutes[0] : 0,
    secondReminderMinutes: alarmMinutes.length > 1 ? alarmMinutes[1] : 0,
    rrule,
    exdate,
    rdate,
    recurrenceId,
    categoryColor: categoryColor.length > 0 ? categoryColor : "#2563EB",
    backgroundColor,
    borderColor,
    textColor,
    dragBackgroundColor,
    eventCategory: unescapeIcsText(eventCategory),
    eventKind: componentKind === "VTODO" && eventKind.length === 0 ? "task" : parseEventKind(eventKind),
    url,
    attendees: readAttendees(properties),
    attendeeJson: readAttendeeJson(properties),
    organizerName: organizer === null ? "" : readParamValue(organizer.params, "CN"),
    organizerEmail: organizer === null ? "" : organizer.value.replace(/^mailto:/i, "").trim(),
    conferenceUrl,
    attachmentUrl,
    attachmentsJson,
    travelMinutes: parsePositiveInteger(travelMinutesRaw),
    comingDuration: parsePositiveInteger(comingDurationRaw),
    availability: availabilityRaw.toUpperCase() === "TRANSPARENT" ? "free" : "busy",
    freeBusyTransparent: availabilityRaw.toUpperCase() === "TRANSPARENT",
    privacy: parsePrivacy(privacyRaw),
    timeZone: dtStart === null ? "" : readTzid(dtStart.params),
    eventStatus: parseEventStatus(statusRaw),
    appointmentStatus: parseAppointmentStatus(appointmentStatusRaw),
    appointmentCapacity: parsePositiveInteger(appointmentCapacityRaw),
    appointmentBookedCount: parsePositiveInteger(appointmentBookedCountRaw),
    appointmentMinDurationMinutes: parsePositiveInteger(appointmentMinDurationRaw),
    appointmentMaxDurationMinutes: parsePositiveInteger(appointmentMaxDurationRaw),
    appointmentBufferBeforeMinutes: parsePositiveInteger(appointmentBufferBeforeRaw),
    appointmentBufferAfterMinutes: parsePositiveInteger(appointmentBufferAfterRaw),
    appointmentDeadlineMinutes: parsePositiveInteger(appointmentDeadlineRaw),
    appointmentPublicUrl,
    appointmentFormJson,
    appointmentTimezone,
    appointmentSlotIntervalMinutes: parsePositiveInteger(appointmentSlotIntervalRaw),
    appointmentApprovalRequired: appointmentApprovalRequiredRaw.toUpperCase() === "TRUE",
    bookingJson,
    bookingContactName,
    bookingContactEmail,
    bookingContactPhone,
    bookingConfirmationStatus,
    bookingStatus,
    sequence: parseNonNegativeInteger(sequenceRaw),
    reminderOffsets: alarmMinutes.join(","),
    dueAt: dueAtValue,
    completedAt: completedAtValue,
    priority: parseNonNegativeInteger(priorityRaw),
    percentComplete: parsePercentComplete(percentCompleteRaw),
    milestoneStatus,
    dueDateClass,
    groupId,
    displayMode,
    overlap: overlapRaw.length === 0 ? true : overlapRaw.toUpperCase() !== "FALSE",
    editable: editableRaw.length === 0 ? true : editableRaw.toUpperCase() !== "FALSE",
    startEditable: startEditableRaw.length === 0 ? true : startEditableRaw.toUpperCase() !== "FALSE",
    durationEditable: durationEditableRaw.length === 0 ? true : durationEditableRaw.toUpperCase() !== "FALSE",
    resourceEditable: resourceEditableRaw.length === 0 ? true : resourceEditableRaw.toUpperCase() !== "FALSE",
    interactive: interactiveRaw.length === 0 ? true : interactiveRaw.toUpperCase() !== "FALSE",
    eventReadOnly: eventReadOnlyRaw.toUpperCase() === "TRUE",
    isVisible: isVisibleRaw.length === 0 ? true : isVisibleRaw.toUpperCase() !== "FALSE",
    isPending: isPendingRaw.toUpperCase() === "TRUE",
    isFocused: isFocusedRaw.toUpperCase() === "TRUE",
    overlapPosition: parsePositiveInteger(overlapPositionRaw),
    overlapCount: Math.max(1, parsePositiveInteger(overlapCountRaw)),
    classNames,
    customStyleJson,
    constraintJson,
    extendedPropsJson,
    rawPropsJson,
    resourceIdsJson,
    roomIdsJson,
    resourceStatusJson,
    alarmAction,
    snoozeMinutes: parsePositiveInteger(snoozeMinutesRaw),
    snoozeTimes: parsePositiveInteger(snoozeTimesRaw),
    allDayReminderAt,
    alarmActionsJson,
    lastModified: lastModifiedRaw.length > 0 ? parseIcsDate(lastModifiedRaw, false, "") : Date.now(),
    syncStatus: "clean"
  };
};

export const parseIcsEvents = (ics: string, hrefPrefix: string = "", etag: string = ""): CalendarEvent[] => {
  const lines: string[] = unfoldIcsLines(ics);
  const blocks: CalendarComponentBlock[] = extractCalendarComponentBlocks(lines);
  const events: CalendarEvent[] = [];
  for (let index = 0; index < blocks.length; index += 1) {
    const href: string = hrefPrefix.length > 0 ? `${hrefPrefix}#${index}` : `import://${index}`;
    const event: CalendarEvent | null = parseIcsEventLines(blocks[index].lines, blocks[index].kind, href, etag, hrefToId(href));
    if (event !== null) {
      events.push(event);
    }
  }

  return events;
};

export const expandRecurringEvents = (
  events: CalendarEvent[],
  rangeStart: number,
  rangeEnd: number
): CalendarEvent[] => {
  const expanded: CalendarEvent[] = [];
  if (rangeEnd <= rangeStart) {
    return expanded;
  }

  events.forEach((event: CalendarEvent) => {
    const rrule: string = event.rrule ?? "";
    if (rrule.trim().length === 0) {
      if (eventTouchesRange(event.startAt, event.endAt, rangeStart, rangeEnd)) {
        expanded.push(event);
      }
      return;
    }

    const rule: RecurrenceRule | null = parseRecurrenceRule(rrule, event.allDay);
    if (rule === null) {
      if (eventTouchesRange(event.startAt, event.endAt, rangeStart, rangeEnd)) {
        expanded.push(event);
      }
      return;
    }

    const duration: number = Math.max(event.endAt - event.startAt, 60 * 1000);
    let occurrenceStart: number = event.startAt;
    let occurrenceIndex: number = 0;
    const maxIterations: number = rule.count > 0 ? rule.count : 1000;
    const excludedDays: number[] = excludedOccurrenceDays(event.exdate ?? "", event.allDay);

    while (occurrenceIndex < maxIterations) {
      if (rule.until > 0 && occurrenceStart > rule.until) {
        break;
      }

      const occurrenceEnd: number = occurrenceStart + duration;
      if (excludedDays.indexOf(startOfDay(occurrenceStart)) < 0 && eventTouchesRange(occurrenceStart, occurrenceEnd, rangeStart, rangeEnd)) {
        expanded.push(buildOccurrenceEvent(event, occurrenceStart, occurrenceEnd, occurrenceIndex));
      }

      if (occurrenceStart >= rangeEnd && (rule.count <= 0 || occurrenceIndex + 1 >= rule.count)) {
        break;
      }

      if (occurrenceStart >= rangeEnd && rule.until <= 0) {
        break;
      }

      const nextStart: number = addRecurrenceInterval(occurrenceStart, rule.freq, rule.interval);
      if (nextStart <= occurrenceStart) {
        break;
      }

      occurrenceStart = nextStart;
      occurrenceIndex += 1;
    }
  });

  return expanded.sort((left: CalendarEvent, right: CalendarEvent) => left.startAt - right.startAt);
};

export const buildIcsEvent = (event: CalendarEventDraft, uid: string): string => {
  const now: string = toUtcIcsDate(Date.now());
  const timeZone: string = (event.timeZone ?? "").trim();
  const useTimeZone: boolean = !event.allDay && timeZone.length > 0;
  const start: string = event.allDay ? toIcsDateOnly(event.startAt) :
    useTimeZone ? toIcsLocalDateTime(event.startAt) : toUtcIcsDate(event.startAt);
  const end: string = event.allDay ? toIcsDateOnly(event.endAt) :
    useTimeZone ? toIcsLocalDateTime(event.endAt) : toUtcIcsDate(event.endAt);
  const startKey: string = event.allDay ? "DTSTART;VALUE=DATE" :
    useTimeZone ? `DTSTART;TZID=${safeIcsParam(timeZone)}` : "DTSTART";
  const endKey: string = event.allDay ? "DTEND;VALUE=DATE" :
    useTimeZone ? `DTEND;TZID=${safeIcsParam(timeZone)}` : "DTEND";
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//macto//Harmony Calendar//CN",
    "CALSCALE:GREGORIAN",
    (event.eventKind ?? "calendar") === "task" ? "BEGIN:VTODO" : "BEGIN:VEVENT",
    `UID:${uid}`,
    `DTSTAMP:${now}`,
    `LAST-MODIFIED:${now}`,
    `SUMMARY:${escapeIcsText(event.title.length > 0 ? event.title : "无标题")}`,
    `${startKey}:${start}`
  ];

  if ((event.eventKind ?? "calendar") !== "task") {
    lines.push(`${endKey}:${end}`);
  }

  if (event.location.trim().length > 0) {
    lines.push(`LOCATION:${escapeIcsText(event.location.trim())}`);
  }

  if (event.notes.trim().length > 0) {
    lines.push(`DESCRIPTION:${escapeIcsText(event.notes.trim())}`);
  }

  if (event.rrule !== undefined && event.rrule.trim().length > 0) {
    lines.push(`RRULE:${event.rrule.trim()}`);
  }

  appendDateListProperties(lines, "EXDATE", event.exdate ?? "");
  appendDateListProperties(lines, "RDATE", event.rdate ?? "");

  if ((event.recurrenceId ?? "").trim().length > 0) {
    lines.push(`RECURRENCE-ID:${(event.recurrenceId ?? "").trim()}`);
  }

  if ((event.sequence ?? 0) > 0) {
    lines.push(`SEQUENCE:${Math.floor(event.sequence ?? 0)}`);
  }

  if (event.categoryColor !== undefined && event.categoryColor.trim().length > 0) {
    lines.push(`X-HARMONY-COLOR:${event.categoryColor.trim()}`);
  }
  appendTextExtension(lines, "X-HARMONY-BACKGROUND-COLOR", event.backgroundColor ?? "");
  appendTextExtension(lines, "X-HARMONY-BORDER-COLOR", event.borderColor ?? "");
  appendTextExtension(lines, "X-HARMONY-TEXT-COLOR", event.textColor ?? "");
  appendTextExtension(lines, "X-HARMONY-DRAG-BACKGROUND-COLOR", event.dragBackgroundColor ?? "");

  if (event.eventKind !== undefined && event.eventKind !== "calendar") {
    lines.push(`X-HARMONY-KIND:${event.eventKind}`);
  }

  if ((event.url ?? "").trim().length > 0) {
    lines.push(`URL:${(event.url ?? "").trim()}`);
  }

  if ((event.organizerEmail ?? "").trim().length > 0) {
    const organizerName: string = (event.organizerName ?? "").trim();
    const cn: string = organizerName.length > 0 ? `;CN=${safeIcsParam(organizerName)}` : "";
    lines.push(`ORGANIZER${cn}:mailto:${(event.organizerEmail ?? "").trim()}`);
  }

  if ((event.conferenceUrl ?? "").trim().length > 0) {
    lines.push(`X-HARMONY-CONFERENCE-URL:${(event.conferenceUrl ?? "").trim()}`);
  }

  if ((event.attachmentUrl ?? "").trim().length > 0) {
    lines.push(`ATTACH;VALUE=URI:${(event.attachmentUrl ?? "").trim()}`);
  }

  appendAttachmentJson(lines, event.attachmentsJson ?? "");

  normalizedAttendees(event.attendees ?? "", event.attendeeJson ?? "").forEach((attendee: CalendarAttendee) => {
    const cn: string = attendee.name.length > 0 ? `;CN=${safeIcsParam(attendee.name)}` : `;CN=${safeIcsParam(attendee.email)}`;
    const role: string = attendee.role.length > 0 ? `;ROLE=${safeIcsParam(attendee.role.toUpperCase())}` : "";
    const cutype: string = (attendee.cutype ?? "").length > 0 ? `;CUTYPE=${safeIcsParam((attendee.cutype ?? "").toUpperCase())}` : "";
    const partstat: string = attendee.status.length > 0 ? attendee.status.toUpperCase() : "NEEDS-ACTION";
    const rsvp: string = attendee.rsvp ? ";RSVP=TRUE" : "";
    lines.push(`ATTENDEE${cn}${role}${cutype};PARTSTAT=${safeIcsParam(partstat)}${rsvp}:mailto:${attendee.email}`);
  });
  appendResourceAttendees(lines, event.roomIdsJson ?? "", "ROOM", event.resourceStatusJson ?? "");
  appendResourceAttendees(lines, event.resourceIdsJson ?? "", "RESOURCE", event.resourceStatusJson ?? "");

  if ((event.travelMinutes ?? 0) > 0) {
    lines.push(`X-HARMONY-TRAVEL-MINUTES:${Math.floor(event.travelMinutes ?? 0)}`);
  }

  if ((event.comingDuration ?? 0) > 0) {
    lines.push(`X-HARMONY-COMING-DURATION:${Math.floor(event.comingDuration ?? 0)}`);
  }

  appendTextExtension(lines, "X-HARMONY-EVENT-SOURCE-ID", event.eventSourceId ?? "");
  appendTextExtension(lines, "X-HARMONY-EVENT-CATEGORY", event.eventCategory ?? "");
  if ((event.eventCategory ?? "").trim().length > 0) {
    lines.push(`CATEGORIES:${escapeIcsText(event.eventCategory ?? "")}`);
  }

  if (event.freeBusyTransparent === true || (event.availability ?? "busy") === "free") {
    lines.push("TRANSP:TRANSPARENT");
  } else {
    lines.push("TRANSP:OPAQUE");
  }

  const privacy: string = event.privacy ?? "default";
  if (privacy !== "default") {
    lines.push(`CLASS:${privacy.toUpperCase()}`);
  }

  const status: string = event.eventStatus ?? "confirmed";
  if (status !== "confirmed") {
    lines.push(`STATUS:${status.toUpperCase()}`);
  } else {
    lines.push("STATUS:CONFIRMED");
  }

  if ((event.dueAt ?? 0) > 0) {
    lines.push(`DUE:${toUtcIcsDate(event.dueAt ?? 0)}`);
  }

  if ((event.completedAt ?? 0) > 0) {
    lines.push(`COMPLETED:${toUtcIcsDate(event.completedAt ?? 0)}`);
  }

  if ((event.priority ?? 0) > 0) {
    lines.push(`PRIORITY:${Math.min(9, Math.max(1, Math.floor(event.priority ?? 0)))}`);
  }

  if ((event.percentComplete ?? 0) > 0) {
    lines.push(`PERCENT-COMPLETE:${Math.min(100, Math.max(0, Math.floor(event.percentComplete ?? 0)))}`);
  }

  appendTextExtension(lines, "X-HARMONY-MILESTONE-STATUS", event.milestoneStatus ?? "");
  appendTextExtension(lines, "X-HARMONY-DUE-DATE-CLASS", event.dueDateClass ?? "");

  if ((event.eventKind ?? "calendar") === "appointment" || (event.appointmentStatus ?? "available") !== "available") {
    lines.push(`X-HARMONY-APPOINTMENT-STATUS:${event.appointmentStatus ?? "available"}`);
  }
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-CAPACITY", event.appointmentCapacity ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-BOOKED-COUNT", event.appointmentBookedCount ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-MIN-DURATION", event.appointmentMinDurationMinutes ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-MAX-DURATION", event.appointmentMaxDurationMinutes ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-BUFFER-BEFORE", event.appointmentBufferBeforeMinutes ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-BUFFER-AFTER", event.appointmentBufferAfterMinutes ?? 0);
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-DEADLINE", event.appointmentDeadlineMinutes ?? 0);
  appendTextExtension(lines, "X-HARMONY-APPOINTMENT-PUBLIC-URL", event.appointmentPublicUrl ?? "");
  appendTextExtension(lines, "X-HARMONY-APPOINTMENT-FORM-JSON", event.appointmentFormJson ?? "");
  appendTextExtension(lines, "X-HARMONY-APPOINTMENT-TIMEZONE", event.appointmentTimezone ?? "");
  appendNumberExtension(lines, "X-HARMONY-APPOINTMENT-SLOT-INTERVAL", event.appointmentSlotIntervalMinutes ?? 0);
  if (event.appointmentApprovalRequired === true) {
    lines.push("X-HARMONY-APPOINTMENT-APPROVAL-REQUIRED:TRUE");
  }
  appendTextExtension(lines, "X-HARMONY-BOOKING-JSON", event.bookingJson ?? "");
  appendTextExtension(lines, "X-HARMONY-BOOKING-CONTACT-NAME", event.bookingContactName ?? "");
  appendTextExtension(lines, "X-HARMONY-BOOKING-CONTACT-EMAIL", event.bookingContactEmail ?? "");
  appendTextExtension(lines, "X-HARMONY-BOOKING-CONTACT-PHONE", event.bookingContactPhone ?? "");
  appendTextExtension(lines, "X-HARMONY-BOOKING-CONFIRMATION-STATUS", event.bookingConfirmationStatus ?? "");
  appendTextExtension(lines, "X-HARMONY-BOOKING-STATUS", event.bookingStatus ?? "");

  appendTextExtension(lines, "X-HARMONY-GROUP-ID", event.groupId ?? "");
  appendTextExtension(lines, "X-HARMONY-DISPLAY-MODE", event.displayMode ?? "");
  if (event.overlap === false) {
    lines.push("X-HARMONY-OVERLAP:FALSE");
  }
  if (event.editable === false) {
    lines.push("X-HARMONY-EDITABLE:FALSE");
  }
  if (event.startEditable === false) {
    lines.push("X-HARMONY-START-EDITABLE:FALSE");
  }
  if (event.durationEditable === false) {
    lines.push("X-HARMONY-DURATION-EDITABLE:FALSE");
  }
  if (event.resourceEditable === false) {
    lines.push("X-HARMONY-RESOURCE-EDITABLE:FALSE");
  }
  if (event.interactive === false) {
    lines.push("X-HARMONY-INTERACTIVE:FALSE");
  }
  if (event.eventReadOnly === true) {
    lines.push("X-HARMONY-EVENT-READ-ONLY:TRUE");
  }
  if (event.isVisible === false) {
    lines.push("X-HARMONY-IS-VISIBLE:FALSE");
  }
  if (event.isPending === true) {
    lines.push("X-HARMONY-IS-PENDING:TRUE");
  }
  if (event.isFocused === true) {
    lines.push("X-HARMONY-IS-FOCUSED:TRUE");
  }
  appendNumberExtension(lines, "X-HARMONY-OVERLAP-POSITION", event.overlapPosition ?? 0);
  appendNumberExtension(lines, "X-HARMONY-OVERLAP-COUNT", event.overlapCount ?? 0);
  appendTextExtension(lines, "X-HARMONY-CLASS-NAMES", event.classNames ?? "");
  appendTextExtension(lines, "X-HARMONY-CUSTOM-STYLE-JSON", event.customStyleJson ?? "");
  appendTextExtension(lines, "X-HARMONY-CONSTRAINT-JSON", event.constraintJson ?? "");
  appendTextExtension(lines, "X-HARMONY-EXTENDED-PROPS-JSON", event.extendedPropsJson ?? "");
  appendPreservedIcsProperties(lines, event.rawPropsJson ?? "");
  appendTextExtension(lines, "X-HARMONY-RAW-PROPS-JSON", event.rawPropsJson ?? "");
  appendTextExtension(lines, "X-HARMONY-RESOURCE-IDS-JSON", event.resourceIdsJson ?? "");
  appendTextExtension(lines, "X-HARMONY-ROOM-IDS-JSON", event.roomIdsJson ?? "");
  appendTextExtension(lines, "X-HARMONY-RESOURCE-STATUS-JSON", event.resourceStatusJson ?? "");
  appendTextExtension(lines, "X-HARMONY-ALARM-ACTION", event.alarmAction ?? "");
  appendNumberExtension(lines, "X-HARMONY-SNOOZE-MINUTES", event.snoozeMinutes ?? 0);
  appendNumberExtension(lines, "X-HARMONY-SNOOZE-TIMES", event.snoozeTimes ?? 0);
  appendTextExtension(lines, "X-HARMONY-ALL-DAY-REMINDER-AT", event.allDayReminderAt ?? "");
  appendTextExtension(lines, "X-HARMONY-ALARM-ACTIONS-JSON", event.alarmActionsJson ?? "");

  reminderOffsets(event).forEach((minutes: number) => appendDisplayAlarm(lines, minutes));

  lines.push((event.eventKind ?? "calendar") === "task" ? "END:VTODO" : "END:VEVENT");
  lines.push("END:VCALENDAR");
  return `${lines.map(foldIcsLine).join("\r\n")}\r\n`;
};

export const buildIcsCalendar = (events: CalendarEventDraft[]): string => {
  const lines: string[] = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Harmony Calendar//ArkTS//CN",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH"
  ];

  events.forEach((event: CalendarEventDraft) => {
    const eventIcs: string = buildIcsEvent(event, createEventUid());
    const eventLines: string[] = unfoldIcsLines(eventIcs);
    const eventBlock: string[] = [];
    let inEvent: boolean = false;
    eventLines.forEach((line: string) => {
      if (line === "BEGIN:VEVENT" || line === "BEGIN:VTODO") {
        inEvent = true;
        eventBlock.push(line);
        return;
      }

      if (line === "END:VEVENT" || line === "END:VTODO") {
        eventBlock.push(line);
        inEvent = false;
        return;
      }

      if (inEvent) {
        eventBlock.push(line);
      }
    });
    eventBlock.forEach((line: string) => lines.push(line));
  });

  lines.push("END:VCALENDAR");
  return `${lines.map(foldIcsLine).join("\r\n")}\r\n`;
};

const unfoldIcsLines = (ics: string): string[] => {
  const rawLines: string[] = ics.replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
  const lines: string[] = [];

  rawLines.forEach((line: string) => {
    if ((line.startsWith(" ") || line.startsWith("\t")) && lines.length > 0) {
      lines[lines.length - 1] = `${lines[lines.length - 1]}${line.substring(1)}`;
    } else if (line.trim().length > 0) {
      lines.push(line);
    }
  });

  return lines;
};

const extractCalendarComponentBlocks = (lines: string[]): CalendarComponentBlock[] => {
  const blocks: CalendarComponentBlock[] = [];
  let eventLines: string[] = [];
  let componentKind: CalendarComponentKind = "VEVENT";
  let inEvent: boolean = false;

  lines.forEach((line: string) => {
    if (line === "BEGIN:VEVENT" || line === "BEGIN:VTODO") {
      inEvent = true;
      componentKind = line === "BEGIN:VTODO" ? "VTODO" : "VEVENT";
      eventLines = [];
      return;
    }

    if (line === "END:VEVENT" || line === "END:VTODO") {
      if (inEvent) {
        blocks.push({ kind: componentKind, lines: eventLines });
      }
      inEvent = false;
      return;
    }

    if (inEvent) {
      eventLines.push(line);
    }
  });

  return blocks;
};

const readDisplayAlarmTriggerMinutes = (eventLines: string[]): number[] => {
  const reminders: number[] = [];
  let inAlarm: boolean = false;
  let isDisplay: boolean = false;
  let trigger: string = "";

  for (let index = 0; index < eventLines.length; index += 1) {
    const line: string = eventLines[index];

    if (line === "BEGIN:VALARM") {
      inAlarm = true;
      isDisplay = false;
      trigger = "";
      continue;
    }

    if (line === "END:VALARM") {
      if (isDisplay && trigger.length > 0) {
        const minutes: number = parseTriggerMinutes(trigger);
        if (minutes > 0) {
          reminders.push(minutes);
        }
      }

      inAlarm = false;
      isDisplay = false;
      trigger = "";
      continue;
    }

    if (inAlarm) {
      const property: IcsProperty = parseProperty(line);
      if (property.name === "ACTION" && property.value.toUpperCase() === "DISPLAY") {
        isDisplay = true;
      } else if (property.name === "TRIGGER" && trigger.length === 0) {
        trigger = property.value;
      }
    }
  }

  return reminders;
};

const parseTriggerMinutes = (trigger: string): number => {
  const normalized: string = trigger.trim().toUpperCase();
  const match: RegExpMatchArray | null = normalized.match(/^([-+]?)P(?:T)?(?:(\d+)W)?(?:(\d+)D)?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/);

  if (match === null) {
    return 0;
  }

  const sign: string = match[1];
  const weeks: number = Number(match[2] ?? "0");
  const days: number = Number(match[3] ?? "0");
  const hours: number = Number(match[4] ?? "0");
  const minutes: number = Number(match[5] ?? "0");
  const seconds: number = Number(match[6] ?? "0");
  const totalMinutes: number = weeks * 7 * 24 * 60 + days * 24 * 60 + hours * 60 + minutes + Math.floor(seconds / 60);

  return sign === "-" ? totalMinutes : 0;
};

const parseProperty = (line: string): IcsProperty => {
  const separator: number = line.indexOf(":");
  const head: string = separator >= 0 ? line.substring(0, separator) : line;
  const value: string = separator >= 0 ? line.substring(separator + 1) : "";
  const semicolon: number = head.indexOf(";");

  return {
    name: (semicolon >= 0 ? head.substring(0, semicolon) : head).toUpperCase(),
    params: semicolon >= 0 ? head.substring(semicolon + 1).toUpperCase() : "",
    value
  };
};

const readPropertyObject = (properties: IcsProperty[], name: string): IcsProperty | null => {
  const normalized: string = name.toUpperCase();
  const found: IcsProperty | undefined = properties.find((property: IcsProperty) => property.name === normalized);
  return found ?? null;
};

const readProperty = (properties: IcsProperty[], name: string): string => readPropertyObject(properties, name)?.value ?? "";

const readProperties = (properties: IcsProperty[], name: string): IcsProperty[] => {
  const normalized: string = name.toUpperCase();
  return properties.filter((property: IcsProperty) => property.name === normalized);
};

const readAttendees = (properties: IcsProperty[]): string => {
  const emails: string[] = [];
  readProperties(properties, "ATTENDEE").forEach((property: IcsProperty) => {
    const email: string = property.value.replace(/^mailto:/i, "").trim();
    if (email.length > 0 && emails.indexOf(email) < 0) {
      emails.push(email);
    }
  });
  return emails.join(", ");
};

const readAttendeeJson = (properties: IcsProperty[]): string => {
  const attendees: CalendarAttendee[] = [];
  readProperties(properties, "ATTENDEE").forEach((property: IcsProperty) => {
    const email: string = property.value.replace(/^mailto:/i, "").trim();
    if (email.length === 0) {
      return;
    }
    attendees.push({
      email,
      name: readParamValue(property.params, "CN"),
      role: readParamValue(property.params, "ROLE"),
      status: readParamValue(property.params, "PARTSTAT"),
      rsvp: readParamValue(property.params, "RSVP").toUpperCase() === "TRUE",
      cutype: readParamValue(property.params, "CUTYPE")
    });
  });

  return attendees.length > 0 ? JSON.stringify(attendees) : "";
};

const readAttendeeResourceSummary = (properties: IcsProperty[]): AttendeeResourceSummary => {
  const resourceIds: string[] = [];
  const roomIds: string[] = [];
  const statusItems: Object[] = [];

  readProperties(properties, "ATTENDEE").forEach((property: IcsProperty) => {
    const cutype: string = readParamValue(property.params, "CUTYPE").toUpperCase();
    if (cutype !== "RESOURCE" && cutype !== "ROOM") {
      return;
    }

    const id: string = property.value.replace(/^mailto:/i, "").trim();
    if (id.length === 0) {
      return;
    }

    if (cutype === "ROOM") {
      appendUnique(roomIds, id);
    } else {
      appendUnique(resourceIds, id);
    }

    statusItems.push({
      id,
      type: cutype.toLowerCase(),
      name: readParamValue(property.params, "CN"),
      role: readParamValue(property.params, "ROLE"),
      status: readParamValue(property.params, "PARTSTAT"),
      rsvp: readParamValue(property.params, "RSVP").toUpperCase() === "TRUE"
    });
  });

  return {
    resourceIdsJson: resourceIds.length > 0 ? JSON.stringify(resourceIds) : "",
    roomIdsJson: roomIds.length > 0 ? JSON.stringify(roomIds) : "",
    resourceStatusJson: statusItems.length > 0 ? JSON.stringify(statusItems) : ""
  };
};

const readAttachmentJson = (properties: IcsProperty[]): string => {
  const attachments: Object[] = [];
  readProperties(properties, "ATTACH").forEach((property: IcsProperty) => {
    const url: string = property.value.trim();
    if (url.length === 0) {
      return;
    }

    attachments.push({
      url,
      valueType: readParamValue(property.params, "VALUE"),
      formatType: readParamValue(property.params, "FMTTYPE")
    });
  });
  return attachments.length > 0 ? JSON.stringify(attachments) : "";
};

const readRawPropsJson = (properties: IcsProperty[]): string => {
  const harmonyRaw: string = readProperty(properties, "X-HARMONY-RAW-PROPS-JSON");
  const preserved: PreservedIcsProperty[] = [];
  properties.forEach((property: IcsProperty) => {
    if (shouldPreserveRawProperty(property.name)) {
      preserved.push({
        name: property.name,
        params: property.params,
        value: property.value
      });
    }
  });

  if (preserved.length === 0) {
    return unescapeIcsText(harmonyRaw);
  }

  if (harmonyRaw.trim().length === 0) {
    return JSON.stringify(uniquePreservedIcsProperties(preserved));
  }

  try {
    const existing = JSON.parse(unescapeIcsText(harmonyRaw)) as PreservedIcsProperty[];
    if (!Array.isArray(existing)) {
      return JSON.stringify(uniquePreservedIcsProperties(preserved));
    }

    existing.forEach((item: PreservedIcsProperty) => {
      if (item.name !== undefined && item.value !== undefined) {
        preserved.push({
          name: `${item.name}`.toUpperCase(),
          params: item.params ?? "",
          value: item.value ?? ""
        });
      }
    });
    return JSON.stringify(uniquePreservedIcsProperties(preserved));
  } catch {
    return JSON.stringify(uniquePreservedIcsProperties(preserved));
  }
};

const uniquePreservedIcsProperties = (properties: PreservedIcsProperty[]): PreservedIcsProperty[] => {
  const items: PreservedIcsProperty[] = [];
  const keys: string[] = [];
  properties.forEach((property: PreservedIcsProperty) => {
    const name: string = `${property.name ?? ""}`.toUpperCase();
    const params: string = `${property.params ?? ""}`;
    const value: string = `${property.value ?? ""}`;
    const key: string = `${name};${params}:${value}`;
    if (name.length > 0 && value.length > 0 && keys.indexOf(key) < 0) {
      items.push({ name, params, value });
      keys.push(key);
    }
  });
  return items;
};

const shouldPreserveRawProperty = (name: string): boolean => {
  if (name === "X-HARMONY-RAW-PROPS-JSON") {
    return false;
  }

  return name.startsWith("X-APPLE-") || name.startsWith("X-MICROSOFT-") || name.startsWith("X-MS-") ||
    name.startsWith("X-GOOGLE-") || name.startsWith("X-MOZ-") || name.startsWith("X-NC-") ||
    name.startsWith("X-NEXTCLOUD-") || name.startsWith("X-WR-");
};

const readDateListProperties = (properties: IcsProperty[], name: string): string => {
  const values: string[] = [];
  readProperties(properties, name).forEach((property: IcsProperty) => {
    property.value.split(",").forEach((value: string) => {
      const trimmed: string = value.trim();
      if (trimmed.length > 0) {
        values.push(trimmed);
      }
    });
  });
  return values.join(",");
};

const readParamValue = (params: string, name: string): string => {
  const target: string = name.toUpperCase();
  const fields: string[] = params.split(";");
  for (const field of fields) {
    const separator: number = field.indexOf("=");
    if (separator > 0 && field.substring(0, separator).toUpperCase() === target) {
      return field.substring(separator + 1).replace(/^"|"$/g, "").trim();
    }
  }

  return "";
};

const readTzid = (params: string): string => {
  const fields: string[] = params.split(";");
  for (const field of fields) {
    const separator: number = field.indexOf("=");
    if (separator > 0 && field.substring(0, separator).toUpperCase() === "TZID") {
      return field.substring(separator + 1).trim();
    }
  }

  return "";
};

const parsePositiveInteger = (value: string): number => {
  const parsed: number = Number(value.trim());
  return Number.isInteger(parsed) && parsed > 0 ? parsed : 0;
};

const parseNonNegativeInteger = (value: string): number => {
  const parsed: number = Number(value.trim());
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : 0;
};

const parsePercentComplete = (value: string): number => {
  const parsed: number = parseNonNegativeInteger(value);
  return Math.min(100, Math.max(0, parsed));
};

const parseIcsDate = (value: string, allDay: boolean, params: string = ""): number => {
  const trimmed: string = value.trim();
  if (trimmed.length < 8) {
    return 0;
  }

  const dateOnly: boolean = allDay || params.indexOf("VALUE=DATE") >= 0 || /^\d{8}$/.test(trimmed);
  if (dateOnly) {
    const year: number = Number(trimmed.substring(0, 4));
    const month: number = Number(trimmed.substring(4, 6));
    const day: number = Number(trimmed.substring(6, 8));
    return new Date(year, month - 1, day).getTime();
  }

  const normalized: string = trimmed.endsWith("Z") ? trimmed.substring(0, trimmed.length - 1) : trimmed;
  const year: number = Number(normalized.substring(0, 4));
  const month: number = Number(normalized.substring(4, 6));
  const day: number = Number(normalized.substring(6, 8));
  const hour: number = Number(normalized.substring(9, 11));
  const minute: number = Number(normalized.substring(11, 13));
  const second: number = Number(normalized.substring(13, 15));

  if (trimmed.endsWith("Z")) {
    return Date.UTC(year, month - 1, day, hour, minute, second);
  }

  // TZID and floating date-times are kept as local wall-clock values for now.
  return new Date(year, month - 1, day, hour, minute, second).getTime();
};

const parseRecurrenceRule = (rrule: string, allDay: boolean): RecurrenceRule | null => {
  const fields: string[] = rrule.split(";");
  let freq: string = "";
  let interval: number = 1;
  let count: number = 0;
  let until: number = 0;

  fields.forEach((field: string) => {
    const separator: number = field.indexOf("=");
    if (separator < 0) {
      return;
    }

    const key: string = field.substring(0, separator).trim().toUpperCase();
    const value: string = field.substring(separator + 1).trim();
    const upperValue: string = value.toUpperCase();

    if (key === "FREQ") {
      freq = upperValue;
    } else if (key === "INTERVAL") {
      const parsed: number = Number(value);
      interval = Number.isInteger(parsed) && parsed > 0 ? parsed : 1;
    } else if (key === "COUNT") {
      const parsed: number = Number(value);
      count = Number.isInteger(parsed) && parsed > 0 ? parsed : 0;
    } else if (key === "UNTIL") {
      until = parseIcsDate(upperValue, allDay || /^\d{8}$/.test(upperValue), "");
    }
  });

  if (freq !== "DAILY" && freq !== "WEEKLY" && freq !== "MONTHLY" && freq !== "YEARLY") {
    return null;
  }

  return {
    freq,
    interval,
    count,
    until
  };
};

const addRecurrenceInterval = (timestamp: number, freq: string, interval: number): number => {
  const date = new Date(timestamp);
  if (freq === "DAILY") {
    date.setDate(date.getDate() + interval);
  } else if (freq === "WEEKLY") {
    date.setDate(date.getDate() + 7 * interval);
  } else if (freq === "MONTHLY") {
    date.setMonth(date.getMonth() + interval);
  } else if (freq === "YEARLY") {
    date.setFullYear(date.getFullYear() + interval);
  }

  return date.getTime();
};

const excludedOccurrenceDays = (value: string, allDay: boolean): number[] => {
  const days: number[] = [];
  value.split(/[,\n]/).forEach((part: string) => {
    const trimmed: string = part.trim();
    if (trimmed.length === 0) {
      return;
    }
    const timestamp: number = parseIcsDate(trimmed, allDay || /^\d{8}$/.test(trimmed), "");
    if (timestamp > 0) {
      const day: number = startOfDay(timestamp);
      if (days.indexOf(day) < 0) {
        days.push(day);
      }
    }
  });
  return days;
};

const buildOccurrenceEvent = (
  event: CalendarEvent,
  startAt: number,
  endAt: number,
  occurrenceIndex: number
): CalendarEvent => {
  if (occurrenceIndex === 0) {
    return event;
  }

	  return {
	    id: `${event.id}__harmony_recur_${occurrenceIndex}_${startAt}`,
	    sourceId: event.sourceId,
	    eventSourceId: event.eventSourceId,
    uid: event.uid,
    href: event.href,
    etag: event.etag,
    title: event.title,
    startAt,
    endAt,
    allDay: event.allDay,
    location: event.location,
    notes: event.notes,
    reminderMinutes: event.reminderMinutes,
    secondReminderMinutes: event.secondReminderMinutes,
    rrule: event.rrule,
    exdate: event.exdate,
    rdate: event.rdate,
    recurrenceId: event.recurrenceId,
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
};

const eventTouchesRange = (eventStart: number, eventEnd: number, rangeStart: number, rangeEnd: number): boolean =>
  eventStart < rangeEnd && eventEnd > rangeStart;

export const toUtcIcsDate = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${date.getUTCFullYear()}${pad2(date.getUTCMonth() + 1)}${pad2(date.getUTCDate())}T${pad2(date.getUTCHours())}${pad2(date.getUTCMinutes())}${pad2(date.getUTCSeconds())}Z`;
};

const toIcsLocalDateTime = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${date.getFullYear()}${pad2(date.getMonth() + 1)}${pad2(date.getDate())}T${pad2(date.getHours())}${pad2(date.getMinutes())}${pad2(date.getSeconds())}`;
};

const toIcsDateOnly = (timestamp: number): string => {
  const date = new Date(timestamp);
  return `${date.getFullYear()}${pad2(date.getMonth() + 1)}${pad2(date.getDate())}`;
};

const safeIcsParam = (value: string): string => value.replace(/[:;\r\n]/g, "").trim();

const appendDateListProperties = (lines: string[], name: string, value: string): void => {
  value.split(/[,\n]/).forEach((part: string) => {
    const trimmed: string = part.trim();
    if (trimmed.length > 0) {
      lines.push(`${name}:${trimmed}`);
    }
  });
};

const appendTextExtension = (lines: string[], name: string, value: string): void => {
  const trimmed: string = value.trim();
  if (trimmed.length > 0) {
    lines.push(`${name}:${escapeIcsText(trimmed)}`);
  }
};

const appendNumberExtension = (lines: string[], name: string, value: number): void => {
  const normalized: number = Math.floor(value);
  if (normalized > 0) {
    lines.push(`${name}:${normalized}`);
  }
};

const appendAttachmentJson = (lines: string[], attachmentsJson: string): void => {
  const trimmed: string = attachmentsJson.trim();
  if (trimmed.length === 0) {
    return;
  }

  try {
    const attachments: Object[] = JSON.parse(trimmed) as Object[];
    attachments.forEach((item: Object) => {
      const attachment = item as Record<string, string>;
      const url: string = (attachment["url"] ?? "").trim();
      if (url.length === 0) {
        return;
      }

      const formatType: string = (attachment["formatType"] ?? "").trim();
      const formatParam: string = formatType.length > 0 ? `;FMTTYPE=${safeIcsParam(formatType)}` : "";
      lines.push(`ATTACH;VALUE=URI${formatParam}:${url}`);
    });
  } catch {
    return;
  }
};

const appendResourceAttendees = (lines: string[], idsJson: string, cutype: string, statusJson: string): void => {
  const statuses: ResourceStatus[] = parseResourceStatusJson(statusJson);
  parseStringArrayJson(idsJson).forEach((id: string) => {
    const status: ResourceStatus | undefined = statuses.find((item: ResourceStatus) => item.id.toLowerCase() === id.toLowerCase());
    const name: string = status?.name !== undefined && status.name.length > 0 ? status.name : id;
    const role: string = status?.role !== undefined && status.role.length > 0 ? status.role : "REQ-PARTICIPANT";
    const partstat: string = status?.status !== undefined && status.status.length > 0 ? status.status : "NEEDS-ACTION";
    const rsvp: string = status?.rsvp === true ? ";RSVP=TRUE" : "";
    lines.push(
      `ATTENDEE;CN=${safeIcsParam(name)};ROLE=${safeIcsParam(role.toUpperCase())};CUTYPE=${safeIcsParam(cutype)};` +
        `PARTSTAT=${safeIcsParam(partstat.toUpperCase())}${rsvp}:mailto:${id}`
    );
  });
};

const appendPreservedIcsProperties = (lines: string[], rawPropsJson: string): void => {
  const trimmed: string = rawPropsJson.trim();
  if (trimmed.length === 0) {
    return;
  }

  try {
    const props = JSON.parse(trimmed) as PreservedIcsProperty[];
    if (!Array.isArray(props)) {
      return;
    }

    props.forEach((property: PreservedIcsProperty) => {
      const name: string = `${property.name ?? ""}`.toUpperCase().replace(/[^A-Z0-9-]/g, "");
      const params: string = `${property.params ?? ""}`.replace(/[\r\n]/g, "").trim();
      const value: string = `${property.value ?? ""}`.replace(/\r/g, "").replace(/\n/g, "\\n");
      if (shouldPreserveRawProperty(name) && value.length > 0) {
        lines.push(`${name}${params.length > 0 ? `;${params}` : ""}:${value}`);
      }
    });
  } catch {
    return;
  }
};

const appendDisplayAlarm = (lines: string[], minutes: number): void => {
  if (minutes <= 0) {
    return;
  }

  lines.push("BEGIN:VALARM");
  lines.push("ACTION:DISPLAY");
  lines.push(`TRIGGER:-PT${Math.floor(minutes)}M`);
  lines.push("DESCRIPTION:Reminder");
  lines.push("END:VALARM");
};

const normalizedAttendees = (value: string, attendeeJson: string): CalendarAttendee[] => {
  const attendees: CalendarAttendee[] = parseAttendeeJson(attendeeJson);
  const emails: string[] = attendees.map((attendee: CalendarAttendee) => attendee.email.toLowerCase());
  value.split(/[,\n;]/).forEach((part: string) => {
    const email: string = part.trim();
    if (email.length > 0 && emails.indexOf(email.toLowerCase()) < 0) {
      attendees.push({
        email,
        name: email,
        role: "REQ-PARTICIPANT",
        status: "NEEDS-ACTION",
        rsvp: true
      });
      emails.push(email.toLowerCase());
    }
  });
  return attendees;
};

const parseAttendeeJson = (value: string): CalendarAttendee[] => {
  const trimmed: string = value.trim();
  if (trimmed.length === 0) {
    return [];
  }

  try {
    const parsed = JSON.parse(trimmed) as CalendarAttendee[];
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed
      .filter((attendee: CalendarAttendee) => attendee.email !== undefined && attendee.email.trim().length > 0)
      .map((attendee: CalendarAttendee) => ({
        email: attendee.email.trim(),
        name: attendee.name ?? attendee.email.trim(),
        role: attendee.role ?? "REQ-PARTICIPANT",
        status: attendee.status ?? "NEEDS-ACTION",
        rsvp: attendee.rsvp === true,
        cutype: attendee.cutype ?? ""
      }));
  } catch {
    return [];
  }
};

interface ResourceStatus {
  readonly id: string;
  readonly type?: string;
  readonly name?: string;
  readonly role?: string;
  readonly status?: string;
  readonly rsvp?: boolean;
}

const parseStringArrayJson = (value: string): string[] => {
  const trimmed: string = value.trim();
  if (trimmed.length === 0) {
    return [];
  }

  try {
    const parsed = JSON.parse(trimmed) as string[];
    if (!Array.isArray(parsed)) {
      return [];
    }

    const items: string[] = [];
    parsed.forEach((item: string) => {
      const text: string = `${item}`.trim();
      appendUnique(items, text);
    });
    return items;
  } catch {
    return [];
  }
};

const parseResourceStatusJson = (value: string): ResourceStatus[] => {
  const trimmed: string = value.trim();
  if (trimmed.length === 0) {
    return [];
  }

  try {
    const parsed = JSON.parse(trimmed) as ResourceStatus[];
    if (!Array.isArray(parsed)) {
      return [];
    }
    return parsed.filter((item: ResourceStatus) => item.id !== undefined && item.id.trim().length > 0);
  } catch {
    return [];
  }
};

const appendUnique = (items: string[], value: string): void => {
  const trimmed: string = value.trim();
  if (trimmed.length > 0 && items.indexOf(trimmed) < 0) {
    items.push(trimmed);
  }
};

const reminderOffsets = (event: CalendarEventDraft): number[] => {
  const values: number[] = [];
  const append = (value: number): void => {
    if (value > 0 && values.indexOf(value) < 0) {
      values.push(value);
    }
  };

  (event.reminderOffsets ?? "").split(/[,\n;]/).forEach((part: string) => {
    const parsed: number = Number(part.trim());
    if (Number.isInteger(parsed)) {
      append(parsed);
    }
  });
  append(event.reminderMinutes ?? 0);
  append(event.secondReminderMinutes ?? 0);
  return values;
};

const escapeIcsText = (value: string): string =>
  value.replace(/\\/g, "\\\\").replace(/\n/g, "\\n").replace(/,/g, "\\,").replace(/;/g, "\\;");

const unescapeIcsText = (value: string): string =>
  value.replace(/\\n/g, "\n").replace(/\\,/g, ",").replace(/\\;/g, ";").replace(/\\\\/g, "\\");

const parseEventKind = (value: string):
  "calendar" | "important" | "reminder" | "task" | "focus" | "outOfOffice" | "workingLocation" | "appointment" => {
  const normalized: string = value.trim().toLowerCase();
  if (normalized === "important" || normalized === "reminder" || normalized === "task" || normalized === "focus" ||
    normalized === "appointment") {
    return normalized as "important" | "reminder" | "task" | "focus" | "appointment";
  }

  if (normalized === "outofoffice" || normalized === "out-of-office" || normalized === "out_of_office") {
    return "outOfOffice";
  }

  if (normalized === "workinglocation" || normalized === "working-location" || normalized === "working_location") {
    return "workingLocation";
  }

  return "calendar";
};

const parsePrivacy = (value: string): "default" | "public" | "private" | "confidential" => {
  const normalized: string = value.trim().toLowerCase();
  if (normalized === "public" || normalized === "private" || normalized === "confidential") {
    return normalized;
  }

  return "default";
};

const parseEventStatus = (value: string): "confirmed" | "tentative" | "cancelled" => {
  const normalized: string = value.trim().toLowerCase();
  if (normalized === "tentative" || normalized === "cancelled") {
    return normalized;
  }

  return "confirmed";
};

const parseAppointmentStatus = (value: string): "available" | "held" | "booked" | "cancelled" => {
  const normalized: string = value.trim().toLowerCase();
  if (normalized === "held" || normalized === "booked" || normalized === "cancelled") {
    return normalized;
  }

  return "available";
};

const foldIcsLine = (line: string): string => {
  if (line.length <= 72) {
    return line;
  }

  const chunks: string[] = [];
  let offset: number = 0;
  while (offset < line.length) {
    const size: number = offset === 0 ? 72 : 71;
    chunks.push(`${offset === 0 ? "" : " "}${line.substring(offset, offset + size)}`);
    offset += size;
  }

  return chunks.join("\r\n");
};

const pad2 = (value: number): string => value < 10 ? `0${value}` : `${value}`;
