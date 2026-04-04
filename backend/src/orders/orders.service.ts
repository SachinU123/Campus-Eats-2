import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';

@Injectable()
export class OrderService {
  constructor(private readonly prisma: PrismaService) {}

  // ─── Create Order ───────────────────────────────────────────

  async createOrder(studentId: string, dto: CreateOrderDto) {
    // Validate and fetch menu items
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

    // Calculate server-side totals
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

    const total = subtotal; // No additional fees for now

    // Generate token number (4-digit numeric, daily unique)
    const tokenNumber = await this.generateToken();

    // Create order with items in a transaction
    const order = await this.prisma.order.create({
      data: {
        studentId,
        tokenNumber,
        status: 'created',
        subtotal,
        total,
        paymentStatus: 'pending',
        notes: dto.notes,
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
    } else {
      // Default: show paid and completed orders
      where.status = { in: ['paid', 'completed'] };
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
      orderDate: order.orderedAt,
      generatedAt: new Date().toISOString(),
      // Plain text format for thermal printing
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
