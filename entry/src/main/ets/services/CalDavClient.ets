import { http } from "@kit.NetworkKit";
import { util } from "@kit.ArkTS";
import { buildIcsEvent, hrefToId, normalizeCollectionUrl, normalizeServerUrl, parseIcsEvent, toUtcIcsDate } from "./CalendarFormat";
import { CalendarAccount, CalendarEvent, CalendarFreeBusySlot, CalendarSource } from "./CalendarTypes";
import { providerPresetFor } from "./CalendarProviderPresets";

export interface RemoteCalendarEvent {
  readonly uid: string;
  readonly href: string;
  readonly etag?: string;
  readonly ics: string;
}

export interface RemoteCalendarListResult {
  readonly events: RemoteCalendarEvent[];
  readonly failed: number;
  readonly total: number;
  readonly deletedHrefs?: string[];
  readonly syncToken?: string;
  readonly incremental?: boolean;
  readonly strategy?: string;
  readonly httpStatus?: number;
  readonly retryAfterSeconds?: number;
  readonly diagnosticJson?: string;
}

export class CalDavHttpError extends Error {
  readonly method: string;
  readonly url: string;
  readonly status: number;
  readonly hint: string;
  readonly retryAfterSeconds: number;
  readonly diagnostic: string;

  constructor(method: string, url: string, status: number, hint: string, retryAfterSeconds: number, diagnostic: string) {
    super(`CalDAV 返回 ${status}（${hint}）: ${diagnostic}`);
    this.method = method;
    this.url = url;
    this.status = status;
    this.hint = hint;
    this.retryAfterSeconds = retryAfterSeconds;
    this.diagnostic = diagnostic;
  }

  toDiagnosticJson(): string {
    return JSON.stringify({
      protocol: "caldav",
      method: this.method,
      url: this.url,
      httpStatus: this.status,
      hint: this.hint,
      retryAfterSeconds: this.retryAfterSeconds,
      diagnostic: this.diagnostic,
      checkedAt: Date.now()
    });
  }
}

interface CalDavRequestOptions {
  readonly method: string;
  readonly url: string;
  readonly body?: string;
  readonly headers?: HeaderMap;
}

export interface PutEventResult {
  readonly href: string;
  readonly etag: string;
}

export interface DiscoveredCalendarSource {
  readonly name: string;
  readonly description: string;
  readonly collectionUrl: string;
  readonly principalUrl: string;
  readonly homeSetUrl: string;
  readonly scheduleInboxUrl: string;
  readonly scheduleOutboxUrl: string;
  readonly calendarUserAddressSet: string;
  readonly ownerEmail: string;
  readonly color: string;
  readonly backgroundColor: string;
  readonly borderColor: string;
  readonly textColor: string;
  readonly isReadOnly: boolean;
  readonly permissionsJson: string;
  readonly supportedReportsJson: string;
  readonly supportedComponentsJson: string;
  readonly capabilitySource: string;
  readonly ctag: string;
  readonly syncToken: string;
}

export interface CalDavDiscoveryTrace {
  readonly directCollectionUrl: string;
  readonly directCollectionMatched: boolean;
  readonly optionsUrl: string;
  readonly davHeader: string;
  readonly allowHeader: string;
  readonly optionsError: string;
  readonly roots: string[];
  readonly principalUrls: string[];
  readonly homeSetUrls: string[];
  readonly sourceUrls: string[];
  readonly errors: string[];
}

interface CalendarObjectRef {
  readonly href: string;
  readonly requestHref?: string;
  readonly etag: string;
  readonly contentType: string;
  readonly deleted?: boolean;
  readonly componentName?: string;
}

interface CalendarObjectRefsResult {
  readonly refs: CalendarObjectRef[];
  readonly strategy: string;
}

interface CalendarDataRef {
  readonly href: string;
  readonly etag: string;
  readonly ics: string;
}

interface CalendarCollectionRef {
  readonly href: string;
  readonly ownerHref: string;
  readonly displayName: string;
  readonly description: string;
  readonly color: string;
  readonly isReadOnly: boolean;
  readonly privileges: string[];
  readonly ctag: string;
  readonly syncToken: string;
  readonly isCalendar: boolean;
  readonly supportsEvents: boolean;
  readonly supportsTasks: boolean;
  readonly supportedComponents: string[];
  readonly supportedReports: string[];
}

interface PrincipalCapabilities {
  readonly scheduleInboxUrl: string;
  readonly scheduleOutboxUrl: string;
  readonly calendarUserAddressSet: string;
  readonly supportedReportsJson: string;
}

interface DiscoveryCandidate {
  readonly principalUrl: string;
  readonly homeSetUrl: string;
}

export interface CalDavOptionsProbe {
  readonly url: string;
  readonly davHeader: string;
  readonly allowHeader: string;
  readonly status: number;
  readonly error: string;
}

interface HeaderMap {
  authorization?: string;
  accept?: string;
  depth?: string;
  contentType?: string;
  ifMatch?: string;
  ifNoneMatch?: string;
  userAgent?: string;
  custom?: Record<string, string>;
}

export class CalDavClient {
  private readonly account: CalendarAccount;
  private resolvedCollectionUrl: string = "";

  constructor(account: CalendarAccount, collectionUrl: string = "") {
    this.account = {
      id: account.id,
      displayName: account.displayName,
	      serverUrl: normalizeServerUrl(account.serverUrl),
	      username: account.username.trim(),
	      password: account.password,
	      authType: account.authType,
	      bearerToken: account.bearerToken,
	      customHeadersJson: account.customHeadersJson,
	      isActive: account.isActive,
	      providerType: account.providerType,
	      providerPresetJson: account.providerPresetJson
	    };
    this.resolvedCollectionUrl = collectionUrl.length > 0 ? normalizeCollectionUrl(collectionUrl) : "";
  }

  async discoverSources(): Promise<DiscoveredCalendarSource[]> {
    const directUrl: string = this.account.serverUrl;
    if (!isWellKnownCalDavUrl(directUrl)) {
      const directCollectionUrl: string = normalizeCollectionUrl(directUrl);
      try {
        if (await this.isCalendarCollectionUrl(directCollectionUrl)) {
          return [await this.readCalendarSource(directCollectionUrl)];
        }
      } catch (error) {
        console.error(`CalDAV direct collection discovery failed: ${this.describeError(error)}`);
      }
    }

	    const roots: string[] = this.discoveryRoots(directUrl);
	    const sources: DiscoveredCalendarSource[] = [];
	    for (const root of roots) {
	      let candidates: DiscoveryCandidate[] = [];
	      try {
	        candidates = await this.discoveryCandidates(root);
	      } catch (error) {
	        console.error(`CalDAV discovery candidates failed: root=${root}, reason=${this.describeError(error)}`);
	        continue;
	      }
	      for (const candidate of candidates) {
	        try {
	          const principalCapabilities: PrincipalCapabilities = candidate.principalUrl.length > 0 ?
	            await this.readPrincipalCapabilities(candidate.principalUrl) : emptyPrincipalCapabilities();
	          const found: DiscoveredCalendarSource[] = await this.findCalendarSources(
	            candidate.homeSetUrl,
	            candidate.principalUrl,
	            principalCapabilities
	          );
	          this.appendUniqueSources(sources, found);
	        } catch (error) {
	          console.error(`CalDAV source discovery failed: home=${candidate.homeSetUrl}, reason=${this.describeError(error)}`);
	        }
	      }
	    }

    if (sources.length > 0) {
      return sources;
    }

    for (const root of roots) {
      try {
        const found: DiscoveredCalendarSource[] = await this.findCalendarSources(root, "", emptyPrincipalCapabilities());
        this.appendUniqueSources(sources, found);
      } catch (error) {
        console.error(`CalDAV fallback discovery failed: root=${root}, reason=${this.describeError(error)}`);
      }
    }

    return sources;
  }

  async traceDiscovery(): Promise<CalDavDiscoveryTrace> {
    const directUrl: string = this.account.serverUrl;
    const directCollectionUrl: string = normalizeCollectionUrl(directUrl);
    const errors: string[] = [];
    const optionsProbe: CalDavOptionsProbe = await this.probeOptions(directUrl);
    let directCollectionMatched: boolean = false;
    if (!isWellKnownCalDavUrl(directUrl)) {
      try {
        directCollectionMatched = await this.isCalendarCollectionUrl(directCollectionUrl);
      } catch (error) {
        errors.push(`direct:${this.describeError(error)}`);
      }
    }

    const roots: string[] = this.discoveryRoots(directUrl);
    const principalUrls: string[] = [];
    const homeSetUrls: string[] = [];
    const sourceUrls: string[] = [];
    for (const root of roots) {
      try {
        const candidates: DiscoveryCandidate[] = await this.discoveryCandidates(root);
        candidates.forEach((candidate: DiscoveryCandidate) => {
          this.appendUniqueText(principalUrls, candidate.principalUrl);
          this.appendUniqueText(homeSetUrls, candidate.homeSetUrl);
        });
        for (const candidate of candidates) {
          try {
            const principalCapabilities: PrincipalCapabilities = candidate.principalUrl.length > 0 ?
              await this.readPrincipalCapabilities(candidate.principalUrl) : emptyPrincipalCapabilities();
            const found: DiscoveredCalendarSource[] = await this.findCalendarSources(
              candidate.homeSetUrl,
              candidate.principalUrl,
              principalCapabilities
            );
            found.forEach((source: DiscoveredCalendarSource) => this.appendUniqueText(sourceUrls, source.collectionUrl));
          } catch (error) {
            errors.push(`${candidate.homeSetUrl}:${this.describeError(error)}`);
          }
        }
      } catch (error) {
        errors.push(`${root}:${this.describeError(error)}`);
      }
    }

    return {
      directCollectionUrl,
      directCollectionMatched,
      optionsUrl: optionsProbe.url,
      davHeader: optionsProbe.davHeader,
      allowHeader: optionsProbe.allowHeader,
      optionsError: optionsProbe.error,
      roots,
      principalUrls,
      homeSetUrls,
      sourceUrls,
      errors
    };
  }

