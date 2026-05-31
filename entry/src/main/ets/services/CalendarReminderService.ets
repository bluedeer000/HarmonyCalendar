import { reminderAgentManager } from "@kit.BackgroundTasksKit";
import { notificationManager } from "@kit.NotificationKit";
import { CalendarEvent, CalendarReminderPreferences } from "./CalendarTypes";

const BUNDLE_NAME: string = "com.macto.harmonycalendar";
const ABILITY_NAME: string = "EntryAbility";

export class CalendarReminderService {
  async syncReminder(event: CalendarEvent, preferences?: CalendarReminderPreferences): Promise<number> {
    if ((event.reminderId ?? 0) > 0) {
      await this.cancelReminder(event.reminderId ?? 0);
    }

    const reminderMinutes: number = event.reminderMinutes ?? 0;
    const triggerAt: number = event.startAt - reminderMinutes * 60 * 1000;
    if (reminderMinutes <= 0 || triggerAt <= Date.now()) {
      return 0;
    }

    const date = new Date(triggerAt);
    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: date.getFullYear(),
        month: date.getMonth() + 1,
        day: date.getDate(),
        hour: date.getHours(),
        minute: date.getMinutes(),
        second: date.getSeconds()
      },
      title: event.title,
      content: event.location.length > 0 ? event.location : "日程即将开始",
      expiredContent: event.title,
      snoozeContent: event.title,
      notificationId: this.notificationId(event.id),
      groupId: event.id,
      slotType: this.slotType(preferences?.reminderSound ?? "default"),
      wantAgent: {
        pkgName: BUNDLE_NAME,
        abilityName: ABILITY_NAME
      },
      tapDismissed: true,
      ringDuration: this.ringDuration(preferences?.reminderSound ?? "default", preferences?.reminderVibrate !== false),
      snoozeTimes: this.snoozeTimes(event, preferences),
      timeInterval: this.snoozeInterval(event, preferences),
      snoozeSlotType: this.slotType(preferences?.reminderSound ?? "default")
    };

    return reminderAgentManager.publishReminder(request);
  }

  async cancelReminder(reminderId: number): Promise<void> {
    if (reminderId <= 0) {
      return;
    }

    try {
      await reminderAgentManager.cancelReminder(reminderId);
    } catch (error) {
      console.error(`Cancel reminder failed: ${this.describeError(error)}`);
    }
  }

  private notificationId(value: string): number {
    let hash: number = 0;
    for (let index = 0; index < value.length; index += 1) {
      hash = (hash * 31 + value.charCodeAt(index)) & 0x7fffffff;
    }

    return hash === 0 ? 1 : hash;
  }

  private slotType(sound: string): notificationManager.SlotType {
    return sound === "silent" ? notificationManager.SlotType.CONTENT_INFORMATION :
      notificationManager.SlotType.SOCIAL_COMMUNICATION;
  }

  private ringDuration(sound: string, vibrate: boolean): number {
    if (sound === "silent" && !vibrate) {
      return 0;
    }

    if (sound === "soft") {
      return 5;
    }

    return 30;
  }

  private snoozeTimes(event: CalendarEvent, preferences?: CalendarReminderPreferences): number {
    const value: number = event.snoozeTimes ?? preferences?.snoozeTimes ?? 0;
    return Math.max(0, Math.min(10, Math.floor(value)));
  }

  private snoozeInterval(event: CalendarEvent, preferences?: CalendarReminderPreferences): number {
    const value: number = event.snoozeMinutes ?? preferences?.snoozeMinutes ?? 0;
    return Math.max(0, Math.floor(value)) * 60;
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
}
