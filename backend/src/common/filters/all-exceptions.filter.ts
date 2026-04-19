/// ─── CampusEats — Global Exception Filter (Phase 11 Telemetry) ─────────────
///
/// Catches ALL unhandled HTTP and non-HTTP exceptions, logs them with context
/// and reports to Sentry when SENTRY_DSN is configured.
///
/// Sentry is lazily initialised: when SENTRY_DSN env var is set, all errors
/// ≥ 500 (and uncaught non-HTTP exceptions) are captured with full context.
/// When DSN is absent the filter still provides structured local logging.
///
/// To enable Sentry on Render:
///   1. Create a Sentry project at https://sentry.io
///   2. Copy the DSN from Settings → Client Keys
///   3. Add SENTRY_DSN=<dsn> to Render → Environment Variables

import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request, Response } from 'express';

// Dynamic import so the app builds even if @sentry/nestjs fails to install
let Sentry: typeof import('@sentry/nestjs') | null = null;

@Catch()
export class AllExceptionsFilter
  implements ExceptionFilter, OnApplicationBootstrap
{
  private readonly logger = new Logger('GlobalExceptionFilter');
  private sentryReady = false;

  constructor(private readonly config: ConfigService) {}

  async onApplicationBootstrap() {
    const dsn = this.config.get<string>('SENTRY_DSN');
    if (!dsn) {
      this.logger.warn(
        '[Sentry] SENTRY_DSN not set — remote error reporting disabled',
      );
      return;
    }
    try {
      Sentry = await import('@sentry/nestjs').catch(() => null);
      if (!Sentry) {
        this.logger.error('[Sentry] @sentry/nestjs could not be loaded');
        return;
      }
      Sentry.init({
        dsn,
        environment: this.config.get<string>('NODE_ENV') ?? 'production',
        // Only trace errors, not all transactions — keeps the free tier quota
        tracesSampleRate: 0,
      });
      this.sentryReady = true;
      this.logger.log('[Sentry] Initialised successfully');
    } catch (err) {
      this.logger.error(
        `[Sentry] Init failed: ${(err as Error).message}`,
      );
    }
  }

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const isHttpException = exception instanceof HttpException;
    const status = isHttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const message = isHttpException
      ? ((exception.getResponse() as any)?.message ?? exception.message)
      : 'Internal server error';

    // Structured production log — enough context without leaking secrets
    if (status >= 500) {
      this.logger.error(
        `[500] ${request.method} ${request.url} — ${message}`,
        exception instanceof Error ? exception.stack : String(exception),
      );

      // Report to Sentry when configured
      if (this.sentryReady && Sentry) {
        Sentry.withScope((scope) => {
          scope.setTag('method', request.method);
          scope.setTag('url', request.url);
          scope.setExtra('statusCode', status);
          if (exception instanceof Error) {
            Sentry!.captureException(exception);
          } else {
            Sentry!.captureMessage(String(exception), 'error');
          }
        });
      }
    } else {
      this.logger.warn(
        `[${status}] ${request.method} ${request.url} — ${message}`,
      );
    }

    response.status(status).json({
      success: false,
      statusCode: status,
      message: Array.isArray(message) ? message.join('; ') : message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
