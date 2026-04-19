"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SettingsService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
const KEY_STATUS = 'canteen_status';
const KEY_MESSAGE = 'canteen_status_message';
const KEY_UPDATED = 'canteen_status_updated_at';
let SettingsService = class SettingsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getCanteenStatus() {
        const rows = await this.prisma.appConfig.findMany({
            where: { key: { in: [KEY_STATUS, KEY_MESSAGE, KEY_UPDATED] } },
        });
        const byKey = new Map(rows.map((r) => [r.key, r.value]));
        const updStr = byKey.get(KEY_UPDATED);
        return {
            status: byKey.get(KEY_STATUS) ?? 'open',
            message: byKey.get(KEY_MESSAGE) ?? '',
            updatedAt: updStr ? new Date(updStr) : null,
        };
    }
    async isOrderingOpen() {
        const row = await this.prisma.appConfig.findUnique({
            where: { key: KEY_STATUS },
        });
        const status = (row?.value ?? 'open');
        return status === 'open';
    }
    async setCanteenStatus(status, message) {
        const now = new Date().toISOString();
        await Promise.all([
            this.prisma.appConfig.upsert({
                where: { key: KEY_STATUS },
                update: { value: status },
                create: { key: KEY_STATUS, value: status },
            }),
            this.prisma.appConfig.upsert({
                where: { key: KEY_MESSAGE },
                update: { value: message },
                create: { key: KEY_MESSAGE, value: message },
            }),
            this.prisma.appConfig.upsert({
                where: { key: KEY_UPDATED },
                update: { value: now },
                create: { key: KEY_UPDATED, value: now },
            }),
        ]);
        return { status, message, updatedAt: new Date(now) };
    }
    async listStaff() {
        return this.prisma.canteenUser.findMany({
            select: {
                id: true,
                name: true,
                phoneNumber: true,
                role: true,
                isActive: true,
                createdAt: true,
            },
            orderBy: { createdAt: 'asc' },
        });
    }
    async setStaffActive(id, isActive) {
        return this.prisma.canteenUser.update({
            where: { id },
            data: { isActive },
            select: {
                id: true,
                name: true,
                phoneNumber: true,
                role: true,
                isActive: true,
            },
        });
    }
};
exports.SettingsService = SettingsService;
exports.SettingsService = SettingsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], SettingsService);
//# sourceMappingURL=settings.service.js.map