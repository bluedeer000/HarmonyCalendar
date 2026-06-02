export interface CalendarProviderPreset {
  readonly providerType: string;
  readonly adapterType: string;
  readonly displayName: string;
  readonly serverUrl: string;
  readonly authHint: string;
  readonly discoveryHint: string;
  readonly supportsWellKnown: boolean;
  readonly discoveryPaths: string[];
  readonly authType: string;
  readonly capabilityHints: string[];
  /** 适配器能力的 JSON 描述，用于自动注册 */
  readonly adapterCapabilityJson?: string;
  /** 是否需要先自动发现集合再使用 */
  readonly discoveryRequired: boolean;
  /** 是否支持服务端创建日历集合 */
  readonly supportsCreateCollection: boolean;
  /** 读取策略 */
  readonly readStrategy: "fullSync" | "incremental" | "poll";
}

export const CALENDAR_PROVIDER_PRESETS: CalendarProviderPreset[] = [
  {
    providerType: "zoho",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "Zoho 日历",
    serverUrl: "https://calendar.zoho.com/.well-known/caldav",
    authHint: "使用 Zoho 用户名和应用专用密码",
    discoveryHint: "使用 .well-known/caldav 发现 principal 和 calendar-home-set",
    supportsWellKnown: true,
    discoveryPaths: ["/.well-known/caldav", "/caldav"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "VTODO", "sync-collection", "free-busy-query"]
  },
  {
    providerType: "icloud",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: false,
    readStrategy: "incremental",
    displayName: "iCloud 日历",
    serverUrl: "https://caldav.icloud.com",
    authHint: "使用 Apple ID 和应用专用密码",
    discoveryHint: "从 caldav.icloud.com 根地址发现个人日历集合",
    supportsWellKnown: false,
    discoveryPaths: ["/principals/", "/principals/{username}/", "/calendars/{username}/", "/"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "calendar-query"]
  },
  {
    providerType: "google",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: false,
    readStrategy: "fullSync",
    displayName: "Google 日历",
    serverUrl: "https://apidata.googleusercontent.com/caldav/v2/{username}/events",
    authHint: "Google 账号通常需要应用专用密码或账号策略允许的凭据",
    discoveryHint: "Google CalDAV 通常直接使用 /caldav/v2/{username}/events 集合地址",
    supportsWellKnown: false,
    discoveryPaths: ["/caldav/v2/{username}/events"],
    authType: "basic-app-password-or-policy",
    capabilityHints: ["VEVENT", "calendar-query"]
  },
  {
    providerType: "nextcloud",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "Nextcloud 日历",
    serverUrl: "",
    authHint: "通常填写 https://你的域名/remote.php/dav",
    discoveryHint: "可从 /remote.php/dav 发现 principal、home-set、共享权限和订阅能力",
    supportsWellKnown: true,
    discoveryPaths: ["/remote.php/dav", "/.well-known/caldav"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "VTODO", "sync-collection", "free-busy-query", "sharing"]
  },
  {
    providerType: "fastmail",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "Fastmail 日历",
    serverUrl: "https://caldav.fastmail.com/dav/calendars/user/{username}/",
    authHint: "使用 Fastmail 用户名和应用专用密码",
    discoveryHint: "Fastmail 可使用 user/{username}/ 或从根地址发现 calendar-home-set",
    supportsWellKnown: false,
    discoveryPaths: ["/dav/calendars/user/{username}/", "/dav/principals/user/{username}/"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "VTODO", "sync-collection"]
  },
  {
    providerType: "baikal",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "fullSync",
    displayName: "Baikal",
    serverUrl: "",
    authHint: "使用 Baikal 用户名和密码，常见路径为 /dav.php 或 /dav.php/calendars/账号/",
    discoveryHint: "Baikal 通常可从 /dav.php 发现 principal 和 calendars home-set",
    supportsWellKnown: true,
    discoveryPaths: ["/dav.php", "/dav.php/principals/{username}/", "/dav.php/calendars/{username}/"],
    authType: "basic",
    capabilityHints: ["VEVENT", "VTODO", "calendar-query"]
  },
  {
    providerType: "radicale",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "fullSync",
    displayName: "Radicale",
    serverUrl: "",
    authHint: "使用 Radicale 配置的用户名和密码，服务根地址通常就是 CalDAV 根",
    discoveryHint: "Radicale 支持根地址发现，也可直接填写具体 collection 地址",
    supportsWellKnown: true,
    discoveryPaths: ["/.well-known/caldav", "/{username}/", "/{username}/calendar/"],
    authType: "basic",
    capabilityHints: ["VEVENT", "VTODO", "calendar-query"]
  },
  {
    providerType: "sabre",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "SabreDAV",
    serverUrl: "",
    authHint: "使用 SabreDAV/自建服务账号密码，常见根路径为 /dav 或 /caldav",
    discoveryHint: "SabreDAV 通常按 DAV principal -> calendar-home-set 标准发现",
    supportsWellKnown: true,
    discoveryPaths: ["/.well-known/caldav", "/dav", "/caldav", "/principals/{username}/", "/calendars/{username}/"],
    authType: "basic",
    capabilityHints: ["VEVENT", "VTODO", "sync-collection", "calendar-query"]
  },
  {
    providerType: "owncloud",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "ownCloud",
    serverUrl: "",
    authHint: "使用 ownCloud 用户名和应用专用密码",
    discoveryHint: "ownCloud 通常从 /remote.php/dav 或 .well-known/caldav 发现日历",
    supportsWellKnown: true,
    discoveryPaths: ["/remote.php/dav", "/.well-known/caldav"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "VTODO", "sync-collection", "free-busy-query"]
  },
  {
    providerType: "yahoo",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: false,
    readStrategy: "fullSync",
    displayName: "Yahoo 日历",
    serverUrl: "https://caldav.calendar.yahoo.com",
    authHint: "使用 Yahoo 账号和应用专用密码",
    discoveryHint: "从 caldav.calendar.yahoo.com 根地址或 .well-known/caldav 发现日历集合",
    supportsWellKnown: true,
    discoveryPaths: ["/", "/.well-known/caldav", "/dav/{username}/Calendar/"],
    authType: "basic-app-password",
    capabilityHints: ["VEVENT", "calendar-query"]
  },
  {
    providerType: "custom",
    adapterType: "caldav",
    discoveryRequired: true,
    supportsCreateCollection: true,
    readStrategy: "incremental",
    displayName: "自定义 CalDAV",
    serverUrl: "",
    authHint: "填写服务商提供的 CalDAV 根地址或具体 calendar collection 地址",
    discoveryHint: "支持 .well-known、DAV principal、calendar-home-set 或直接 collection 地址",
    supportsWellKnown: true,
    discoveryPaths: [
      "/.well-known/caldav",
      "/dav",
      "/caldav",
      "/principals/{username}/",
      "/principals/users/{username}/",
      "/calendars/{username}/"
    ],
    authType: "basic-or-app-password",
    capabilityHints: ["VEVENT", "VTODO", "calendar-query", "free-busy-query"]
  }
];

