import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module.js';
import type { Request, Response, NextFunction } from 'express';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter.js';

const httpLogger = new Logger('HTTP');

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ─── Request logging middleware ───────────────────────────────────────────
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    res.on('finish', () => {
      const ms = Date.now() - start;
      const level = res.statusCode >= 400 ? 'error' : 'log';
      httpLogger[level](
        `[${req.method}] ${req.url} → ${res.statusCode} (${ms}ms)`,
      );
    });
    next();
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Phase 11: Global exception filter — Sentry when SENTRY_DSN is set, else local log.
  // Pulls ConfigService from DI so filter can read env vars.
  const configService = app.get(ConfigService);
  app.useGlobalFilters(new AllExceptionsFilter(configService));

  // CORS for Flutter app
  app.enableCors({
    origin: '*', // In production, restrict to specific origins
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization',
  });

  // ── Root health route — GET / and HEAD / ─────────────────────────────────
  // Registered on the raw Express adapter BEFORE setGlobalPrefix so it is
  // not affected by the /api/v1 prefix. Eliminates noisy 404s from Render
  // uptime checks, browser hits, and health monitors.
  const httpAdapter = app.getHttpAdapter().getInstance() as import('express').Application;
  httpAdapter.get('/', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'ok',
      message: 'CampusEats API is running',
      basePath: '/api/v1',
    });
  });
  httpAdapter.head('/', (_req: Request, res: Response) => {
    res.status(200).end();
  });

  // API prefix
  app.setGlobalPrefix('api/v1');

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  httpLogger.log(`\n🚀 CampusEats API running on http://localhost:${port}/api/v1\n`);
}
bootstrap();
