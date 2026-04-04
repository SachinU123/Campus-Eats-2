"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const crypto = __importStar(require("crypto"));
const prisma_service_js_1 = require("../prisma/prisma.service.js");
const orders_service_js_1 = require("../orders/orders.service.js");
let PaymentService = class PaymentService {
    prisma;
    config;
    orderService;
    razorpay;
    constructor(prisma, config, orderService) {
        this.prisma = prisma;
        this.config = config;
        this.orderService = orderService;
        this.initRazorpay();
    }
    async initRazorpay() {
        try {
            const Razorpay = (await import('razorpay')).default;
            this.razorpay = new Razorpay({
                key_id: this.config.get('RAZORPAY_KEY_ID'),
                key_secret: this.config.get('RAZORPAY_KEY_SECRET'),
            });
        }
        catch (err) {
            console.error('Failed to initialize Razorpay:', err);
        }
    }
    async createPaymentOrder(dto) {
        const order = await this.prisma.order.findUnique({
            where: { id: dto.orderId },
            include: { paymentTransaction: true },
        });
        if (!order) {
            throw new common_1.NotFoundException('Order not found');
        }
        if (order.paymentStatus === 'paid') {
            throw new common_1.BadRequestException('Order already paid');
        }
        if (order.paymentTransaction?.razorpayOrderId) {
            return {
                razorpayOrderId: order.paymentTransaction.razorpayOrderId,
                amount: order.total * 100,
                currency: 'INR',
                keyId: this.config.get('RAZORPAY_KEY_ID'),
            };
        }
        const amountInPaise = Math.round(order.total * 100);
        if (!this.razorpay) {
            await this.initRazorpay();
        }
        const razorpayOrder = await this.razorpay.orders.create({
            amount: amountInPaise,
            currency: 'INR',
            receipt: `receipt_${order.id.slice(0, 8)}`,
            notes: {
                orderId: order.id,
                tokenNumber: order.tokenNumber,
            },
        });
        await this.prisma.paymentTransaction.create({
            data: {
                orderId: order.id,
                gateway: 'razorpay',
                razorpayOrderId: razorpayOrder.id,
                amount: order.total,
                currency: 'INR',
                status: 'created',
            },
        });
        await this.prisma.order.update({
            where: { id: order.id },
            data: { status: 'payment_pending' },
        });
        return {
            razorpayOrderId: razorpayOrder.id,
            amount: amountInPaise,
            currency: 'INR',
            keyId: this.config.get('RAZORPAY_KEY_ID'),
        };
    }
    async verifyPayment(dto) {
        const order = await this.prisma.order.findUnique({
            where: { id: dto.orderId },
            include: { paymentTransaction: true },
        });
        if (!order) {
            throw new common_1.NotFoundException('Order not found');
        }
        if (!order.paymentTransaction) {
            throw new common_1.BadRequestException('No payment transaction found');
        }
        const keySecret = this.config.get('RAZORPAY_KEY_SECRET');
        const body = `${dto.razorpayOrderId}|${dto.razorpayPaymentId}`;
        const expectedSignature = crypto
            .createHmac('sha256', keySecret)
            .update(body)
            .digest('hex');
        const isValid = expectedSignature === dto.razorpaySignature;
        if (!isValid) {
            await this.prisma.paymentTransaction.update({
                where: { id: order.paymentTransaction.id },
                data: {
                    status: 'failed',
                    razorpayPaymentId: dto.razorpayPaymentId,
                    razorpaySignature: dto.razorpaySignature,
                    rawPayloadJson: {
                        verified: false,
                        error: 'Signature mismatch',
                    },
                },
            });
            await this.prisma.order.update({
                where: { id: order.id },
                data: { paymentStatus: 'failed' },
            });
            throw new common_1.BadRequestException('Payment verification failed');
        }
        await this.prisma.paymentTransaction.update({
            where: { id: order.paymentTransaction.id },
            data: {
                status: 'captured',
                razorpayPaymentId: dto.razorpayPaymentId,
                razorpaySignature: dto.razorpaySignature,
                paidAt: new Date(),
                rawPayloadJson: {
                    verified: true,
                    razorpayOrderId: dto.razorpayOrderId,
                    razorpayPaymentId: dto.razorpayPaymentId,
                },
            },
        });
        const finalizedOrder = await this.orderService.finalizeOrder(order.id);
        return {
            verified: true,
            order: finalizedOrder,
        };
    }
    async getPaymentByOrderId(orderId) {
        const payment = await this.prisma.paymentTransaction.findUnique({
            where: { orderId },
        });
        if (!payment)
            throw new common_1.NotFoundException('Payment not found');
        return payment;
    }
};
exports.PaymentService = PaymentService;
exports.PaymentService = PaymentService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService,
        config_1.ConfigService,
        orders_service_js_1.OrderService])
], PaymentService);
//# sourceMappingURL=payments.service.js.map