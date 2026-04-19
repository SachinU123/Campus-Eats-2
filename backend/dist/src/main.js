"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const common_1 = require("@nestjs/common");
const app_module_js_1 = require("./app.module.js");
const all_exceptions_filter_js_1 = require("./common/filters/all-exceptions.filter.js");
const httpLogger = new common_1.Logger('HTTP');
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_js_1.AppModule);
    app.use((req, res, next) => {
        const start = Date.now();
        res.on('finish', () => {
            const ms = Date.now() - start;
            const level = res.statusCode >= 400 ? 'error' : 'log';
            httpLogger[level](`[${req.method}] ${req.url} → ${res.statusCode} (${ms}ms)`);
        });
        next();
    });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    app.useGlobalFilters(new all_exceptions_filter_js_1.AllExceptionsFilter());
    app.enableCors({
        origin: '*',
        methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
        allowedHeaders: 'Content-Type,Authorization',
    });
    app.setGlobalPrefix('api/v1');
    const port = process.env.PORT ?? 3000;
    await app.listen(port, '0.0.0.0');
    httpLogger.log(`\n🚀 CampusEats API running on http://localhost:${port}/api/v1\n`);
}
bootstrap();
//# sourceMappingURL=main.js.map