import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module.js';
import type { Request, Response, NextFunction } from 'express';

const httpLogger = new Logger('HTTP');

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ─── Request logging middleware (temporary debug — remove after stabilisation) ───
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

  // CORS for Flutter app
  app.enableCors({
    origin: '*', // In production, restrict to specific origins
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type,Authorization',
  });

  // API prefix
  app.setGlobalPrefix('api/v1');

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  httpLogger.log(`\n🚀 CampusEats API running on http://localhost:${port}/api/v1\n`);
}
bootstrap();