export const providerPresetFor = (providerType: string): CalendarProviderPreset => {
  const found: CalendarProviderPreset | undefined = CALENDAR_PROVIDER_PRESETS.find((preset: CalendarProviderPreset) =>
    preset.providerType === providerType);
  return found ?? CALENDAR_PROVIDER_PRESETS[CALENDAR_PROVIDER_PRESETS.length - 1];
};

export const inferCalendarProviderType = (url: string): string => {
  const lower: string = url.toLowerCase();
  if (lower.indexOf("icloud.com") >= 0) {
    return "icloud";
  }
  if (lower.indexOf("googleusercontent.com") >= 0 || lower.indexOf("google.com") >= 0) {
    return "google";
  }
  if (lower.indexOf("zoho.") >= 0) {
    return "zoho";
  }
  if (lower.indexOf("/remote.php/dav") >= 0 || lower.indexOf("nextcloud") >= 0) {
    return "nextcloud";
  }
  if (lower.indexOf("fastmail") >= 0) {
    return "fastmail";
  }
  if (lower.indexOf("baikal") >= 0 || lower.indexOf("/dav.php") >= 0) {
    return "baikal";
  }
  if (lower.indexOf("radicale") >= 0) {
    return "radicale";
  }
  if (lower.indexOf("sabre") >= 0 || lower.endsWith("/dav") || lower.indexOf("/sabre/") >= 0) {
    return "sabre";
  }
  if (lower.indexOf("owncloud") >= 0) {
    return "owncloud";
  }
  if (lower.indexOf("yahoo") >= 0) {
    return "yahoo";
  }
  return "custom";
};

export const buildProviderPresetJson = (providerType: string, serverUrl: string): string =>
  JSON.stringify({
    providerType,
    serverUrl,
    authHint: providerPresetFor(providerType).authHint,
    discoveryHint: providerPresetFor(providerType).discoveryHint,
    supportsWellKnown: providerPresetFor(providerType).supportsWellKnown,
    discoveryPaths: providerPresetFor(providerType).discoveryPaths,
    authType: providerPresetFor(providerType).authType,
    capabilityHints: providerPresetFor(providerType).capabilityHints,
    standardDiscovery: JSON.stringify({
      currentUserPrincipal: true,
      calendarHomeSet: true,
      directCollection: true,
      fallbackGuessPaths: true
    })
  });

