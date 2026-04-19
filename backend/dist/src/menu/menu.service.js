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
exports.MenuService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let MenuService = class MenuService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getCategories() {
        return this.prisma.menuCategory.findMany({
            orderBy: { sortOrder: 'asc' },
        });
    }
    async getItems(categoryId) {
        const where = {
            isAvailable: true,
            isUnavailableToday: false,
        };
        if (categoryId && categoryId !== 'all') {
            if (categoryId === 'popular') {
                where.isPopular = true;
            }
            else {
                where.categoryId = categoryId;
            }
        }
        return this.prisma.menuItem.findMany({
            where,
            include: { category: true },
            orderBy: [{ isSpecial: 'desc' }, { name: 'asc' }],
        });
    }
    async getItemById(id) {
        return this.prisma.menuItem.findUnique({
            where: { id },
            include: { category: true },
        });
    }
    async searchItems(query) {
        return this.prisma.menuItem.findMany({
            where: {
                isAvailable: true,
                isUnavailableToday: false,
                OR: [
                    { name: { contains: query, mode: 'insensitive' } },
                    { description: { contains: query, mode: 'insensitive' } },
                ],
            },
            include: { category: true },
            orderBy: [{ isSpecial: 'desc' }, { name: 'asc' }],
        });
    }
    async getAllItemsForManagement() {
        return this.prisma.menuItem.findMany({
            include: { category: true },
            orderBy: [{ categoryId: 'asc' }, { name: 'asc' }],
        });
    }
    async setUnavailableToday(id, isUnavailableToday) {
        const item = await this.prisma.menuItem.findUnique({ where: { id } });
        if (!item)
            throw new common_1.NotFoundException(`Menu item ${id} not found`);
        return this.prisma.menuItem.update({
            where: { id },
            data: { isUnavailableToday },
            include: { category: true },
        });
    }
    async setSpecial(id, isSpecial, specialLabel) {
        const item = await this.prisma.menuItem.findUnique({ where: { id } });
        if (!item)
            throw new common_1.NotFoundException(`Menu item ${id} not found`);
        return this.prisma.menuItem.update({
            where: { id },
            data: {
                isSpecial,
                specialLabel: isSpecial ? (specialLabel ?? item.specialLabel ?? "Today's Special") : '',
            },
            include: { category: true },
        });
    }
    async checkItemsOrderable(ids) {
        const items = await this.prisma.menuItem.findMany({
            where: { id: { in: ids } },
        });
        const blocked = [];
        for (const id of ids) {
            const item = items.find((m) => m.id === id);
            if (!item) {
                blocked.push({ id, name: 'Unknown', reason: 'Item not found' });
            }
            else if (!item.isAvailable) {
                blocked.push({ id, name: item.name, reason: 'Item is permanently unavailable' });
            }
            else if (item.isUnavailableToday) {
                blocked.push({ id, name: item.name, reason: 'Item is unavailable today' });
            }
        }
        return blocked;
    }
};
exports.MenuService = MenuService;
exports.MenuService = MenuService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], MenuService);
//# sourceMappingURL=menu.service.js.map