  withSource(source: CalendarSource): CalDavClient {
    return new CalDavClient(this.account, source.collectionUrl);
  }

  async listEvents(): Promise<RemoteCalendarEvent[]> {
    const result: RemoteCalendarListResult = await this.listEventsWithStatus();
    if (result.failed > 0) {
      throw new Error(`CalDAV 拉取对象失败 ${result.failed}/${result.total}`);
    }
    return result.events;
  }

	  async listEventsWithStatus(): Promise<RemoteCalendarListResult> {
	    const refsResult: CalendarObjectRefsResult = await this.listObjectRefsWithStrategy();
	    return this.fetchObjectsByRefs(refsResult.refs, refsResult.strategy);
	  }

		  async listEventsSinceSyncToken(syncToken: string): Promise<RemoteCalendarListResult> {
	    if (syncToken.trim().length === 0) {
	      return this.listEventsWithStatus();
	    }

	    const collectionUrl: string = await this.collectionUrl();
	    const body: string =
	      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
	      "<d:sync-collection xmlns:d=\"DAV:\">" +
	      `<d:sync-token>${escapeXml(syncToken.trim())}</d:sync-token>` +
	      "<d:sync-level>1</d:sync-level>" +
	      "<d:prop><d:getetag /><d:getcontenttype /></d:prop>" +
	      "</d:sync-collection>";
	    const response: http.HttpResponse = await this.request({
	      method: "REPORT",
	      url: collectionUrl,
	      body,
	      headers: {
	        depth: "1",
	        contentType: "application/xml; charset=utf-8"
	      }
	    });
	    const xml: string = this.responseText(response);
	    const refs: CalendarObjectRef[] = parseObjectRefs(xml, collectionUrl, "");
		    const deletedHrefs: string[] = [];
		    const changedRefs: CalendarObjectRef[] = [];

		    for (const ref of refs) {
		      if (ref.deleted === true) {
		        deletedHrefs.push(ref.href);
		        continue;
	      }

		      changedRefs.push(ref);
		    }

		    const fetched: RemoteCalendarListResult = await this.fetchObjectsByRefs(changedRefs, "sync-collection");

		    return {
		      events: fetched.events,
		      failed: fetched.failed,
		      total: changedRefs.length,
		      deletedHrefs,
		      syncToken: readXmlValue(xml, "sync-token"),
		      incremental: true,
		      strategy: fetched.strategy ?? "sync-collection"
		    };
		  }

  async resolveCollectionUrl(): Promise<string> {
    return this.collectionUrl();
  }

  async probeOptions(url: string = ""): Promise<CalDavOptionsProbe> {
    const targetUrl: string = url.trim().length > 0 ? url.trim() : this.account.serverUrl;
    try {
      const response: http.HttpResponse = await this.request({
        method: "OPTIONS",
        url: targetUrl,
        headers: {
          accept: "*/*"
        }
      });
      return {
        url: targetUrl,
        davHeader: this.readHeader(response, "dav"),
        allowHeader: this.readHeader(response, "allow"),
        status: response.responseCode,
        error: ""
      };
    } catch (error) {
      return {
        url: targetUrl,
        davHeader: "",
        allowHeader: "",
        status: 0,
        error: this.describeError(error)
      };
    }
  }

  async putEvent(event: CalendarEvent): Promise<PutEventResult> {
    const collectionUrl: string = await this.collectionUrl();
    const href: string = event.href.length > 0 ?
      event.href :
      `${collectionUrl}${encodeURIComponent(event.uid)}.ics`;
    const ics: string = buildIcsEvent(event, event.uid);
    const headers: HeaderMap = {
      contentType: "text/calendar; charset=utf-8"
    };

    if (event.etag.length > 0) {
      headers.ifMatch = event.etag;
    } else if (event.href.length === 0) {
      headers.ifNoneMatch = "*";
    }

    const response: http.HttpResponse = await this.request({
      method: "PUT",
      url: this.absoluteUrl(href),
      body: ics,
      headers
    });

    let etag: string = this.readHeader(response, "etag");
    if (etag.length === 0) {
      etag = await this.fetchCurrentEtag(href);
    }

    if (etag.length === 0) {
      console.error(`CalDAV PUT succeeded but no ETag returned for ${href}`);
    }

    return {
      href,
      etag: etag.length > 0 ? etag : event.etag
    };
  }

  async deleteEvent(event: CalendarEvent): Promise<void> {
    if (event.href.length === 0) {
      return;
    }

    await this.collectionUrl();
    const headers: HeaderMap = {};
    if (event.etag.length > 0) {
      headers.ifMatch = event.etag;
    }

    try {
      await this.request({
        method: "DELETE",
        url: this.absoluteUrl(event.href),
        headers
      });
    } catch (error) {
      const message: string = this.describeError(error);
      if (message.indexOf("404") < 0 && message.indexOf("410") < 0) {
        throw new Error(message);
      }
    }
	  }

  async getCurrentEvent(event: CalendarEvent): Promise<CalendarEvent | null> {
    const href: string = event.href.length > 0 ? event.href : `${await this.collectionUrl()}${encodeURIComponent(event.uid)}.ics`;
    try {
      const ics: string = await this.getObject(href);
      const etag: string = await this.fetchCurrentEtag(href);
      return parseIcsEvent(ics, href, etag.length > 0 ? etag : event.etag, hrefToId(href));
    } catch (error) {
      console.error(`CalDAV get current event failed: id=${event.id}, href=${href}, reason=${this.describeError(error)}`);
      return null;
    }
  }

  async queryFreeBusy(startAt: number, endAt: number, principalUrl: string = ""): Promise<CalendarFreeBusySlot[]> {
    const targetUrl: string = principalUrl.length > 0 ? principalUrl : await this.collectionUrl();
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<c:free-busy-query xmlns:c=\"urn:ietf:params:xml:ns:caldav\">" +
      `<c:time-range start=\"${toUtcIcsDate(startAt)}\" end=\"${toUtcIcsDate(endAt)}\" />` +
      "</c:free-busy-query>";
    const response: http.HttpResponse = await this.request({
      method: "REPORT",
      url: targetUrl,
      body,
      headers: {
        depth: "0",
        contentType: "application/xml; charset=utf-8",
        accept: "text/calendar"
      }
    });

    return parseFreeBusySlots(this.responseText(response));
  }

  async createCalendarCollection(homeSetUrl: string, displayName: string, color: string): Promise<DiscoveredCalendarSource> {
    const homeUrl: string = normalizeCollectionUrl(homeSetUrl.length > 0 ? homeSetUrl : await this.defaultCalendarHomeUrl());
    const slug: string = safeCollectionSlug(displayName);
    const collectionUrl: string = normalizeCollectionUrl(`${homeUrl}${slug}`);
    const attempts: string[][] = [["VEVENT", "VTODO"], ["VEVENT"]];
    let lastError: string = "";
    for (const components of attempts) {
      try {
        await this.mkCalendar(collectionUrl, displayName, color, components);
        const source: DiscoveredCalendarSource = await this.readCalendarSource(collectionUrl);
        if ((source.supportedComponentsJson ?? "").length > 0) {
          return source;
        }
        return { ...source, supportedComponentsJson: JSON.stringify(components) };
      } catch (error) {
        lastError = this.describeError(error);
        console.error(`CalDAV MKCALENDAR failed: url=${collectionUrl}, components=${components.join(",")}, reason=${lastError}`);
        if (!this.shouldRetryMkCalendarWithEventsOnly(lastError, components)) {
          break;
        }
      }
    }

    throw new Error(lastError.length > 0 ? lastError : "CalDAV 创建日历源失败");
  }

  private async mkCalendar(collectionUrl: string, displayName: string, color: string, components: string[]): Promise<void> {
    const componentXml: string = components.map((component: string) =>
      `<c:comp name="${escapeXml(component)}" />`).join("");
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<c:mkcalendar xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\" xmlns:cs=\"http://calendarserver.org/ns/\" xmlns:a=\"http://apple.com/ns/ical/\">" +
      "<d:set><d:prop>" +
      `<d:displayname>${escapeXml(displayName.trim().length > 0 ? displayName.trim() : "新日历")}</d:displayname>` +
      `<c:supported-calendar-component-set>${componentXml}</c:supported-calendar-component-set>` +
      `<a:calendar-color>${escapeXml(normalizeCalendarColor(color))}</a:calendar-color>` +
      "</d:prop></d:set>" +
      "</c:mkcalendar>";

    await this.request({
      method: "MKCALENDAR",
      url: collectionUrl,
      body,
      headers: {
        contentType: "application/xml; charset=utf-8"
      }
    });
  }

