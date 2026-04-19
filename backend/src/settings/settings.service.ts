import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';

export type CanteenStatus = 'open' | 'paused' | 'closed';

export interface CanteenOperationalStatus {
  status: CanteenStatus;
  message: string;
  updatedAt: Date | null;
}

const KEY_STATUS  = 'canteen_status';
const KEY_MESSAGE = 'canteen_status_message';
const KEY_UPDATED = 'canteen_status_updated_at';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  // ── Read current canteen operational status ──────────────────

  async getCanteenStatus(): Promise<CanteenOperationalStatus> {
    const rows = await this.prisma.appConfig.findMany({
      where: { key: { in: [KEY_STATUS, KEY_MESSAGE, KEY_UPDATED] } },
    });
    const byKey = new Map(rows.map((r) => [r.key, r.value]));
    const updStr = byKey.get(KEY_UPDATED);
    return {
      status: (byKey.get(KEY_STATUS) as CanteenStatus) ?? 'open',
      message: byKey.get(KEY_MESSAGE) ?? '',
      updatedAt: updStr ? new Date(updStr) : null,
    };
  }

  // ── Check if new orders are currently accepted ───────────────

  async isOrderingOpen(): Promise<boolean> {
    const row = await this.prisma.appConfig.findUnique({
      where: { key: KEY_STATUS },
    });
    // Default: open (no row = open)
    const status = (row?.value ?? 'open') as CanteenStatus;
    return status === 'open';
  }

  // ── Update canteen operational status ────────────────────────

  async setCanteenStatus(
    status: CanteenStatus,
    message: string,
  ): Promise<CanteenOperationalStatus> {
    const now = new Date().toISOString();

    // Upsert all three config keys atomically (sequential — AppConfig has unique key)
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

  // ── Staff management helpers ──────────────────────────────────

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

  async setStaffActive(id: string, isActive: boolean) {
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
}