export const normalizeProviderServerUrl = (providerType: string, serverUrl: string, username: string): string => {
  const preset: CalendarProviderPreset = providerPresetFor(providerType);
  const trimmed: string = serverUrl.trim();
  const user: string = encodeURIComponent(username.trim());
  const fallback: string = preset.serverUrl.replace("{username}", user);

  if (providerType === "google") {
    if (trimmed.length === 0 || trimmed.indexOf("{username}") >= 0) {
      return fallback;
    }
    if (trimmed.endsWith("/caldav/v2/primary/events")) {
      return trimmed.replace("/primary/events", `/${user}/events`);
    }
    return trimmed;
  }

  if (providerType === "fastmail") {
    if (trimmed.length === 0 || trimmed.endsWith("/user/") || trimmed.indexOf("{username}") >= 0) {
      return fallback;
    }
    return trimmed;
  }

  if (providerType === "nextcloud" && trimmed.length > 0) {
    const withoutTrailing: string = trimmed.endsWith("/") ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (withoutTrailing.endsWith("/remote.php/dav")) {
      return withoutTrailing;
    }
    if (withoutTrailing.indexOf("/remote.php/") < 0 && withoutTrailing.indexOf("/dav") < 0) {
      return `${withoutTrailing}/remote.php/dav`;
    }
    return withoutTrailing;
  }

  if (providerType === "owncloud" && trimmed.length > 0) {
    const withoutTrailing: string = trimmed.endsWith("/") ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (withoutTrailing.endsWith("/remote.php/dav")) {
      return withoutTrailing;
    }
    if (withoutTrailing.indexOf("/remote.php/") < 0 && withoutTrailing.indexOf("/dav") < 0) {
      return `${withoutTrailing}/remote.php/dav`;
    }
    return withoutTrailing;
  }

  if (providerType === "baikal" && trimmed.length > 0) {
    const withoutTrailing: string = trimmed.endsWith("/") ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    if (withoutTrailing.indexOf("/dav.php") >= 0) {
      return withoutTrailing;
    }
    return `${withoutTrailing}/dav.php`;
  }

  if (providerType === "yahoo" && trimmed.length === 0) {
    return fallback;
  }

  if (trimmed.length > 0) {
    return trimmed;
  }

  return fallback;
};

export const providerDiagnosticHint = (providerType: string, message: string = ""): string => {
  const lower: string = message.toLowerCase();
  if (lower.indexOf("401") >= 0 || lower.indexOf("403") >= 0 || lower.indexOf("unauthorized") >= 0) {
    if (providerType === "icloud") {
      return "认证失败：iCloud 需要完整 Apple ID 邮箱和 Apple 账号生成的应用专用密码，不能使用 Apple ID 登录密码；如果刚修改过密码，请重新生成应用专用密码。";
    }
    if (providerType === "google") {
      return "认证失败：Google CalDAV 通常需要应用专用密码或组织策略允许的凭据。";
    }
    if (providerType === "zoho") {
      return "认证失败：Zoho 建议使用账号邮箱和应用专用密码。";
    }
    if (providerType === "yahoo") {
      return "认证失败：Yahoo CalDAV 通常需要账号邮箱和应用专用密码。";
    }
    return "认证失败：请确认用户名、应用专用密码和服务商 CalDAV 权限。";
  }

  if (lower.indexOf("404") >= 0 || lower.indexOf("not found") >= 0) {
    if (providerType === "nextcloud") {
      return "发现失败：Nextcloud 通常应填写 https://域名/remote.php/dav。";
    }
    if (providerType === "google") {
      return "发现失败：Google 地址通常为 https://apidata.googleusercontent.com/caldav/v2/账号/events。";
    }
    if (providerType === "baikal") {
      return "发现失败：Baikal 常见根地址是 https://域名/dav.php。";
    }
    if (providerType === "owncloud") {
      return "发现失败：ownCloud 通常应填写 https://域名/remote.php/dav。";
    }
    return "发现失败：请确认填写的是 CalDAV 根地址、.well-known/caldav 或具体 calendar collection。";
  }

  if (providerType === "fastmail") {
    return "Fastmail 建议使用应用专用密码；地址可用 caldav.fastmail.com/dav/calendars/user/账号/。";
  }
  if (providerType === "radicale") {
    return "Radicale 可填写服务根地址或具体 collection；若未发现，请检查服务端 rights/auth 配置。";
  }
  if (providerType === "sabre") {
    return "SabreDAV 自建服务通常支持 /dav、/caldav、principal 和 calendar-home-set 标准发现。";
  }
  return providerPresetFor(providerType).discoveryHint;
};

export const providerDiscoveryChecklist = (providerType: string, serverUrl: string, username: string): string => {
  const normalizedUrl: string = normalizeProviderServerUrl(providerType, serverUrl, username);
  const preset: CalendarProviderPreset = providerPresetFor(providerType);
  const user: string = encodeURIComponent(username.trim());
  const roots: string[] = [];
  appendUnique(roots, normalizedUrl);
  preset.discoveryPaths.forEach((path: string) => {
    const resolved: string = path.replace("{username}", user);
    if (resolved.indexOf("http://") === 0 || resolved.indexOf("https://") === 0) {
      appendUnique(roots, resolved);
      return;
    }
    const base: string = normalizedUrl.split("/").slice(0, 3).join("/");
    appendUnique(roots, `${base}${resolved.startsWith("/") ? resolved : `/${resolved}`}`);
  });

  return `标准 CalDAV 对接：1. 认证使用 ${preset.authType}；2. 先探测 current-user-principal；` +
    `3. 再读取 calendar-home-set；4. 枚举 calendar collection；5. 候选地址 ${roots.join(" | ")}`;
};

const appendUnique = (items: string[], value: string): void => {
  const trimmed: string = value.trim();
  if (trimmed.length === 0 || items.indexOf(trimmed) >= 0) {
    return;
  }
  items.push(trimmed);
};