  private shouldRetryMkCalendarWithEventsOnly(reason: string, components: string[]): boolean {
    if (components.length <= 1 || components.indexOf("VTODO") < 0) {
      return false;
    }

    const lower: string = reason.toLowerCase();
    return lower.indexOf("vtodo") >= 0 ||
      lower.indexOf("supported-calendar-component-set") >= 0 ||
      lower.indexOf("component") >= 0 ||
      lower.indexOf("返回 400") >= 0 ||
      lower.indexOf("返回 403") >= 0 ||
      lower.indexOf("返回 409") >= 0 ||
      lower.indexOf("返回 415") >= 0 ||
      lower.indexOf("返回 501") >= 0;
  }

  async updateCalendarCollection(collectionUrl: string, displayName: string, color: string): Promise<DiscoveredCalendarSource> {
    const targetUrl: string = normalizeCollectionUrl(collectionUrl);
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<d:propertyupdate xmlns:d=\"DAV:\" xmlns:a=\"http://apple.com/ns/ical/\">" +
      "<d:set><d:prop>" +
      `<d:displayname>${escapeXml(displayName.trim().length > 0 ? displayName.trim() : "CalDAV 日历")}</d:displayname>` +
      `<a:calendar-color>${escapeXml(normalizeCalendarColor(color))}</a:calendar-color>` +
      "</d:prop></d:set>" +
      "</d:propertyupdate>";

    await this.request({
      method: "PROPPATCH",
      url: targetUrl,
      body,
      headers: {
        contentType: "application/xml; charset=utf-8"
      }
    });

    return this.readCalendarSource(targetUrl);
  }

  async deleteCalendarCollection(collectionUrl: string): Promise<void> {
    await this.request({
      method: "DELETE",
      url: normalizeCollectionUrl(collectionUrl)
    });
  }

  async grantCalendarAccess(collectionUrl: string, principal: string, role: string): Promise<void> {
    const targetUrl: string = normalizeCollectionUrl(collectionUrl);
    const principalHref: string = principal.indexOf("mailto:") === 0 || principal.indexOf("/") >= 0 ? principal : `mailto:${principal}`;
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<d:acl xmlns:d=\"DAV:\">" +
      "<d:ace>" +
      `<d:principal><d:href>${escapeXml(principalHref)}</d:href></d:principal>` +
      "<d:grant>" +
      "<d:privilege><d:read /></d:privilege>" +
      "<d:privilege><d:read-current-user-privilege-set /></d:privilege>" +
      (role === "write" ?
        "<d:privilege><d:write /></d:privilege>" +
          "<d:privilege><d:write-properties /></d:privilege>" +
          "<d:privilege><d:write-content /></d:privilege>" +
          "<d:privilege><d:bind /></d:privilege>" +
          "<d:privilege><d:unbind /></d:privilege>" : "") +
      "</d:grant>" +
      "</d:ace>" +
      "</d:acl>";

    await this.request({
      method: "ACL",
      url: targetUrl,
      body,
      headers: {
        contentType: "application/xml; charset=utf-8"
      }
    });
  }

  private async listObjectRefsWithStrategy(): Promise<CalendarObjectRefsResult> {
    try {
      const refs: CalendarObjectRef[] = await this.calendarQueryRefs();
      if (refs.length > 0) {
        return { refs, strategy: "calendar-query" };
      }
    } catch (error) {
      console.error(`CalDAV calendar-query refs failed, fallback to PROPFIND: ${this.describeError(error)}`);
    }

    return {
      refs: await this.propfindObjectRefs(),
      strategy: "propfind-depth1"
    };
  }

  private async calendarQueryRefs(): Promise<CalendarObjectRef[]> {
    const refs: CalendarObjectRef[] = [];
    const appendRefs = (items: CalendarObjectRef[]): void => {
      items.forEach((item: CalendarObjectRef) => {
        if (refs.find((existing: CalendarObjectRef) => existing.href === item.href) === undefined) {
          refs.push(item);
        }
      });
    };

    const components: string[] = await this.queryComponentNames();
    for (const component of components) {
      try {
        appendRefs(await this.calendarQueryRefsForComponent(component));
      } catch (error) {
        console.error(`CalDAV ${component} query refs failed, continue with remaining refs: ${this.describeError(error)}`);
      }
    }

    return refs;
  }

  private async queryComponentNames(): Promise<string[]> {
    if (this.resolvedCollectionUrl.length === 0) {
      return ["VEVENT", "VTODO"];
    }

    try {
      const source: DiscoveredCalendarSource = await this.readCalendarSource(this.resolvedCollectionUrl);
      const parsed: string[] = this.parseComponentJson(source.supportedComponentsJson);
      return parsed.length > 0 ? parsed : ["VEVENT", "VTODO"];
    } catch {
      return ["VEVENT", "VTODO"];
    }
  }

  private parseComponentJson(value: string): string[] {
    try {
      const parsed = JSON.parse(value) as Object[];
      if (!Array.isArray(parsed)) {
        return [];
      }
      const components: string[] = [];
      parsed.forEach((item: Object) => {
        const component: string = `${item}`.toUpperCase();
        if ((component === "VEVENT" || component === "VTODO") && components.indexOf(component) < 0) {
          components.push(component);
        }
      });
      return components;
    } catch {
      return [];
    }
  }

  private async calendarQueryRefsForComponent(componentName: string): Promise<CalendarObjectRef[]> {
    const collectionUrl: string = await this.collectionUrl();
    const safeComponentName: string = componentName.toUpperCase() === "VTODO" ? "VTODO" : "VEVENT";
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<c:calendar-query xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\">" +
      "<d:prop><d:getetag /><d:getcontenttype /></d:prop>" +
      `<c:filter><c:comp-filter name=\"VCALENDAR\"><c:comp-filter name=\"${safeComponentName}\" /></c:comp-filter></c:filter>` +
      "</c:calendar-query>";

    const response: http.HttpResponse = await this.request({
      method: "REPORT",
      url: collectionUrl,
      body,
      headers: {
        depth: "1",
        contentType: "application/xml; charset=utf-8"
      }
    });
    return parseObjectRefs(this.responseText(response), collectionUrl, safeComponentName).filter((item: CalendarObjectRef) => this.isCalendarObjectRef(item));
  }

	  private async propfindObjectRefs(): Promise<CalendarObjectRef[]> {
    const collectionUrl: string = await this.collectionUrl();
    const body: string =
      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<d:propfind xmlns:d=\"DAV:\">" +
      "<d:prop><d:getetag /><d:getcontenttype /><d:resourcetype /></d:prop>" +
      "</d:propfind>";

    const response: http.HttpResponse = await this.request({
      method: "PROPFIND",
      url: collectionUrl,
      body,
      headers: {
        depth: "1",
        contentType: "application/xml; charset=utf-8"
      }
    });
	    const raw: string = this.responseText(response);
	    return parseObjectRefs(raw, collectionUrl, "").filter((item: CalendarObjectRef) => this.isCalendarObjectRef(item));
	  }

	  private async fetchObjectsByRefs(refs: CalendarObjectRef[], baseStrategy: string): Promise<RemoteCalendarListResult> {
	    const events: RemoteCalendarEvent[] = [];
	    let failed: number = 0;

	    const multigetResult: RemoteCalendarListResult | null = await this.tryCalendarMultiget(refs);
	    if (multigetResult !== null) {
	      return { ...multigetResult, strategy: `${baseStrategy}+calendar-multiget` };
	    }

	    for (const ref of refs) {
	      try {
	        const ics: string = await this.getObject(ref.href);
	        const event: CalendarEvent | null = parseIcsEvent(ics, ref.href, ref.etag, hrefToId(ref.href));
	        if (event !== null) {
	          events.push({ event, ics });
	        }
	      } catch (error) {
	        failed += 1;
	        console.error(`CalDAV get object failed: ${this.describeError(error)}`);
	      }
	    }

	    return {
	      events,
	      failed,
	      total: refs.length,
	      strategy: `${baseStrategy}+object-get`
	    };
	  }

	  private async tryCalendarMultiget(refs: CalendarObjectRef[]): Promise<RemoteCalendarListResult | null> {
	    if (refs.length === 0) {
	      return null;
	    }

	    const batchSize: number = 100;
	    const events: RemoteCalendarEvent[] = [];
	    let failed: number = 0;
	    let hasSuccessfulBatch: boolean = false;

	    try {
	      for (let offset = 0; offset < refs.length; offset += batchSize) {
	        const batch: CalendarObjectRef[] = refs.slice(offset, offset + batchSize);
	        const batchResult: RemoteCalendarListResult | null = await this.tryCalendarMultigetBatch(batch);
	        if (batchResult === null) {
	          return null;
	        }
	        hasSuccessfulBatch = true;
	        batchResult.events.forEach((item: RemoteCalendarEvent) => events.push(item));
	        failed += batchResult.failed;
	      }

	      if (!hasSuccessfulBatch) {
	        return null;
	      }

	      return {
	        events,
	        failed,
	        total: refs.length,
	        strategy: "calendar-multiget"
	      };
    } catch (error) {
      console.error(`CalDAV calendar-multiget failed, fallback to object GET: ${this.describeError(error)}`);
	      return null;
	    }
	  }

