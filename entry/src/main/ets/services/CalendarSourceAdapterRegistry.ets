/**
 * CalendarSourceAdapterRegistry — 标准日历源适配器注册中心
 *
 * 管理所有日历源适配器的注册、查找和工厂创建。
 * 新增日历源类型只需 registerAdapter()，无需修改同步编排代码。
 *
 * 使用示例：
 *   const registry = CalendarSourceAdapterRegistry.getInstance();
 *   registry.registerAdapter(registration);          // 注册新适配器
 *   const adapter = registry.getAdapter(account);    // 获取对应的适配器
 *   const found = registry.findAdapter("caldav");    // 按类型查找
 */

import {
  AdapterCapability,
  AdapterRegistration,
  CalendarSourceAdapter,
  defaultDavCapability,
  defaultSubscriptionCapability
} from "./CalendarSourceAdapter";
import { CalDavSourceAdapter } from "./CalDavSourceAdapter";
import { SubscriptionSourceAdapter } from "./SubscriptionSourceAdapter";
import { CalendarAccount, CalendarSource } from "./CalendarTypes";
import { inferCalendarProviderType } from "./CalendarProviderPresets";

/* ===================================================================
 * 注册中心 — 单例
 * =================================================================== */

export class CalendarSourceAdapterRegistry {
  private static instance: CalendarSourceAdapterRegistry | null = null;
  private readonly registrations: Map<string, AdapterRegistration> = new Map();

  private constructor() {
    this.registerBuiltin();
  }

  /** 获取单例 */
  static getInstance(): CalendarSourceAdapterRegistry {
    if (CalendarSourceAdapterRegistry.instance === null) {
      CalendarSourceAdapterRegistry.instance = new CalendarSourceAdapterRegistry();
    }
    return CalendarSourceAdapterRegistry.instance;
  }

  /* -------- 注册 -------- */

  /** 注册一个新类型适配器 */
  registerAdapter(registration: AdapterRegistration): void {
    this.registrations.set(registration.type, registration);
  }

  /** 批量注册 */
  registerAdapters(registrations: AdapterRegistration[]): void {
    for (const reg of registrations) {
      this.registrations.set(reg.type, reg);
    }
  }

  /** 注销适配器 */
  unregisterAdapter(type: string): boolean {
    // 不注销内置类型
    if (type === "caldav" || type === "ics-subscription") {
      return false;
    }
    return this.registrations.delete(type);
  }

  /* -------- 查找 -------- */

  /** 按适配器类型字符串查找 */
  findAdapter(type: string): AdapterRegistration | undefined {
    return this.registrations.get(type);
  }

  /** 列出所有已注册的适配器 */
  listAdapters(): AdapterRegistration[] {
    const result: AdapterRegistration[] = [];
    this.registrations.forEach((reg: AdapterRegistration) => {
      result.push(reg);
    });
    return result;
  }

  /** 列出支持写入的适配器 */
  listWritableAdapters(): AdapterRegistration[] {
    return this.listAdapters().filter((reg: AdapterRegistration) => reg.capability.supportsWrite);
  }

  /** 列出支持自动发现的适配器 */
  listDiscoverableAdapters(): AdapterRegistration[] {
    return this.listAdapters().filter((reg: AdapterRegistration) => reg.capability.supportsDiscovery);
  }

  /* -------- 工厂 -------- */

  /**
   * 根据 CalendarAccount 获取适配器实例
   * 适配器类型优先级：account.providerType → infer 推断 → 默认 caldav
   */
  getAdapter(account: CalendarAccount): CalendarSourceAdapter {
    const adapterType: string = this.resolveAdapterType(account);
    const registration: AdapterRegistration | undefined = this.registrations.get(adapterType);
    if (registration === undefined) {
      console.warn(`CalendarSourceAdapterRegistry: 未找到适配器类型 "${adapterType}"，回退到 caldav`);
      return new CalDavSourceAdapter(account);
    }
    return registration.factory(account);
  }

  /**
   * 根据 CalendarSource 获取适配器实例
   * 先尝试用 source.providerAdapterType，再回退到 sourceType
   */
  getAdapterForSource(source: CalendarSource, fallbackAccount?: CalendarAccount): CalendarSourceAdapter {
    const adapterType: string = source.providerAdapterType?.length ?? 0 > 0
      ? (source.providerAdapterType ?? "")
      : source.sourceType === "caldav"
        ? "caldav"
        : source.sourceType === "subscription"
          ? "ics-subscription"
          : "caldav";

    const account: CalendarAccount = fallbackAccount ?? {
      serverUrl: source.collectionUrl,
      username: source.ownerEmail ?? "",
      password: "",
      displayName: source.name,
      providerType: source.providerType ?? "custom"
    };

    const registration: AdapterRegistration | undefined = this.registrations.get(adapterType);
    if (registration === undefined) {
      return new CalDavSourceAdapter(account);
    }
    return registration.factory(account);
  }

  /* -------- 内部 -------- */

  private resolveAdapterType(account: CalendarAccount): string {
    // 显式指定的 providerAdapterType 优先
    const accountMap: Record<string, Object> = JSON.parse(JSON.stringify(account));
    if (accountMap["providerAdapterType"] !== undefined) {
      return accountMap["providerAdapterType"] as string;
    }

    // 已知的 providerType
    const providerType: string = account.providerType ?? inferCalendarProviderType(account.serverUrl);
    if (providerType === "webcal" || providerType === "ics-subscription") {
      return "ics-subscription";
    }

    // 所有 CalDAV 提供者共用 caldav 适配器
    return "caldav";
  }

  private registerBuiltin(): void {
    // CalDAV 适配器（内置）
    this.registrations.set("caldav", {
      type: "caldav",
      displayName: "CalDAV",
      description: "支持所有标准 CalDAV 服务的通用适配器（Zoho、iCloud、Google、Nextcloud、自建等）",
      capability: defaultDavCapability(),
      factory: (account: CalendarAccount) => new CalDavSourceAdapter(account)
    });

    // ICS 订阅适配器（内置）
    this.registrations.set("ics-subscription", {
      type: "ics-subscription",
      displayName: "ICS 订阅",
      description: "只读的 iCalendar 订阅源适配器，支持 ETag / If-Modified-Since 条件请求",
      capability: defaultSubscriptionCapability(),
      factory: (_account: CalendarAccount) => new SubscriptionSourceAdapter(_account)
    });
  }
}
