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
var OrderService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let OrderService = OrderService_1 = class OrderService {
    prisma;
    logger = new common_1.Logger(OrderService_1.name);
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createOrder(studentId, dto) {
        this.logger.log(`[ORDER] createOrder for student: ${studentId}, items: ${JSON.stringify(dto.items)}`);
        let scheduledFor = null;
        if (dto.scheduledFor) {
            const parsed = new Date(dto.scheduledFor);
            if (isNaN(parsed.getTime())) {
                throw new common_1.BadRequestException('Invalid scheduledFor date format');
            }
            const nowMs = Date.now();
            const diffMs = parsed.getTime() - nowMs;
            const diffMin = diffMs / 60_000;
            if (diffMin < 30) {
                throw new common_1.BadRequestException('Scheduled time must be at least 30 minutes from now');
            }
            if (diffMin > 120) {
                throw new common_1.BadRequestException('Scheduled time cannot be more than 2 hours ahead');
            }
            scheduledFor = parsed;
            this.logger.log(`[ORDER] Scheduled order for ${parsed.toISOString()} (${Math.round(diffMin)} min from now)`);
        }
        const menuItemIds = dto.items.map((item) => item.menuItemId);
        const menuItems = await this.prisma.menuItem.findMany({
            where: { id: { in: menuItemIds }, isAvailable: true },
        });
        if (menuItems.length !== menuItemIds.length) {
            const foundIds = menuItems.map((m) => m.id);
            const missing = menuItemIds.filter((id) => !foundIds.includes(id));
            throw new common_1.BadRequestException(`Menu items not found or unavailable: ${missing.join(', ')}`);
        }
        const menuMap = new Map(menuItems.map((m) => [m.id, m]));
        let subtotal = 0;
        const orderItems = dto.items.map((item) => {
            const menu = menuMap.get(item.menuItemId);
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
        let estimatedReadyAt = null;
        if (!scheduledFor) {
            const maxPrepMinutes = Math.max(...menuItems.map((m) => m.prepTimeMinutes ?? 5));
            const buffer = 5;
            const now = new Date();
            const istOffsetMs = 5.5 * 60 * 60 * 1000;
            const istHour = new Date(now.getTime() + istOffsetMs).getUTCHours();
            const rushExtra = istHour >= 11 && istHour < 14 ? 10 : 0;
            const totalMinutes = maxPrepMinutes + buffer + rushExtra;
            estimatedReadyAt = new Date(now.getTime() + totalMinutes * 60_000);
            this.logger.log(`[ETA] Computed: maxPrep=${maxPrepMinutes}min buffer=${buffer}min istHour=${istHour} rush=${rushExtra}min → ready at ${estimatedReadyAt.toISOString()}`);
        }
        const tokenNumber = await this.generateToken();
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
    async getStudentOrders(studentId) {
        return this.prisma.order.findMany({
            where: { studentId },
            include: {
                items: true,
                paymentTransaction: true,
            },
            orderBy: { orderedAt: 'desc' },
        });
    }
    async getOrderById(orderId) {
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: {
                items: true,
                student: true,
                paymentTransaction: true,
                receipt: true,
            },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
        return order;
    }
    async getCanteenOrders(status) {
        const where = {
            hiddenFromCanteenAt: null,
        };
        if (status) {
            where.status = status;
            this.logger.log(`[CANTEEN] getCanteenOrders with filter status=${status}`);
        }
        else {
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
                paymentTransaction: true,
            },
            orderBy: { orderedAt: 'desc' },
        });
    }
    async getCanteenReports() {
        const now = new Date();
        const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;
        const nowIst = new Date(now.getTime() + IST_OFFSET_MS);
        const istMidnightUTC = new Date(Date.UTC(nowIst.getUTCFullYear(), nowIst.getUTCMonth(), nowIst.getUTCDate()) - IST_OFFSET_MS);
        const todayStart = istMidnightUTC;
        const todayEnd = new Date(istMidnightUTC.getTime() + 86_400_000 - 1);
        const monthStartIstMs = Date.UTC(nowIst.getUTCFullYear(), nowIst.getUTCMonth(), 1);
        const monthEndIstMs = Date.UTC(nowIst.getUTCFullYear(), nowIst.getUTCMonth() + 1, 1) - 1;
        const monthStart = new Date(monthStartIstMs - IST_OFFSET_MS);
        const monthEnd = new Date(monthEndIstMs - IST_OFFSET_MS);
        const paidStatuses = ['paid', 'completed'];
        const todayOrders = await this.prisma.order.findMany({
            where: {
                status: { in: paidStatuses },
                orderedAt: { gte: todayStart, lte: todayEnd },
            },
            include: { items: true },
        });
        const todayRevenue = todayOrders.reduce((s, o) => s + o.total, 0);
        const monthOrders = await this.prisma.order.findMany({
            where: {
                status: { in: paidStatuses },
                orderedAt: { gte: monthStart, lte: monthEnd },
            },
            include: { items: true },
        });
        const monthRevenue = monthOrders.reduce((s, o) => s + o.total, 0);
        const allOrderItems = await this.prisma.orderItem.groupBy({
            by: ['itemNameSnapshot'],
            _sum: { quantity: true },
            orderBy: { _sum: { quantity: 'desc' } },
            take: 5,
        });
        const daysPassed = nowIst.getUTCDate();
        const avgDailyOrders = daysPassed > 0
            ? Math.round((monthOrders.length / daysPassed) * 10) / 10
            : 0;
        this.logger.log(`[REPORTS] IST date=${nowIst.toUTCString()} today=${todayOrders.length} Rs.${todayRevenue} | month=${monthOrders.length} Rs.${monthRevenue}`);
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
    async clearCompletedHistory(canteenUserId) {
        this.logger.log(`[CANTEEN] clearCompletedHistory (soft-archive) requested by canteen user: ${canteenUserId}`);
        const result = await this.prisma.order.updateMany({
            where: {
                status: 'completed',
                hiddenFromCanteenAt: null,
            },
            data: {
                hiddenFromCanteenAt: new Date(),
            },
        });
        this.logger.log(`[CANTEEN] Soft-archived ${result.count} completed orders (hiddenFromCanteenAt set)`);
        return { cleared: result.count };
    }
    async printOrder(orderId) {
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: { items: true, student: true },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
        const updated = await this.prisma.order.update({
            where: { id: orderId },
            data: { printedAt: order.printedAt ?? new Date() },
            include: { items: true, student: true },
        });
        this.logger.log(`[CANTEEN] printOrder orderId=${orderId} printedAt=${updated.printedAt?.toISOString()}`);
        return updated;
    }
    async updateOrderStatus(orderId, dto) {
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
        const allowedTransitions = {
            paid: ['completed', 'cancelled'],
            completed: [],
            cancelled: [],
        };
        const allowed = allowedTransitions[order.status] || [];
        if (!allowed.includes(dto.status)) {
            throw new common_1.BadRequestException(`Cannot transition from '${order.status}' to '${dto.status}'`);
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
    async finalizeOrder(orderId) {
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
        await this.generateReceipt(order);
        return order;
    }
    async getSlip(orderId) {
        const receipt = await this.prisma.receipt.findUnique({
            where: { orderId },
        });
        if (receipt) {
            return receipt;
        }
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: {
                items: true,
                student: true,
                paymentTransaction: true,
            },
        });
        if (!order)
            throw new common_1.NotFoundException('Order not found');
        return this.generateReceipt(order);
    }
    async generateToken() {
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        let token;
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
    async generateReceipt(order) {
        const printablePayload = {
            slipId: `SLIP-${order.tokenNumber}`,
            orderId: order.id,
            tokenNumber: order.tokenNumber,
            studentName: order.student?.name || 'N/A',
            studentPhone: order.student?.phoneNumber || '',
            items: order.items.map((item) => ({
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
    buildPrintText(order) {
        const lines = [];
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
};
exports.OrderService = OrderService;
exports.OrderService = OrderService = OrderService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], OrderService);
//# sourceMappingURL=orders.service.js.map