	  private async tryCalendarMultigetBatch(refs: CalendarObjectRef[]): Promise<RemoteCalendarListResult | null> {
	    if (refs.length === 0) {
	      return null;
	    }

	    const collectionUrl: string = await this.collectionUrl();
	    const hrefs: string = refs.map((ref: CalendarObjectRef) => `<d:href>${escapeXml(ref.requestHref ?? ref.href)}</d:href>`).join("");
	    const body: string =
	      "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
	      "<c:calendar-multiget xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\">" +
	      "<d:prop><d:getetag /><c:calendar-data /></d:prop>" +
	      hrefs +
	      "</c:calendar-multiget>";

	    const response: http.HttpResponse = await this.request({
	      method: "REPORT",
	      url: collectionUrl,
	      body,
	      headers: {
	        depth: "1",
	        contentType: "application/xml; charset=utf-8"
	      }
	    });

	    const objects: RemoteCalendarEvent[] = [];
	    const returnedHrefs: string[] = [];
	    let failed: number = 0;
	    parseCalendarDataResponses(this.responseText(response), collectionUrl).forEach((item: CalendarDataRef) => {
	      returnedHrefs.push(item.href);
	      const event: CalendarEvent | null = parseIcsEvent(item.ics, item.href, item.etag, hrefToId(item.href));
	      if (event === null) {
	        failed += 1;
	        return;
	      }
	      objects.push({ event, ics: item.ics });
	    });

	    if (objects.length === 0 && refs.length > 0) {
	      return null;
	    }

	    refs.forEach((ref: CalendarObjectRef) => {
	      if (returnedHrefs.find((href: string) => this.sameHref(href, ref.href)) === undefined) {
	        failed += 1;
	      }
	    });

	    return {
	      events: objects,
	      failed,
	      total: refs.length,
	      strategy: "calendar-multiget"
	    };
	  }

