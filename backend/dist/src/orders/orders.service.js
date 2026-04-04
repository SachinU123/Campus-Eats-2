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
exports.OrderService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let OrderService = class OrderService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async createOrder(studentId, dto) {
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
        const where = {};
        if (status) {
            where.status = status;
        }
        else {
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
exports.OrderService = OrderService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService])
], OrderService);
//# sourceMappingURL=orders.service.js.map