import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';
import { SettingsService } from '../settings/settings.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly settings: SettingsService,
    private readonly notifications: NotificationsService,
  ) {}

  // ─── Create Order ───────────────────────────────────────────

  async createOrder(
    callerId: string,
    dto: CreateOrderDto,
    callerRole: 'student' | 'faculty' = 'student',
  ) {
    this.logger.log(
      `[ORDER] createOrder for ${callerRole}: ${callerId}, items: ${JSON.stringify(dto.items)}`,
    );

    // ── Phase 7: Enforce canteen operational status ─────────────
    const isOpen = await this.settings.isOrderingOpen();
    if (!isOpen) {
      const status = await this.settings.getCanteenStatus();
      const reason = status.message
        ? status.message
        : status.status === 'paused'
          ? 'The canteen is temporarily paused. Please try again later.'
          : 'The canteen is currently closed for new orders.';
      throw new BadRequestException(`Ordering is currently disabled: ${reason}`);
    }

    // ── Schedule validation ──────────────────────────────────
    let scheduledFor: Date | null = null;
    if (dto.scheduledFor) {
      const parsed = new Date(dto.scheduledFor);
      if (isNaN(parsed.getTime())) {
        throw new BadRequestException('Invalid scheduledFor date format');
      }
      const nowMs = Date.now();
      const diffMs = parsed.getTime() - nowMs;
      const diffMin = diffMs / 60_000;

      if (diffMin < 30) {
        throw new BadRequestException(
          'Scheduled time must be at least 30 minutes from now',
        );
      }
      if (diffMin > 120) {
        throw new BadRequestException(
          'Scheduled time cannot be more than 2 hours ahead',
        );
      }
      scheduledFor = parsed;
      this.logger.log(
        `[ORDER] Scheduled order for ${parsed.toISOString()} (${Math.round(diffMin)} min from now)`,
      );
    }

    // ── Validate and fetch menu items ────────────────────────
    const menuItemIds = dto.items.map((item) => item.menuItemId);
    const menuItems = await this.prisma.menuItem.findMany({
      where: { id: { in: menuItemIds } },
    });

    // Phase 6: Check each item separately for clear error messages
    const blockedItems: string[] = [];
    const foundMap = new Map(menuItems.map((m) => [m.id, m]));

    for (const id of menuItemIds) {
      const item = foundMap.get(id);
      if (!item) {
        blockedItems.push(`${id} (not found)`);
      } else if (!item.isAvailable) {
        blockedItems.push(`${item.name} (permanently unavailable)`);
      } else if (item.isUnavailableToday) {
        blockedItems.push(`${item.name} (unavailable today)`);
      }
    }

    if (blockedItems.length > 0) {
      throw new BadRequestException(
        `Some items cannot be ordered: ${blockedItems.join(', ')}`,
      );
    }

    // All items are orderable — keep only the validated set
    const validMenuItems = menuItems.filter(
      (m) => m.isAvailable && !m.isUnavailableToday,
    );


    // ── Calculate server-side totals ─────────────────────────
    const menuMap = new Map(validMenuItems.map((m) => [m.id, m]));
    let subtotal = 0;
    const orderItems = dto.items.map((item) => {
      const menu = menuMap.get(item.menuItemId)!;
      const lineTotal = menu.price * item.quantity;
      subtotal += lineTotal;
      return {
        menuItemId: menu.id,
        itemNameSnapshot: menu.name,
        unitPriceSnapshot: menu.price,
        quantity: item.quantity,
        lineTotal,
        emoji: menu.emoji,
        isVeg: menu.isVeg,
      };
    });

    const total = subtotal;

    // ── Compute ETA (only for non-scheduled / immediate orders) ─
    let estimatedReadyAt: Date | null = null;
    if (!scheduledFor) {
      const maxPrepMinutes = Math.max(
        ...validMenuItems.map((m) => m.prepTimeMinutes ?? 5),
      );
      const buffer = 5; // standard kitchen buffer

      // Rush hour: 11:00 AM – 2:00 PM IST (UTC+5:30) — use campus-local hour
      const now = new Date();
      const istOffsetMs = 5.5 * 60 * 60 * 1000; // IST = UTC+5:30
      const istHour = new Date(now.getTime() + istOffsetMs).getUTCHours();
      const rushExtra = istHour >= 11 && istHour < 14 ? 10 : 0;

      const totalMinutes = maxPrepMinutes + buffer + rushExtra;
      estimatedReadyAt = new Date(now.getTime() + totalMinutes * 60_000);

      this.logger.log(
        `[ETA] Computed: maxPrep=${maxPrepMinutes}min buffer=${buffer}min istHour=${istHour} rush=${rushExtra}min → ready at ${estimatedReadyAt.toISOString()}`,
      );
    }

    // ── Generate token ────────────────────────────────────────
    const tokenNumber = await this.generateToken();

    // ── Create order ──────────────────────────────────────────
    const order = await this.prisma.order.create({
      data: {
        ...(callerRole === 'faculty'
          ? { facultyId: callerId, customerRole: 'faculty' }
          : { studentId: callerId, customerRole: 'student' }),
        tokenNumber,
        status: 'created',
        subtotal,
        total,
        paymentStatus: 'pending',
        notes: dto.notes,
        scheduledFor,
        estimatedReadyAt,
        items: {
          create: orderItems,
        },
      },
      include: {
        items: { include: { menuItem: true } },
        student: true,
        faculty: true,
      },
    });

    return order;
  }

  async getStudentOrders(studentId: string) {
    return this.prisma.order.findMany({
      where: { studentId },
      include: {
        items: true,
        paymentTransaction: true,
      },
      orderBy: { orderedAt: 'desc' },
    });
  }

  // ─── Get Faculty Orders ─────────────────────────────────────

  async getFacultyOrders(facultyId: string) {
    return this.prisma.order.findMany({
      where: { facultyId },
      include: {
        items: true,
        paymentTransaction: true,
      },
      orderBy: { orderedAt: 'desc' },
    });
  }

  // ─── Get Order by ID ───────────────────────────────────────

  async getOrderById(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: true,
        student: true,
        paymentTransaction: true,
        receipt: true,
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  // ─── Canteen: Get All Paid Orders ──────────────────────────

  async getCanteenOrders(status?: string) {
    const where: any = {
      // Never show soft-archived orders in the canteen live view
      hiddenFromCanteenAt: null,
    };
    if (status) {
      where.status = status;
      this.logger.log(`[CANTEEN] getCanteenOrders with filter status=${status}`);
    } else {
      // Default: show paid and completed orders only
      where.status = { in: ['paid', 'completed'] };
      this.logger.log(`[CANTEEN] getCanteenOrders default filter: paid + completed (non-archived)`);
    }

    return this.prisma.order.findMany({
      where,
      include: {
        items: true,
        student: {
          select: { id: true, name: true, phoneNumber: true, email: true },
        },
        faculty: {
          select: { id: true, name: true, phoneNumber: true, email: true, department: true, roomNumber: true },
        },
        paymentTransaction: true,
      },
      orderBy: { orderedAt: 'desc' },
    });
  }

  // ─── Canteen: Reports ───────────────────────────────────────

  async getCanteenReports() {
    const now = new Date();

    // ── Use IST (UTC+5:30) boundaries so "today" and "this month" are
    //    campus-local, not server-UTC boundaries. ─────────────────────
    const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
    const nowIst = new Date(now.getTime() + IST_OFFSET_MS);

    // IST midnight for today (UTC)
    const istMidnightUTC = new Date(
      Date.UTC(
        nowIst.getUTCFullYear(),
        nowIst.getUTCMonth(),
        nowIst.getUTCDate(),
      ) - IST_OFFSET_MS,
    );
    const todayStart = istMidnightUTC;
    const todayEnd = new Date(istMidnightUTC.getTime() + 86_400_000 - 1); // +24h-1ms

    // IST month boundaries
    const monthStartIstMs = Date.UTC(
      nowIst.getUTCFullYear(),
      nowIst.getUTCMonth(),
      1,
    );
    const monthEndIstMs = Date.UTC(
      nowIst.getUTCFullYear(),
      nowIst.getUTCMonth() + 1,
      1,
    ) - 1;
    const monthStart = new Date(monthStartIstMs - IST_OFFSET_MS);
    const monthEnd = new Date(monthEndIstMs - IST_OFFSET_MS);

    // Paid statuses only (completed orders = real revenue)
    // Reports are NOT filtered by hiddenFromCanteenAt — archive is UI-only.
    const paidStatuses = ['paid', 'completed'];

    // Today stats
    const todayOrders = await this.prisma.order.findMany({
      where: {
        status: { in: paidStatuses },
        orderedAt: { gte: todayStart, lte: todayEnd },
      },
      include: { items: true },
    });

    const todayRevenue = todayOrders.reduce((s, o) => s + o.total, 0);

    // This month stats
    const monthOrders = await this.prisma.order.findMany({
      where: {
        status: { in: paidStatuses },
        orderedAt: { gte: monthStart, lte: monthEnd },
      },
      include: { items: true },
    });

    const monthRevenue = monthOrders.reduce((s, o) => s + o.total, 0);

    // Top items (across all time) — not filtered by archive
    const allOrderItems = await this.prisma.orderItem.groupBy({
      by: ['itemNameSnapshot'],
      _sum: { quantity: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: 5,
    });

    // Average daily orders (this month) — use IST day-of-month
    const daysPassed = nowIst.getUTCDate();
    const avgDailyOrders =
      daysPassed > 0
        ? Math.round((monthOrders.length / daysPassed) * 10) / 10
        : 0;

    this.logger.log(
      `[REPORTS] IST date=${nowIst.toUTCString()} today=${todayOrders.length} Rs.${todayRevenue} | month=${monthOrders.length} Rs.${monthRevenue}`,
    );

    return {
      today: {
        orderCount: todayOrders.length,
        revenue: todayRevenue,
      },
      thisMonth: {
        orderCount: monthOrders.length,
        revenue: monthRevenue,
        avgDailyOrders,
      },
      topItems: allOrderItems.map((item) => ({
        name: item.itemNameSnapshot,
        totalQuantity: item._sum.quantity ?? 0,
      })),
    };
  }

  // ─── Canteen: Clear Completed History ──────────────────────

  async clearCompletedHistory(canteenUserId: string) {
    this.logger.log(
      `[CANTEEN] clearCompletedHistory (soft-archive) requested by canteen user: ${canteenUserId}`,
    );

    // SOFT CLEAR — never delete orders or payment records.
    // Sets hiddenFromCanteenAt on completed orders that are not already hidden.
    // Reports, student history, and payment records are completely unaffected.
    const result = await this.prisma.order.updateMany({
      where: {
        status: 'completed',
        hiddenFromCanteenAt: null, // only touch orders not yet archived
      },
      data: {
        hiddenFromCanteenAt: new Date(),
      },
    });

    this.logger.log(
      `[CANTEEN] Soft-archived ${result.count} completed orders (hiddenFromCanteenAt set)`,
    );
    return { cleared: result.count };
  }

  // ─── Canteen: Mark Order as Printed ────────────────────────

  async printOrder(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { items: true, student: true, faculty: true },
    });
    if (!order) throw new NotFoundException('Order not found');
    // Idempotent — if already printed, still return success with current state
    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { printedAt: order.printedAt ?? new Date() },
      include: { items: true, student: true, faculty: true },
    });
    this.logger.log(
      `[CANTEEN] printOrder orderId=${orderId} printedAt=${updated.printedAt?.toISOString()}`,
    );
    return updated;
  }

  // ─── Canteen: Update Order Status ──────────────────────────

  async updateOrderStatus(orderId: string, dto: UpdateOrderStatusDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) throw new NotFoundException('Order not found');

    // Idempotent: already completed → return success without re-applying
    if (order.status === dto.status && dto.status === 'completed') {
      return this.prisma.order.findUnique({
        where: { id: orderId },
        include: { items: true, student: true, faculty: true },
      });
    }

    const allowedTransitions: Record<string, string[]> = {
      paid: ['completed', 'cancelled'],
      completed: [], // Final state – block re-completion
      cancelled: [], // Final state
    };

    const allowed = allowedTransitions[order.status] || [];
    if (!allowed.includes(dto.status)) {
      if (order.status === 'completed') {
        throw new BadRequestException('Order has already been completed');
      }
      throw new BadRequestException(
        `Cannot transition from '${order.status}' to '${dto.status}'`,
      );
    }

    return this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: dto.status,
        completedAt: dto.status === 'completed' ? new Date() : undefined,
      },
      include: {
        items: true,
        student: true,
        faculty: true,
      },
    });
  }

  // ─── Canteen: Mark Order as READY (Phase 11) ─────────────────
  //
  // Explicit readiness signal — separate from printedAt and completedAt.
  // Sets readyAt, then fires a push notification to the customer so they
  // know to come collect their food.
  // Idempotent: if already marked ready, returns current state.

  async markOrderReady(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: { items: true, student: true, faculty: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    if (order.status !== 'paid') {
      throw new BadRequestException(
        `Only paid (queued) orders can be marked ready. Current status: ${order.status}`,
      );
    }

    // Idempotent — already ready, return current state
    if (order.readyAt) {
      this.logger.log(
        `[READY] Order ${orderId} already marked ready at ${order.readyAt.toISOString()}`,
      );
      return order;
    }

    const updated = await this.prisma.order.update({
      where: { id: orderId },
      data: { readyAt: new Date() },
      include: { items: true, student: true, faculty: true },
    });

    this.logger.log(
      `[READY] Order ${orderId} (token=${updated.tokenNumber}) marked ready`,
    );

    // ── Dispatch push notification ─────────────────────────────
    // Look up the customer's FCM token from the appropriate table.
    // This is fire-and-forget — any FCM failure is logged but swallowed.
    const isFaculty = updated.customerRole === 'faculty';
    let fcmToken: string | null = null;

    if (isFaculty && updated.facultyId) {
      const fac = await this.prisma.faculty.findUnique({
        where: { id: updated.facultyId },
        select: { fcmToken: true, name: true },
      });
      fcmToken = fac?.fcmToken ?? null;
    } else if (updated.studentId) {
      const stu = await this.prisma.student.findUnique({
        where: { id: updated.studentId },
        select: { fcmToken: true, name: true },
      });
      fcmToken = stu?.fcmToken ?? null;
    }

    if (fcmToken) {
      // Do not await — notification failure must never block order flow
      this.notifications
        .sendToToken(
          fcmToken,
          '🍽️ Your order is ready!',
          `Token #${updated.tokenNumber} is ready for pickup at the counter.`,
          { orderId: updated.id, token: updated.tokenNumber },
        )
        .catch((e) =>
          this.logger.error(`[READY] FCM dispatch failed: ${e?.message}`),
        );
    } else {
      this.logger.warn(
        `[READY] No FCM token for ${isFaculty ? 'faculty' : 'student'} — push skipped`,
      );
    }

    return updated;
  }

  // ─── Register / Update FCM Token (Phase 11) ─────────────────
  //
  // Called by the Flutter app after login when a new FCM token is
  // obtained. Stores the token against the user record.
  // Idempotent — calling again with the same token is a no-op.

  async registerFcmToken(
    userId: string,
    userRole: 'student' | 'faculty',
    token: string,
  ): Promise<void> {
    if (!token?.trim()) return;
    if (userRole === 'faculty') {
      await this.prisma.faculty.update({
        where: { id: userId },
        data: { fcmToken: token },
      });
    } else {
      await this.prisma.student.update({
        where: { id: userId },
        data: { fcmToken: token },
      });
    }
    this.logger.log(`[FCM] Token registered for ${userRole}:${userId.slice(0, 8)}`);
  }

  // ─── Canteen: Queue Count (smart poll) ─────────────────────
  // Lightweight endpoint — returns only {count, latestOrderedAt}
  // Used by canteen frontend smart-poll to detect new orders without
  // fetching the full order list every few seconds.

  async getOrderQueueCount(): Promise<{
    count: number;
    latestOrderedAt: string | null;
  }> {
    const result = await this.prisma.order.aggregate({
      where: {
        status: 'paid',
        hiddenFromCanteenAt: null,
        printedAt: null,
      },
      _count: { id: true },
      _max: { orderedAt: true },
    });
    return {
      count: result._count.id,
      latestOrderedAt: result._max.orderedAt?.toISOString() ?? null,
    };
  }

  // ─── Canteen: Verify & Complete by Token or QR ─────────────

  async verifyAndCompleteByToken(token: string, canteenUserId: string) {
    this.logger.log(
      `[VERIFY] verifyAndCompleteByToken token=${token} by canteen=${canteenUserId}`,
    );

    // Look up by token number (today's orders first, then all time as fallback)
    const order = await this.prisma.order.findFirst({
      where: { tokenNumber: token },
      include: {
        items: true,
        student: { select: { id: true, name: true, phoneNumber: true, email: true } },
        faculty: { select: { id: true, name: true, phoneNumber: true, email: true, department: true, roomNumber: true } },
        paymentTransaction: true,
      },
      orderBy: { orderedAt: 'desc' },
    });

    if (!order) {
      return { found: false, reason: 'TOKEN_NOT_FOUND', message: 'No order found for this token' };
    }

    if (order.status === 'created' || order.status === 'payment_pending') {
      return { found: true, order, reason: 'NOT_PAID', message: 'Order has not been paid yet' };
    }

    if (order.status === 'cancelled') {
      return { found: true, order, reason: 'CANCELLED', message: 'This order was cancelled' };
    }

    if (order.status === 'completed') {
      return { found: true, order, reason: 'ALREADY_COMPLETED', message: 'This order has already been collected' };
    }

    // status === 'paid' → safe to complete
    const completed = await this.prisma.order.update({
      where: { id: order.id },
      data: { status: 'completed', completedAt: new Date() },
      include: {
        items: true,
        student: { select: { id: true, name: true, phoneNumber: true, email: true } },
        faculty: { select: { id: true, name: true, phoneNumber: true, email: true, department: true, roomNumber: true } },
        paymentTransaction: true,
      },
    });

    this.logger.log(
      `[VERIFY] Order ${order.id} (token=${token}) completed by canteen=${canteenUserId}`,
    );

    return { found: true, order: completed, reason: 'COMPLETED', message: 'Order verified and marked as collected' };
  }

  // ─── Finalize Paid Order ───────────────────────────────────

  async finalizeOrder(orderId: string) {
    const order = await this.prisma.order.update({
      where: { id: orderId },
      data: {
        status: 'paid',
        paymentStatus: 'paid',
      },
      include: {
        items: true,
        student: true,
        paymentTransaction: true,
      },
    });

    // Generate receipt
    await this.generateReceipt(order);

    return order;
  }

  // ─── Get Slip/Receipt ─────────────────────────────────────

  async getSlip(orderId: string) {
    const receipt = await this.prisma.receipt.findUnique({
      where: { orderId },
    });
    if (receipt) {
      return receipt;
    }

    // Generate on the fly if not found
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      include: {
        items: true,
        student: true,
        paymentTransaction: true,
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return this.generateReceipt(order);
  }

  // ─── Private Helpers ──────────────────────────────────────

  private async generateToken(): Promise<string> {
    // Generate a 4-digit token, check for uniqueness today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    let token: string;
    let exists = true;
    let attempts = 0;

    do {
      token = Math.floor(1000 + Math.random() * 9000).toString();
      const existing = await this.prisma.order.findFirst({
        where: {
          tokenNumber: token,
          orderedAt: { gte: today, lt: tomorrow },
        },
      });
      exists = !!existing;
      attempts++;
    } while (exists && attempts < 50);

    return token;
  }

  private async generateReceipt(order: any) {
    const printablePayload = {
      slipId: `SLIP-${order.tokenNumber}`,
      orderId: order.id,
      tokenNumber: order.tokenNumber,
      studentName: order.student?.name || 'N/A',
      studentPhone: order.student?.phoneNumber || '',
      items: order.items.map((item: any) => ({
        name: item.itemNameSnapshot,
        qty: item.quantity,
        unitPrice: item.unitPriceSnapshot,
        lineTotal: item.lineTotal,
        isVeg: item.isVeg,
      })),
      subtotal: order.subtotal,
      total: order.total,
      paymentStatus: order.paymentStatus,
      paymentMethod: order.paymentMethod || 'razorpay',
      razorpayPaymentId: order.paymentTransaction?.razorpayPaymentId || null,
      scheduledFor: order.scheduledFor?.toISOString() || null,
      estimatedReadyAt: order.estimatedReadyAt?.toISOString() || null,
      orderDate: order.orderedAt,
      generatedAt: new Date().toISOString(),
      printText: this.buildPrintText(order),
    };

    return this.prisma.receipt.upsert({
      where: { orderId: order.id },
      create: {
        orderId: order.id,
        printablePayloadJson: printablePayload,
      },
      update: {
        printablePayloadJson: printablePayload,
        generatedAt: new Date(),
      },
    });
  }

  private buildPrintText(order: any): string {
    const lines: string[] = [];
    lines.push('================================');
    lines.push('        CAMPUS EATS');
    lines.push('================================');
    lines.push(`Token: #${order.tokenNumber}`);
    lines.push(`Order: ${order.id.slice(0, 8)}`);
    lines.push(`Date: ${new Date(order.orderedAt).toLocaleString()}`);
    if (order.scheduledFor) {
      lines.push(`Scheduled: ${new Date(order.scheduledFor).toLocaleTimeString()}`);
    }
    if (order.estimatedReadyAt) {
      lines.push(`Ready by: ${new Date(order.estimatedReadyAt).toLocaleTimeString()}`);
    }
    lines.push('--------------------------------');
    lines.push(`Student: ${order.student?.name || 'N/A'}`);
    lines.push('--------------------------------');
    lines.push('Item           Qty   Amount');
    lines.push('--------------------------------');
    for (const item of order.items) {
      const name = item.itemNameSnapshot.padEnd(15).slice(0, 15);
      const qty = String(item.quantity).padStart(3);
      const amt = String(item.lineTotal.toFixed(0)).padStart(8);
      lines.push(`${name}${qty}${amt}`);
    }
    lines.push('--------------------------------');
    lines.push(`TOTAL: Rs. ${order.total.toFixed(0)}`.padStart(32));
    lines.push(`Payment: ${order.paymentStatus.toUpperCase()}`);
    lines.push('================================');
    lines.push('     Thank you! Visit again.');
    lines.push('================================');
    return lines.join('\n');
  }
}