  private async fetchCurrentEtag(href: string): Promise<string> {
    try {
      const response: http.HttpResponse = await this.request({
        method: "GET",
        url: this.absoluteUrl(href),
        headers: {
          accept: "text/calendar"
        }
      });
      const etag: string = this.readHeader(response, "etag");
      if (etag.length > 0) {
        return etag;
      }
    } catch (error) {
      console.error(`CalDAV fetch ETag by GET failed for ${href}: ${this.describeError(error)}`);
    }

    try {
      const body: string =
        "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
        "<d:propfind xmlns:d=\"DAV:\">" +
        "<d:prop><d:getetag /></d:prop>" +
        "</d:propfind>";
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url: this.absoluteUrl(href),
        body,
        headers: {
          depth: "0",
          contentType: "application/xml; charset=utf-8"
        }
      });
      const refs: CalendarObjectRef[] = parseObjectRefs(this.responseText(response), this.absoluteUrl(href), "");
      const found: CalendarObjectRef | undefined = refs.find((item: CalendarObjectRef) => this.sameHref(item.href, href));
      if (found !== undefined) {
        return found.etag;
      }
      return refs.length > 0 ? refs[0].etag : "";
    } catch (error) {
      console.error(`CalDAV fetch ETag by PROPFIND failed for ${href}: ${this.describeError(error)}`);
      return "";
    }
  }

  private async getObject(href: string): Promise<string> {
    const response: http.HttpResponse = await this.request({
      method: "GET",
      url: this.absoluteUrl(href),
      headers: {
        accept: "text/calendar"
      }
    });
    return this.responseText(response);
  }

  private async collectionUrl(): Promise<string> {
    if (this.resolvedCollectionUrl.length > 0) {
      return this.resolvedCollectionUrl;
    }

    this.resolvedCollectionUrl = await this.discoverCollectionUrl();
    return this.resolvedCollectionUrl;
  }

  private async discoverCollectionUrl(): Promise<string> {
    const sources: DiscoveredCalendarSource[] = await this.discoverSources();
    if (sources.length > 0) {
      return sources[0].collectionUrl;
    }

    const directUrl: string = this.account.serverUrl;
    console.error(`CalDAV discovery found no calendar collection, fallback to ${directUrl}`);
    return directUrl;
  }

  private async defaultCalendarHomeUrl(): Promise<string> {
    const sources: DiscoveredCalendarSource[] = await this.discoverSources();
    if (sources.length > 0 && sources[0].homeSetUrl.length > 0) {
      return sources[0].homeSetUrl;
    }

    const collection: string = await this.collectionUrl();
    const trimmed: string = collection.endsWith("/") ? collection.substring(0, collection.length - 1) : collection;
    const slash: number = trimmed.lastIndexOf("/");
    if (slash > "https://".length) {
      return normalizeCollectionUrl(trimmed.substring(0, slash + 1));
    }
    return normalizeCollectionUrl(collection);
  }

  private async isCalendarCollectionUrl(url: string): Promise<boolean> {
    try {
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url,
        body: this.buildPropfindBody("<d:resourcetype /><c:supported-calendar-component-set />"),
        headers: {
          depth: "0",
          contentType: "application/xml; charset=utf-8"
        }
      });
      return isCalendarCollectionBlock(this.responseText(response));
    } catch (error) {
      console.error(`CalDAV direct collection check failed for ${url}: ${this.describeError(error)}`);
      return false;
    }
  }

  private async readCurrentUserPrincipal(url: string): Promise<string> {
    try {
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url,
        body: this.buildPropfindBody("<d:current-user-principal />"),
        headers: {
          depth: "0",
          contentType: "application/xml; charset=utf-8"
        }
      });
      return readNestedHref(this.responseText(response), "current-user-principal");
    } catch (error) {
      console.error(`CalDAV current-user-principal discovery failed for ${url}: ${this.describeError(error)}`);
      return "";
    }
  }

  private async readCalendarHomeSet(principalUrl: string): Promise<string> {
    try {
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url: principalUrl,
        body: this.buildPropfindBody("<c:calendar-home-set />"),
        headers: {
          depth: "0",
          contentType: "application/xml; charset=utf-8"
        }
      });
      return readNestedHref(this.responseText(response), "calendar-home-set");
    } catch (error) {
      console.error(`CalDAV calendar-home-set discovery failed for ${principalUrl}: ${this.describeError(error)}`);
      return "";
    }
	  }

	  private async readPrincipalCapabilities(principalUrl: string): Promise<PrincipalCapabilities> {
	    try {
	      const response: http.HttpResponse = await this.request({
	        method: "PROPFIND",
	        url: principalUrl,
	        body: this.buildPropfindBody(
	          "<c:schedule-inbox-URL /><c:schedule-outbox-URL /><c:calendar-user-address-set /><d:supported-report-set />"
	        ),
	        headers: {
	          depth: "0",
	          contentType: "application/xml; charset=utf-8"
	        }
	      });
	      const xml: string = this.responseText(response);
	      return {
	        scheduleInboxUrl: resolveHref(readNestedHref(xml, "schedule-inbox-URL"), principalUrl),
	        scheduleOutboxUrl: resolveHref(readNestedHref(xml, "schedule-outbox-URL"), principalUrl),
        calendarUserAddressSet: readHrefSet(xml, "calendar-user-address-set").join(","),
        supportedReportsJson: JSON.stringify(readSupportedReports(xml))
      };
    } catch (error) {
      console.error(`CalDAV principal capabilities discovery failed for ${principalUrl}: ${this.describeError(error)}`);
	      return emptyPrincipalCapabilities();
	    }
	  }

	  private async discoveryCandidates(root: string): Promise<DiscoveryCandidate[]> {
	    const candidates: DiscoveryCandidate[] = [];
	    const append = (principalUrl: string, homeSetUrl: string): void => {
	      const normalizedHome: string = normalizeCollectionUrl(homeSetUrl);
	      if (normalizedHome.length === 0) {
	        return;
	      }

	      if (candidates.find((candidate: DiscoveryCandidate) => this.sameHref(candidate.homeSetUrl, normalizedHome)) === undefined) {
	        candidates.push({ principalUrl, homeSetUrl: normalizedHome });
	      }
	    };

	    const principalHref: string = await this.readCurrentUserPrincipal(root);
	    if (principalHref.length > 0) {
	      const principalUrl: string = resolveHref(principalHref, root);
	      const homeHref: string = await this.readCalendarHomeSet(principalUrl);
	      if (homeHref.length > 0) {
	        append(principalUrl, resolveHref(homeHref, principalUrl));
	      }
	    }

	    for (const principalUrl of this.guessPrincipalUrls(root)) {
	      const homeHref: string = await this.readCalendarHomeSet(principalUrl);
	      if (homeHref.length > 0) {
	        append(principalUrl, resolveHref(homeHref, principalUrl));
	      }
	    }

	    this.guessHomeSetUrls(root).forEach((homeSetUrl: string) => append("", homeSetUrl));
	    return candidates;
	  }

	  private async findCalendarSources(
    homeUrl: string,
    principalUrl: string,
    principalCapabilities: PrincipalCapabilities
  ): Promise<DiscoveredCalendarSource[]> {
    const normalizedHomeUrl: string = normalizeCollectionUrl(homeUrl);
    try {
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url: normalizedHomeUrl,
        body: this.buildPropfindBody(
          "<d:displayname /><d:owner /><c:calendar-description /><d:resourcetype /><d:getctag /><cs:getctag /><d:sync-token />" +
            "<c:supported-calendar-component-set /><c:calendar-color /><d:current-user-privilege-set /><d:supported-report-set />"
        ),
        headers: {
          depth: "1",
          contentType: "application/xml; charset=utf-8"
        }
      });
      const collections: CalendarCollectionRef[] = parseCalendarCollections(this.responseText(response), normalizedHomeUrl);
      return collections
        .filter((item: CalendarCollectionRef) => !this.sameHref(item.href, normalizedHomeUrl) && (item.supportsEvents || item.supportsTasks || item.isCalendar))
        .map((item: CalendarCollectionRef) => this.toDiscoveredSource(item, principalUrl, normalizedHomeUrl, principalCapabilities));
    } catch (error) {
      console.error(`CalDAV calendar collection discovery failed for ${normalizedHomeUrl}: ${this.describeError(error)}`);
      return [];
    }
  }

	  private discoveryRoots(url: string): string[] {
    const roots: string[] = [];
    const addServer = (value: string): void => {
      const normalized: string = normalizeServerUrl(value);
      if (normalized.length > 0 && roots.indexOf(normalized) < 0) {
        roots.push(normalized);
      }
    };
    const addCollection = (value: string): void => {
      const normalized: string = normalizeCollectionUrl(value);
      if (normalized.length > 0 && roots.indexOf(normalized) < 0) {
        roots.push(normalized);
      }
    };

    addServer(url);
    if (isWellKnownCalDavUrl(url)) {
      const origin: string = new URLParts(url).origin;
      if (origin.length > 0) {
        addCollection(`${origin}/`);
      }
      return roots;
    }

    let current: string = normalizeServerUrl(url);
    const origin: string = new URLParts(current).origin;
    while (current.length > origin.length + 1) {
      const withoutTrailing: string = current.endsWith("/") ? current.substring(0, current.length - 1) : current;
      const slash: number = withoutTrailing.lastIndexOf("/");
      if (slash <= origin.length) {
        break;
      }
      current = `${withoutTrailing.substring(0, slash)}/`;
      addCollection(current);
    }

    if (origin.length > 0) {
      addServer(`${origin}/.well-known/caldav`);
      addCollection(`${origin}/`);
      this.providerDiscoveryPaths(false).forEach((path: string) => {
        const resolved: string = this.resolvePresetRoot(new URLParts(origin), path);
        if (resolved.length > 0) {
          addServer(resolved);
          addCollection(resolved);
        }
      });
      this.providerDiscoveryPaths(true).forEach((path: string) => {
        const resolved: string = this.resolvePresetRoot(new URLParts(origin), path);
        if (resolved.length > 0) {
          addCollection(resolved);
        }
      });
    }

	    return roots;
	  }

	  private guessPrincipalUrls(root: string): string[] {
	    const urls: string[] = [];
	    const add = (value: string): void => {
	      const normalized: string = normalizeCollectionUrl(value);
	      if (normalized.length > 0 && urls.indexOf(normalized) < 0) {
	        urls.push(normalized);
	      }
	    };
	    const parts = new URLParts(root);
	    if (parts.origin.length === 0) {
	      return urls;
	    }

	    const user: string = encodeURIComponent(this.account.username.trim());
	    const emailName: string = encodeURIComponent(this.account.username.trim().split("@")[0]);
	    this.providerDiscoveryPaths(false).forEach((path: string) => {
	      const value: string = this.interpolateDiscoveryPath(path, user, emailName);
	      if (value.length > 0) {
	        add(`${parts.origin}${value}`);
	      }
	    });
	    [user, emailName].forEach((name: string) => {
	      if (name.length === 0) {
	        return;
	      }
	      add(`${parts.origin}/principals/${name}/`);
	      add(`${parts.origin}/principals/users/${name}/`);
	      add(`${parts.origin}/remote.php/dav/principals/users/${name}/`);
	      add(`${parts.origin}/dav/principals/users/${name}/`);
	      add(`${parts.origin}/dav.php/principals/${name}/`);
	      add(`${parts.origin}/dav.php/principals/users/${name}/`);
	      add(`${parts.origin}/caldav/principals/${name}/`);
	    });
	    return urls;
	  }

	  private guessHomeSetUrls(root: string): string[] {
	    const urls: string[] = [];
	    const add = (value: string): void => {
	      const normalized: string = normalizeCollectionUrl(value);
	      if (normalized.length > 0 && urls.indexOf(normalized) < 0) {
	        urls.push(normalized);
	      }
	    };
	    const parts = new URLParts(root);
	    if (parts.origin.length === 0) {
	      return urls;
	    }

	    const user: string = encodeURIComponent(this.account.username.trim());
	    const emailName: string = encodeURIComponent(this.account.username.trim().split("@")[0]);
	    this.providerDiscoveryPaths(true).forEach((path: string) => {
	      const value: string = this.interpolateDiscoveryPath(path, user, emailName);
	      if (value.length > 0) {
	        add(`${parts.origin}${value}`);
	      }
	    });
	    [user, emailName].forEach((name: string) => {
	      if (name.length === 0) {
	        return;
	      }
	      add(`${parts.origin}/calendars/${name}/`);
	      add(`${parts.origin}/dav/calendars/user/${name}/`);
	      add(`${parts.origin}/dav/calendars/users/${name}/`);
	      add(`${parts.origin}/caldav.php/${name}/`);
	      add(`${parts.origin}/remote.php/dav/calendars/${name}/`);
	      add(`${parts.origin}/dav.php/calendars/${name}/`);
	      add(`${parts.origin}/caldav/calendars/${name}/`);
	      add(`${parts.origin}/${name}/`);
	      add(`${parts.origin}/${name}/calendar/`);
	    });
	    return urls;
	  }

	  private providerDiscoveryPaths(homeOnly: boolean): string[] {
	    const providerType: string = this.account.providerType ?? "custom";
	    const presetPaths: string[] = providerPresetFor(providerType).discoveryPaths;
	    const rawPaths: string[] = this.providerPresetJsonPaths();
	    const paths: string[] = rawPaths.length > 0 ? rawPaths : presetPaths;
	    return paths.filter((path: string) => {
	      const lower: string = path.toLowerCase();
	      if (homeOnly) {
	        return lower.indexOf("calendar") >= 0 || lower.indexOf("caldav/v2") >= 0;
	      }
	      return lower.indexOf("principal") >= 0;
	    });
	  }

	  private providerPresetJsonPaths(): string[] {
	    const raw: string = this.account.providerPresetJson ?? "";
	    if (raw.trim().length === 0) {
	      return [];
	    }

	    try {
	      const parsed = JSON.parse(raw) as Record<string, Object>;
	      const value = parsed["discoveryPaths"];
	      if (!Array.isArray(value)) {
	        return [];
	      }
	      return value.map((item: Object) => `${item}`).filter((item: string) => item.length > 0);
	    } catch {
	      return [];
	    }
	  }

	  private interpolateDiscoveryPath(path: string, user: string, emailName: string): string {
	    const trimmed: string = path.trim();
	    if (trimmed.length === 0) {
	      return "";
	    }

	    const withSlash: string = trimmed.startsWith("/") ? trimmed : `/${trimmed}`;
	    return withSlash.replace(/\{username\}/g, user).replace(/\{emailName\}/g, emailName);
	  }

	  private resolvePresetRoot(parts: URLParts, path: string): string {
	    const user: string = encodeURIComponent(this.account.username.trim());
	    const emailName: string = encodeURIComponent(this.account.username.trim().split("@")[0]);
	    const value: string = this.interpolateDiscoveryPath(path, user, emailName);
	    if (value.length === 0 || parts.origin.length === 0) {
	      return "";
	    }
	    if (value.indexOf("http://") === 0 || value.indexOf("https://") === 0) {
	      return value;
	    }
	    return `${parts.origin}${value}`;
	  }

	  private buildPropfindBody(props: string): string {
    return "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
      "<d:propfind xmlns:d=\"DAV:\" xmlns:c=\"urn:ietf:params:xml:ns:caldav\" xmlns:cs=\"http://calendarserver.org/ns/\">" +
      `<d:prop>${props}</d:prop>` +
      "</d:propfind>";
  }

  private async readCalendarSource(collectionUrl: string): Promise<DiscoveredCalendarSource> {
    try {
      const response: http.HttpResponse = await this.request({
        method: "PROPFIND",
        url: collectionUrl,
        body: this.buildPropfindBody(
          "<d:displayname /><d:owner /><c:calendar-description /><d:resourcetype /><d:getctag /><cs:getctag /><d:sync-token />" +
            "<c:supported-calendar-component-set /><c:calendar-color /><d:current-user-privilege-set /><d:supported-report-set />"
        ),
        headers: {
          depth: "0",
          contentType: "application/xml; charset=utf-8"
        }
      });
      const collections: CalendarCollectionRef[] = parseCalendarCollections(this.responseText(response), collectionUrl);
      if (collections.length > 0) {
        return this.toDiscoveredSource(collections[0], "", "", emptyPrincipalCapabilities());
      }
    } catch (error) {
      console.error(`CalDAV source metadata read failed for ${collectionUrl}: ${this.describeError(error)}`);
    }

    return {
      name: this.account.displayName ?? "CalDAV 日历",
      description: "",
      collectionUrl: normalizeCollectionUrl(collectionUrl),
      principalUrl: "",
      homeSetUrl: "",
      scheduleInboxUrl: "",
      scheduleOutboxUrl: "",
      calendarUserAddressSet: "",
      ownerEmail: this.account.username.indexOf("@") > 0 ? this.account.username : "",
      color: "#2563EB",
      backgroundColor: "#2563EB",
      borderColor: "#2563EB",
      textColor: "#FFFFFF",
      isReadOnly: false,
      permissionsJson: "",
      supportedReportsJson: JSON.stringify(this.providerCapabilityHints(false)),
      supportedComponentsJson: JSON.stringify(this.providerCapabilityHints(true)),
      capabilitySource: "provider-hint",
      ctag: "",
      syncToken: ""
    };
  }

  private toDiscoveredSource(
    ref: CalendarCollectionRef,
    principalUrl: string,
    homeSetUrl: string,
    principalCapabilities: PrincipalCapabilities
  ): DiscoveredCalendarSource {
    const color: string = normalizeCalendarColor(ref.color);
    const hasServerReports: boolean = ref.supportedReports.length > 0;
    const hasServerComponents: boolean = ref.supportedComponents.length > 0;
    const hasPrincipalReports: boolean = principalCapabilities.supportedReportsJson.length > 0;
    return {
      name: ref.displayName.length > 0 ? ref.displayName : this.collectionName(ref.href),
      description: ref.description,
      collectionUrl: normalizeCollectionUrl(ref.href),
      principalUrl,
      homeSetUrl,
      scheduleInboxUrl: principalCapabilities.scheduleInboxUrl,
      scheduleOutboxUrl: principalCapabilities.scheduleOutboxUrl,
      calendarUserAddressSet: principalCapabilities.calendarUserAddressSet,
      ownerEmail: this.ownerEmail(ref, principalCapabilities),
      color,
      backgroundColor: color,
      borderColor: color,
      textColor: readableTextColor(color),
      isReadOnly: ref.isReadOnly,
      permissionsJson: ref.privileges.join(","),
      supportedReportsJson: ref.supportedReports.length > 0 ? JSON.stringify(ref.supportedReports) :
        (principalCapabilities.supportedReportsJson.length > 0 ? principalCapabilities.supportedReportsJson : JSON.stringify(this.providerCapabilityHints(false))),
      supportedComponentsJson: ref.supportedComponents.length > 0 ? JSON.stringify(ref.supportedComponents) :
        JSON.stringify(this.providerCapabilityHints(true)),
      capabilitySource: hasServerReports || hasServerComponents ? "server-propfind" : (hasPrincipalReports ? "principal-propfind" : "provider-hint"),
      ctag: ref.ctag,
      syncToken: ref.syncToken
    };
  }

  private providerCapabilityHints(componentsOnly: boolean): string[] {
    const providerType: string = this.account.providerType ?? "custom";
    const hints: string[] = providerPresetFor(providerType).capabilityHints;
    const result: string[] = [];
    hints.forEach((hint: string) => {
      const normalized: string = this.normalizeCapabilityHint(hint, componentsOnly);
      if (normalized.length === 0) {
        return;
      }
      if (result.indexOf(normalized) < 0) {
        result.push(normalized);
      }
    });
    return result;
  }

  private normalizeCapabilityHint(hint: string, componentsOnly: boolean): string {
    const normalized: string = hint.trim();
    const upper: string = normalized.toUpperCase();
    if (componentsOnly) {
      return upper === "VEVENT" || upper === "VTODO" ? upper : "";
    }

    const lower: string = normalized.toLowerCase();
    const reports: string[] = ["calendar-query", "calendar-multiget", "free-busy-query", "sync-collection", "expand-property"];
    return reports.indexOf(lower) >= 0 ? lower : "";
  }

  private ownerEmail(ref: CalendarCollectionRef, principalCapabilities: PrincipalCapabilities): string {
    const values: string[] = [ref.ownerHref, principalCapabilities.calendarUserAddressSet, ref.href];
    for (const value of values) {
      const decoded: string = decodeURIComponentSafe(value);
      const match: RegExpMatchArray | null = decoded.match(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/i);
      if (match !== null) {
        return match[0];
      }
    }

    return "";
  }

  private appendUniqueSources(target: DiscoveredCalendarSource[], sourceItems: DiscoveredCalendarSource[]): void {
    sourceItems.forEach((source: DiscoveredCalendarSource) => {
      if (target.find((item: DiscoveredCalendarSource) => this.sameHref(item.collectionUrl, source.collectionUrl)) === undefined) {
        target.push(source);
      }
    });
  }

  private appendUniqueText(target: string[], value: string): void {
    const trimmed: string = value.trim();
    if (trimmed.length > 0 && target.indexOf(trimmed) < 0) {
      target.push(trimmed);
    }
  }

  private collectionName(url: string): string {
    const normalized: string = normalizeCollectionUrl(url);
    const trimmed: string = normalized.endsWith("/") ? normalized.substring(0, normalized.length - 1) : normalized;
    const slash: number = trimmed.lastIndexOf("/");
    const name: string = slash >= 0 ? trimmed.substring(slash + 1) : trimmed;
    return name.length > 0 ? decodeURIComponentSafe(name) : "CalDAV 日历";
  }

  private async request(options: CalDavRequestOptions, redirectCount: number = 0): Promise<http.HttpResponse> {
    const request = http.createHttp();
    const headers: HeaderMap = this.mergeHeaders(options.headers);

    try {
      const response: http.HttpResponse = await request.request(options.url, {
        method: options.method as http.RequestMethod,
        connectTimeout: 15000,
        readTimeout: 20000,
        header: this.toHttpHeaders(headers),
        extraData: options.body
      });

      if (this.isRedirectStatus(response.responseCode)) {
        const location: string = this.readHeader(response, "location");
        if (location.length > 0 && redirectCount < 5) {
          return await this.request({
            method: options.method,
            url: resolveHref(location, options.url),
            body: options.body,
            headers: options.headers
          }, redirectCount + 1);
        }
      }

	      if (response.responseCode < 200 || response.responseCode >= 300) {
	        throw new CalDavHttpError(
	          options.method,
	          options.url,
	          response.responseCode,
	          this.statusHint(response.responseCode),
	          this.retryAfterSeconds(response),
	          this.responseDiagnostic(response)
	        );
	      }

      return response;
    } catch (error) {
      if (error instanceof CalDavHttpError) {
        throw error;
      }
      throw new Error(`${options.method} ${options.url} 失败：${this.describeError(error)}`);
    } finally {
      request.destroy();
    }
  }

  private isRedirectStatus(code: number): boolean {
    return code === 301 || code === 302 || code === 303 || code === 307 || code === 308;
  }

  private absoluteUrl(href: string): string {
    return resolveHref(href, this.resolvedCollectionUrl.length > 0 ? this.resolvedCollectionUrl : this.account.serverUrl);
  }

	  private isCalendarObjectRef(ref: CalendarObjectRef): boolean {
	    if ((ref.componentName ?? "").length > 0) {
	      return true;
	    }

	    if (ref.href.endsWith(".ics")) {
	      return true;
	    }

    return ref.contentType.toLowerCase().indexOf("text/calendar") >= 0;
  }

  private sameHref(left: string, right: string): boolean {
    return this.absoluteUrl(left) === this.absoluteUrl(right);
  }

	  private mergeHeaders(extra?: HeaderMap): HeaderMap {
    const headers: HeaderMap = {
      accept: "*/*",
      userAgent: "HarmonyCalendar/1.0 CalDAV",
      custom: {}
    };

	    const authorization: string = this.authorizationHeader();
	    if (authorization.length > 0) {
	      headers.authorization = authorization;
	    }

    if (extra !== undefined) {
      if (extra.accept !== undefined) {
        headers.accept = extra.accept;
      }
      if (extra.depth !== undefined) {
        headers.depth = extra.depth;
      }
      if (extra.contentType !== undefined) {
        headers.contentType = extra.contentType;
      }
      if (extra.ifMatch !== undefined) {
        headers.ifMatch = extra.ifMatch;
      }
      if (extra.ifNoneMatch !== undefined) {
        headers.ifNoneMatch = extra.ifNoneMatch;
      }
      if (extra.userAgent !== undefined) {
        headers.userAgent = extra.userAgent;
      }
    }

	    return this.applyCustomHeaders(headers);
	  }

  private toHttpHeaders(headers: HeaderMap): Object {
    const output: Record<string, string> = {};
    if (headers.authorization !== undefined) {
      output["authorization"] = headers.authorization;
    }
    if (headers.accept !== undefined) {
      output["accept"] = headers.accept;
    }
    if (headers.depth !== undefined) {
      output["depth"] = headers.depth;
    }
    if (headers.contentType !== undefined) {
      output["content-type"] = headers.contentType;
    }
    if (headers.ifMatch !== undefined) {
      output["if-match"] = headers.ifMatch;
    }
    if (headers.ifNoneMatch !== undefined) {
      output["if-none-match"] = headers.ifNoneMatch;
    }
    if (headers.userAgent !== undefined) {
      output["user-agent"] = headers.userAgent;
    }
    Object.keys(headers.custom ?? {}).forEach((key: string) => {
      const name: string = key.trim().toLowerCase();
      const value: string = (headers.custom ?? {})[key];
      if (name.length > 0 && value.length > 0 && !this.isBlockedCustomHeader(name)) {
        output[name] = value;
      }
    });
    return output;
  }

	  private basicAuth(): string {
	    const bytes: Uint8Array = util.TextEncoder.create("utf-8").encodeInto(`${this.account.username}:${this.account.password}`) ?? new Uint8Array();
	    const helper = new util.Base64Helper();
	    return helper.encodeToStringSync(bytes, util.Type.BASIC);
	  }

	  private authorizationHeader(): string {
	    const authType: string = this.account.authType ?? "basic";
	    if (authType === "none" || authType === "custom") {
	      return "";
	    }
	    if (authType === "bearer") {
	      const token: string = (this.account.bearerToken ?? this.account.password).trim();
	      return token.length > 0 ? `Bearer ${token}` : "";
	    }
	    return `Basic ${this.basicAuth()}`;
	  }

		  private applyCustomHeaders(headers: HeaderMap): HeaderMap {
	    const raw: string = this.account.customHeadersJson ?? "";
	    if (raw.trim().length === 0) {
	      return headers;
	    }

	    try {
	      const parsed = JSON.parse(raw) as Record<string, string>;
		      Object.keys(parsed).forEach((key: string) => {
		        const normalized: string = key.trim().toLowerCase();
		        const value: string = `${parsed[key] ?? ""}`.trim();
		        if (value.length === 0) {
		          return;
		        }
	        if (normalized === "authorization") {
	          headers.authorization = value;
	        } else if (normalized === "accept") {
	          headers.accept = value;
		        } else if (normalized === "user-agent") {
		          headers.userAgent = value;
		        } else if (!this.isBlockedCustomHeader(normalized)) {
		          const customHeaders: Record<string, string> = headers.custom ?? {};
		          customHeaders[normalized] = value;
		          headers.custom = customHeaders;
		        }
		      });
	    } catch {
	      return headers;
	    }

	    return headers;
	  }

	  private isBlockedCustomHeader(name: string): boolean {
	    return name === "host" || name === "content-length" || name === "connection" || name === "transfer-encoding";
	  }

  private responseText(response: http.HttpResponse): string {
    if (typeof response.result === "string") {
      return response.result;
    }

    return JSON.stringify(response.result);
  }

	  private responseDiagnostic(response: http.HttpResponse): string {
	    const body: string = this.responseText(response).replace(/\s+/g, " ").substring(0, 220);
	    const auth: string = this.readHeader(response, "www-authenticate");
	    const dav: string = this.readHeader(response, "dav");
	    const contentType: string = this.readHeader(response, "content-type");
	    const location: string = this.readHeader(response, "location");
	    const retryAfter: string = this.readHeader(response, "retry-after");
	    const parts: string[] = [];
	    if (location.length > 0) {
	      parts.push(`location=${location}`);
	    }
	    if (retryAfter.length > 0) {
	      parts.push(`retry-after=${retryAfter}`);
	    }
    if (auth.length > 0) {
      parts.push(`auth=${auth}`);
    }
    if (dav.length > 0) {
      parts.push(`dav=${dav}`);
    }
    if (contentType.length > 0) {
      parts.push(`content-type=${contentType}`);
    }
    if (body.length > 0) {
      parts.push(`body=${body}`);
    }
    return parts.length > 0 ? parts.join("; ") : "无响应正文";
  }

  private statusHint(code: number): string {
    if (code === 401) {
      return "认证失败，检查账号、应用专用密码或 Basic Auth";
    }
    if (code === 403) {
      return "权限不足，检查日历共享权限或服务端是否禁用写入";
    }
    if (code === 404) {
      return "路径不存在，检查 CalDAV 根地址、principal 或 calendar-home-set";
    }
    if (code === 405) {
      return "方法不支持，当前地址可能不是 CalDAV collection";
    }
    if (code === 501) {
      return "服务端未实现该 DAV/CalDAV 方法，检查服务商是否支持当前操作";
    }
    if (code === 301 || code === 302 || code === 303 || code === 307 || code === 308) {
      return "服务端返回重定向，检查 Location 是否可访问";
    }
    if (code === 409 || code === 412) {
      return "同步冲突，服务端 ETag 或 collection 状态已变化";
    }
	    if (code === 415) {
	      return "内容类型不支持，服务端可能不接受当前 ICS 请求";
	    }
	    if (code === 423) {
	      return "资源被锁定，稍后重试或检查服务端锁定状态";
	    }
	    if (code === 429) {
	      return "请求过多，稍后重试或调大同步间隔";
	    }
	    if (code === 507) {
	      return "服务端存储空间不足，清理远端空间后再同步";
	    }
	    if (code === 503) {
	      return "服务暂时不可用，按 Retry-After 或稍后重试";
	    }
	    if (code >= 500) {
	      return "服务端错误或网关异常";
	    }
    return "请求失败";
  }

	  private readHeader(response: http.HttpResponse, name: string): string {
	    const headers: Object = response.header ?? {};
	    const target: string = name.toLowerCase();
	    const entries: string[] = Object.keys(headers);

	    for (const key of entries) {
	      if (key.toLowerCase() === target) {
	        const value = (headers as Record<string, Object>)[key];
	        return this.headerValueToString(value);
	      }
	    }

	    return "";
	  }

	  private headerValueToString(value: Object): string {
	    if (typeof value === "string") {
	      return value;
	    }
	    if (Array.isArray(value)) {
	      return value.map((item: Object) => `${item}`).join(",");
	    }
	    return `${value}`;
	  }

	  private retryAfterSeconds(response: http.HttpResponse): number {
	    const value: string = this.readHeader(response, "retry-after").trim();
	    if (value.length === 0) {
	      return 0;
	    }

	    const seconds: number = Number(value);
	    if (!Number.isNaN(seconds) && seconds > 0) {
	      return Math.floor(seconds);
	    }

	    const retryAt: number = Date.parse(value);
	    if (Number.isNaN(retryAt)) {
	      return 0;
	    }

	    return Math.max(0, Math.ceil((retryAt - Date.now()) / 1000));
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

class URLParts {
  readonly origin: string;

  constructor(url: string) {
    const schemeEnd: number = url.indexOf("://");
    if (schemeEnd < 0) {
      this.origin = "";
      return;
    }

    const scheme: string = url.substring(0, schemeEnd);
    const rest: string = url.substring(schemeEnd + 3);
    const slash: number = rest.indexOf("/");
    const host: string = slash >= 0 ? rest.substring(0, slash) : rest;
    this.origin = `${scheme}://${host}`;
  }
}

const parseObjectRefs = (xml: string, baseUrl: string, componentName: string = ""): CalendarObjectRef[] => {
  const refs: CalendarObjectRef[] = [];
  const responses: string[] = readXmlBlocks(xml, "response");

  if (responses.length === 0) {
    return refs;
  }

	  responses.forEach((block: string) => {
	    const rawHref: string = readXmlValue(block, "href");
	    const href: string = resolveHref(rawHref, baseUrl);
	    const etag: string = readXmlValue(block, "getetag");
	    const contentType: string = readXmlValue(block, "getcontenttype");
	    const deleted: boolean = hasDeletedStatus(block);
		    if (href.length > 0 && (etag.length > 0 || deleted)) {
		      refs.push({ href, requestHref: rawHref.length > 0 ? rawHref : href, etag, contentType, deleted, componentName });
		    }
	  });

  return refs;
};

const parseCalendarDataResponses = (xml: string, baseUrl: string): CalendarDataRef[] => {
  const refs: CalendarDataRef[] = [];
  readXmlBlocks(xml, "response").forEach((block: string) => {
    if (hasDeletedStatus(block)) {
      return;
    }

    const href: string = resolveHref(readXmlValue(block, "href"), baseUrl);
    const etag: string = readXmlValue(block, "getetag");
    const ics: string = readXmlValue(block, "calendar-data");
    if (href.length > 0 && ics.length > 0) {
      refs.push({ href, etag, ics });
    }
  });
  return refs;
};

const parseCalendarCollections = (xml: string, baseUrl: string): CalendarCollectionRef[] => {
  const collections: CalendarCollectionRef[] = [];
  readXmlBlocks(xml, "response").forEach((block: string) => {
    const href: string = resolveHref(readXmlValue(block, "href"), baseUrl);
    if (href.length === 0) {
      return;
    }

    collections.push({
      href,
      ownerHref: readNestedHref(block, "owner"),
      displayName: readXmlValue(block, "displayname"),
      description: readXmlValue(block, "calendar-description"),
      color: readXmlValue(block, "calendar-color"),
      isReadOnly: !hasXmlTag(block, "write"),
      privileges: readPrivileges(block),
      ctag: readXmlValue(block, "getctag"),
      syncToken: readXmlValue(block, "sync-token"),
      isCalendar: isCalendarCollectionBlock(block),
      supportsEvents: supportsEventComponent(block),
      supportsTasks: supportsTaskComponent(block),
      supportedComponents: readSupportedComponents(block),
      supportedReports: readSupportedReports(block)
    });
  });
  return collections;
};

const isCalendarCollectionBlock = (xml: string): boolean =>
  hasXmlTag(xml, "calendar") || supportsCalendarComponent(xml);

const supportsCalendarComponent = (xml: string): boolean => {
  const lower: string = xml.toLowerCase();
  if (lower.indexOf("supported-calendar-component-set") < 0) {
    return false;
  }

  return lower.indexOf("vevent") >= 0 || lower.indexOf("vtodo") >= 0;
};

const supportsEventComponent = (xml: string): boolean => {
  const lower: string = xml.toLowerCase();
  return lower.indexOf("supported-calendar-component-set") >= 0 && lower.indexOf("vevent") >= 0;
};

const supportsTaskComponent = (xml: string): boolean => {
  const lower: string = xml.toLowerCase();
  return lower.indexOf("supported-calendar-component-set") >= 0 && lower.indexOf("vtodo") >= 0;
};

const readNestedHref = (xml: string, tag: string): string => {
  const container: string = readXmlBlock(xml, tag);
  return container.length === 0 ? "" : readXmlValue(container, "href");
};

const readHrefSet = (xml: string, tag: string): string[] => {
  const container: string = readXmlBlock(xml, tag);
  if (container.length === 0) {
    return [];
  }

  const hrefs: string[] = [];
  readXmlBlocks(container, "href").forEach((block: string) => {
    const href: string = readXmlValue(block, "href");
    if (href.length > 0 && hrefs.indexOf(href) < 0) {
      hrefs.push(href);
    }
  });
  return hrefs;
};

const readXmlBlocks = (xml: string, tag: string): string[] => {
  const pattern = new RegExp(`<(?:[A-Za-z0-9_-]+:)?${tag}\\b[\\s\\S]*?<\\/(?:[A-Za-z0-9_-]+:)?${tag}>`, "gi");
  const matches: RegExpMatchArray | null = xml.match(pattern);
  return matches === null ? [] : matches;
};

const readXmlBlock = (xml: string, tag: string): string => {
  const blocks: string[] = readXmlBlocks(xml, tag);
  return blocks.length > 0 ? blocks[0] : "";
};

const readXmlValue = (xml: string, tag: string): string => {
  const pattern = new RegExp(`<(?:[A-Za-z0-9_-]+:)?${tag}\\b[^>]*>([\\s\\S]*?)<\\/(?:[A-Za-z0-9_-]+:)?${tag}>`, "i");
  const match: RegExpMatchArray | null = xml.match(pattern);
  return match === null ? "" : decodeXml(match[1].trim());
};

const hasDeletedStatus = (xml: string): boolean =>
  xml.indexOf(" 404 ") >= 0 || xml.indexOf(">404") >= 0 || xml.indexOf(" 410 ") >= 0 || xml.indexOf(">410") >= 0;

const escapeXml = (value: string): string =>
  value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

const hasXmlTag = (xml: string, tag: string): boolean => {
  const pattern = new RegExp(`<(?:[A-Za-z0-9_-]+:)?${tag}(?:\\s|>|\\/)`, "i");
  return pattern.test(xml);
};

const resolveHref = (href: string, baseUrl: string): string => {
  const decoded: string = href.trim();
  if (decoded.length === 0) {
    return "";
  }

  if (decoded.startsWith("http://") || decoded.startsWith("https://")) {
    return decoded;
  }

  const base = new URLParts(baseUrl);
  if (base.origin.length === 0) {
    return decoded;
  }

  if (decoded.startsWith("/")) {
    return `${base.origin}${decoded}`;
  }

  return `${normalizeCollectionUrl(baseUrl)}${decoded}`;
};

const decodeXml = (value: string): string =>
  value
    .replace(/&quot;/g, "\"")
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&amp;/g, "&");

