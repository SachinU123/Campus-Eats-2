import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

@Injectable()
export class MenuService {
  constructor(private readonly prisma: PrismaService) {}

  async getCategories() {
    return this.prisma.menuCategory.findMany({
      orderBy: { sortOrder: 'asc' },
    });
  }

  async getItems(categoryId?: string) {
    const where: any = { isAvailable: true };
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
      orderBy: { name: 'asc' },
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
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
      },
      include: { category: true },
    });
  }
}
