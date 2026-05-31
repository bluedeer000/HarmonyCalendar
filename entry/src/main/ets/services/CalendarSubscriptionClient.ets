import { http } from "@kit.NetworkKit";
import { parseIcsEvents } from "./CalendarFormat";
import { CalendarEvent } from "./CalendarTypes";

export interface SubscriptionFetchResult {
  readonly events: CalendarEvent[];
  readonly etag: string;
  readonly lastModified: string;
  readonly notModified?: boolean;
  readonly failed: number;
  readonly total: number;
  readonly httpStatus?: number;
  readonly retryAfterSeconds?: number;
  readonly diagnosticJson?: string;
}

export class SubscriptionHttpError extends Error {
  readonly url: string;
  readonly status: number;
  readonly retryAfterSeconds: number;
  readonly diagnostic: string;

  constructor(url: string, status: number, retryAfterSeconds: number, diagnostic: string) {
    super(`订阅源返回 ${status}: ${diagnostic}`);
    this.url = url;
    this.status = status;
    this.retryAfterSeconds = retryAfterSeconds;
    this.diagnostic = diagnostic;
  }

  toDiagnosticJson(): string {
    return JSON.stringify({
      protocol: "ics-subscription",
      method: "GET",
      url: this.url,
      httpStatus: this.status,
      retryAfterSeconds: this.retryAfterSeconds,
      diagnostic: this.diagnostic,
      checkedAt: Date.now()
    });
  }
}

export class CalendarSubscriptionClient {
  async fetch(url: string, etag: string = "", lastModified: string = ""): Promise<SubscriptionFetchResult> {
    const request = http.createHttp();
    try {
      const headers: Record<string, string> = {
        "accept": "text/calendar, application/ics, */*"
      };
      if (etag.trim().length > 0) {
        headers["if-none-match"] = etag.trim();
      }
      if (lastModified.trim().length > 0) {
        headers["if-modified-since"] = lastModified.trim();
      }

      const response: http.HttpResponse = await request.request(this.normalizedUrl(url), {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 25000,
        header: headers
      });

      if (response.responseCode === 304) {
        return {
          events: [],
          etag,
          lastModified,
          notModified: true,
          failed: 0,
          total: 0,
          httpStatus: 304,
          retryAfterSeconds: this.retryAfterSeconds(response),
          diagnosticJson: this.responseDiagnosticJson(url, response)
        };
      }

      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new SubscriptionHttpError(
          this.normalizedUrl(url),
          response.responseCode,
          this.retryAfterSeconds(response),
          this.responseDiagnostic(response)
        );
      }

      const ics: string = this.responseText(response);
      const events: CalendarEvent[] = parseIcsEvents(ics, this.normalizedUrl(url), this.readHeader(response, "etag"));
      return {
        events,
        etag: this.readHeader(response, "etag"),
        lastModified: this.readHeader(response, "last-modified"),
        failed: 0,
        total: events.length,
        httpStatus: response.responseCode,
        retryAfterSeconds: this.retryAfterSeconds(response),
        diagnosticJson: this.responseDiagnosticJson(url, response)
      };
    } catch (error) {
      if (error instanceof SubscriptionHttpError) {
        throw error;
      }
      throw new Error(`拉取订阅源失败：${this.describeError(error)}`);
    } finally {
      request.destroy();
    }
  }

  private normalizedUrl(url: string): string {
    const trimmed: string = url.trim();
    if (trimmed.toLowerCase().startsWith("webcal://")) {
      return `https://${trimmed.substring("webcal://".length)}`;
    }

    return trimmed;
  }

  private responseText(response: http.HttpResponse): string {
    if (typeof response.result === "string") {
      return response.result;
    }

    return JSON.stringify(response.result);
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

  private responseDiagnostic(response: http.HttpResponse): string {
    const parts: string[] = [];
    const retryAfter: string = this.readHeader(response, "retry-after");
    const contentType: string = this.readHeader(response, "content-type");
    const body: string = this.responseText(response).replace(/\s+/g, " ").substring(0, 220);
    if (retryAfter.length > 0) {
      parts.push(`retry-after=${retryAfter}`);
    }
    if (contentType.length > 0) {
      parts.push(`content-type=${contentType}`);
    }
    if (body.length > 0) {
      parts.push(`body=${body}`);
    }
    return parts.length > 0 ? parts.join("; ") : "无响应正文";
  }

  private responseDiagnosticJson(url: string, response: http.HttpResponse): string {
    return JSON.stringify({
      protocol: "ics-subscription",
      method: "GET",
      url: this.normalizedUrl(url),
      httpStatus: response.responseCode,
      retryAfterSeconds: this.retryAfterSeconds(response),
      etag: this.readHeader(response, "etag"),
      lastModified: this.readHeader(response, "last-modified"),
      diagnostic: this.responseDiagnostic(response),
      checkedAt: Date.now()
    });
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

    return JSON.stringify(error);
  }
}
