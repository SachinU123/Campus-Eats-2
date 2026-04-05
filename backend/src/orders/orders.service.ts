import {
  Injectable,
  NotFoundException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ─── Create Order ───────────────────────────────────────────

  async createOrder(studentId: string, dto: CreateOrderDto) {
    this.logger.log(
      `[ORDER] createOrder for student: ${studentId}, items: ${JSON.stringify(dto.items)}`,
    );

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
      where: { id: { in: menuItemIds }, isAvailable: true },
    });

    if (menuItems.length !== menuItemIds.length) {
      const foundIds = menuItems.map((m) => m.id);
      const missing = menuItemIds.filter((id) => !foundIds.includes(id));
      throw new BadRequestException(
        `Menu items not found or unavailable: ${missing.join(', ')}`,
      );
    }

    // ── Calculate server-side totals ─────────────────────────
    const menuMap = new Map(menuItems.map((m) => [m.id, m]));
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
        ...menuItems.map((m) => m.prepTimeMinutes ?? 5),
      );
      const buffer = 5; // standard kitchen buffer

      // Rush hour: 11:00 AM – 2:00 PM adds +10 minutes
      const now = new Date();
      const hour = now.getHours();
      const rushExtra = hour >= 11 && hour < 14 ? 10 : 0;

      const totalMinutes = maxPrepMinutes + buffer + rushExtra;
      estimatedReadyAt = new Date(now.getTime() + totalMinutes * 60_000);

      this.logger.log(
        `[ETA] Computed: maxPrep=${maxPrepMinutes}min buffer=${buffer}min rush=${rushExtra}min → ready at ${estimatedReadyAt.toISOString()}`,
      );
    }

    // ── Generate token ────────────────────────────────────────
    const tokenNumber = await this.generateToken();

    // ── Create order ──────────────────────────────────────────
    const order = await this.prisma.order.create({
      data: {
        studentId,
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
      },
    });

    return order;
  }

  // ─── Get Student Orders ─────────────────────────────────────

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
    const where: any = {};
    if (status) {
      where.status = status;
      this.logger.log(`[CANTEEN] getCanteenOrders with filter status=${status}`);
    } else {
      // Default: show paid and completed orders only
      where.status = { in: ['paid', 'completed'] };
      this.logger.log(`[CANTEEN] getCanteenOrders default filter: paid + completed`);
    }

    return this.prisma.order.findMany({
      where,
      include: {
        items: true,
        student: {
          select: { id: true, name: true, phoneNumber: true, email: true },
        },
        paymentTransaction: true,
      },
      orderBy: { orderedAt: 'desc' },
    });
  }

  // ─── Canteen: Reports ───────────────────────────────────────

  async getCanteenReports() {
    const now = new Date();

    // Today boundaries (midnight to midnight)
    const todayStart = new Date(now);
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date(now);
    todayEnd.setHours(23, 59, 59, 999);

    // This month boundaries
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

    // Paid statuses only (completed orders = real revenue)
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

    // Top items (across all time)
    const allOrderItems = await this.prisma.orderItem.groupBy({
      by: ['itemNameSnapshot'],
      _sum: { quantity: true },
      orderBy: { _sum: { quantity: 'desc' } },
      take: 5,
    });

    // Average daily orders (this month)
    const daysPassed = now.getDate();
    const avgDailyOrders =
      daysPassed > 0
        ? Math.round((monthOrders.length / daysPassed) * 10) / 10
        : 0;

    this.logger.log(
      `[REPORTS] today=${todayOrders.length} orders Rs.${todayRevenue} | month=${monthOrders.length} orders Rs.${monthRevenue}`,
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
      `[CANTEEN] clearCompletedHistory requested by canteen user: ${canteenUserId}`,
    );

    // Only delete orders in 'completed' status — NEVER active orders
    const result = await this.prisma.order.deleteMany({
      where: { status: 'completed' },
    });

    this.logger.log(`[CANTEEN] Cleared ${result.count} completed orders`);
    return { cleared: result.count };
  }

  // ─── Canteen: Update Order Status ──────────────────────────

  async updateOrderStatus(orderId: string, dto: UpdateOrderStatusDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
    });
    if (!order) throw new NotFoundException('Order not found');

    const allowedTransitions: Record<string, string[]> = {
      paid: ['completed', 'cancelled'],
      completed: [], // Final state
      cancelled: [], // Final state
    };

    const allowed = allowedTransitions[order.status] || [];
    if (!allowed.includes(dto.status)) {
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
      },
    });
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