const normalizeCalendarColor = (value: string): string => {
  const color: string = value.trim();
  if (/^#[0-9a-fA-F]{6}$/.test(color)) {
    return color.substring(0, 7);
  }

  if (/^#[0-9a-fA-F]{8}$/.test(color)) {
    return color.substring(0, 7);
  }

  return "#2563EB";
};

const safeCollectionSlug = (value: string): string => {
  const normalized: string = value.trim().toLowerCase()
    .replace(/[^a-z0-9\u4e00-\u9fa5_-]+/g, "-")
    .replace(/^-+|-+$/g, "");
  const slug: string = normalized.length > 0 ? normalized : `calendar-${Date.now()}`;
  return `${encodeURIComponent(slug)}/`;
};

const readableTextColor = (color: string): string => {
  const normalized: string = normalizeCalendarColor(color).replace("#", "");
  const red: number = parseHexPair(normalized.substring(0, 2));
  const green: number = parseHexPair(normalized.substring(2, 4));
  const blue: number = parseHexPair(normalized.substring(4, 6));
  const brightness: number = red * 0.299 + green * 0.587 + blue * 0.114;
  return brightness > 160 ? "#1B2630" : "#FFFFFF";
};

const parseHexPair = (value: string): number => {
  const parsed: number = Number.parseInt(value, 16);
  return Number.isNaN(parsed) ? 0 : parsed;
};

