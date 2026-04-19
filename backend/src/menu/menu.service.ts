import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class MenuService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Customer-facing: only available items (isAvailable=true AND NOT isUnavailableToday) ──

  async getCategories() {
    return this.prisma.menuCategory.findMany({
      orderBy: { sortOrder: 'asc' },
    });
  }

  async getItems(categoryId?: string) {
    const where: any = {
      isAvailable: true,
      // Phase 6: exclude items marked unavailable today (customer view hides them)
      isUnavailableToday: false,
    };
    if (categoryId && categoryId !== 'all') {
      if (categoryId === 'popular') {
        where.isPopular = true;
      } else {
        where.categoryId = categoryId;
      }
    }
    return this.prisma.menuItem.findMany({
      where,
      include: { category: true },
      orderBy: [{ isSpecial: 'desc' }, { name: 'asc' }], // specials first
    });
  }

  async getItemById(id: string) {
    return this.prisma.menuItem.findUnique({
      where: { id },
      include: { category: true },
    });
  }

  async searchItems(query: string) {
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

  // ── Operations/Canteen-facing: full item list (all items regardless of availability) ──

  async getAllItemsForManagement() {
    return this.prisma.menuItem.findMany({
      include: { category: true },
      orderBy: [{ categoryId: 'asc' }, { name: 'asc' }],
    });
  }

  // ── Phase 6: Toggle unavailable today ──

  async setUnavailableToday(id: string, isUnavailableToday: boolean) {
    const item = await this.prisma.menuItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException(`Menu item ${id} not found`);

    return this.prisma.menuItem.update({
      where: { id },
      data: { isUnavailableToday },
      include: { category: true },
    });
  }

  // ── Phase 6: Toggle special/event food ──

  async setSpecial(id: string, isSpecial: boolean, specialLabel?: string) {
    const item = await this.prisma.menuItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException(`Menu item ${id} not found`);

    return this.prisma.menuItem.update({
      where: { id },
      data: {
        isSpecial,
        specialLabel: isSpecial ? (specialLabel ?? item.specialLabel ?? "Today's Special") : '',
      },
      include: { category: true },
    });
  }

  // ── Phase 6: Bulk availability check (used by order service) ──

  async checkItemsOrderable(ids: string[]): Promise<{ id: string; name: string; reason: string }[]> {
    const items = await this.prisma.menuItem.findMany({
      where: { id: { in: ids } },
    });

    const blocked: { id: string; name: string; reason: string }[] = [];

    for (const id of ids) {
      const item = items.find((m) => m.id === id);
      if (!item) {
        blocked.push({ id, name: 'Unknown', reason: 'Item not found' });
      } else if (!item.isAvailable) {
        blocked.push({ id, name: item.name, reason: 'Item is permanently unavailable' });
      } else if (item.isUnavailableToday) {
        blocked.push({ id, name: item.name, reason: 'Item is unavailable today' });
      }
    }

    return blocked;
  }
}