const readPrivileges = (xml: string): string[] => {
  const privileges: string[] = [];
  ["read", "write", "write-properties", "write-content", "bind", "unbind"].forEach((name: string) => {
    if (hasXmlTag(xml, name)) {
      privileges.push(name);
    }
  });
  return privileges;
};

const readSupportedComponents = (xml: string): string[] => {
  const components: string[] = [];
  const pattern = /<(?:[A-Za-z0-9_-]+:)?comp\b[^>]*\bname=["']?([^"'\s/>]+)["']?[^>]*\/?>/gi;
  let match: RegExpExecArray | null = pattern.exec(xml);
  while (match !== null) {
    const name: string = match[1].toUpperCase();
    if (components.indexOf(name) < 0) {
      components.push(name);
    }
    match = pattern.exec(xml);
  }
  return components;
};

const readSupportedReports = (xml: string): string[] => {
  const reports: string[] = [];
  readXmlBlocks(xml, "supported-report").forEach((block: string) => {
    const reportBlock: string = readXmlBlock(block, "report");
    if (reportBlock.length === 0) {
      return;
    }

    ["calendar-query", "calendar-multiget", "free-busy-query", "sync-collection", "expand-property"].forEach((name: string) => {
      if (hasXmlTag(reportBlock, name) && reports.indexOf(name) < 0) {
        reports.push(name);
      }
    });
  });
  return reports;
};

const emptyPrincipalCapabilities = (): PrincipalCapabilities => ({
  scheduleInboxUrl: "",
  scheduleOutboxUrl: "",
  calendarUserAddressSet: "",
  supportedReportsJson: ""
});

const parseFreeBusySlots = (ics: string): CalendarFreeBusySlot[] => {
  const slots: CalendarFreeBusySlot[] = [];
  const lines: string[] = ics.replace(/\r\n[ \t]/g, "").replace(/\n[ \t]/g, "").split(/\r?\n/);
  lines.forEach((line: string) => {
    const upper: string = line.toUpperCase();
    if (!upper.startsWith("FREEBUSY")) {
      return;
    }

    const separator: number = line.indexOf(":");
    if (separator < 0) {
      return;
    }

    const params: string = line.substring(0, separator);
    const busyType: string = readFreeBusyType(params);
    line.substring(separator + 1).split(",").forEach((range: string) => {
      const parts: string[] = range.split("/");
      if (parts.length !== 2) {
        return;
      }

      const startAt: number = parseUtcIcsDate(parts[0]);
      const endAt: number = parseUtcIcsDate(parts[1]);
      if (startAt > 0 && endAt > startAt) {
        slots.push({ startAt, endAt, busyType });
      }
    });
  });
  return slots;
};

const readFreeBusyType = (params: string): string => {
  const match: RegExpMatchArray | null = params.match(/FBTYPE=([^;:]+)/i);
  return match === null ? "BUSY" : match[1].toUpperCase();
};

const parseUtcIcsDate = (value: string): number => {
  const trimmed: string = value.trim();
  const match: RegExpMatchArray | null = trimmed.match(/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z?$/);
  if (match === null) {
    return 0;
  }

  return Date.UTC(
    Number(match[1]),
    Number(match[2]) - 1,
    Number(match[3]),
    Number(match[4]),
    Number(match[5]),
    Number(match[6])
  );
};

const decodeURIComponentSafe = (value: string): string => {
  try {
    return decodeURIComponent(value);
  } catch {
    return value;
  }
};

const isWellKnownCalDavUrl = (url: string): boolean => {
  const normalized: string = normalizeServerUrl(url).toLowerCase();
  return normalized.endsWith("/.well-known/caldav");
};
