import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { OrderService } from '../orders/orders.service.js';
import { CreatePaymentOrderDto, VerifyPaymentDto } from './dto/payment.dto.js';
export declare class PaymentService {
    private readonly prisma;
    private readonly config;
    private readonly orderService;
    private razorpay;
    constructor(prisma: PrismaService, config: ConfigService, orderService: OrderService);
    private initRazorpay;
    createPaymentOrder(dto: CreatePaymentOrderDto): Promise<{
        razorpayOrderId: any;
        amount: number;
        currency: string;
        keyId: string | undefined;
    }>;
    verifyPayment(dto: VerifyPaymentDto): Promise<{
        verified: boolean;
        order: {
            items: {
                id: string;
                createdAt: Date;
                emoji: string;
                isVeg: boolean;
                menuItemId: string;
                quantity: number;
                itemNameSnapshot: string;
                unitPriceSnapshot: number;
                lineTotal: number;
                orderId: string;
            }[];
            student: {
                id: string;
                phoneNumber: string;
                name: string;
                isActive: boolean;
                createdAt: Date;
                updatedAt: Date;
                email: string;
                passwordHash: string;
            };
            paymentTransaction: {
                id: string;
                createdAt: Date;
                updatedAt: Date;
                status: string;
                orderId: string;
                razorpayPaymentId: string | null;
                razorpayOrderId: string | null;
                razorpaySignature: string | null;
                gateway: string;
                amount: number;
                currency: string;
                paidAt: Date | null;
                rawPayloadJson: import("@prisma/client/runtime/client").JsonValue | null;
            } | null;
        } & {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            studentId: string;
            notes: string | null;
            status: string;
            tokenNumber: string;
            subtotal: number;
            total: number;
            paymentStatus: string;
            paymentMethod: string | null;
            orderedAt: Date;
            completedAt: Date | null;
        };
    }>;
    getPaymentByOrderId(orderId: string): Promise<{
        id: string;
        createdAt: Date;
        updatedAt: Date;
        status: string;
        orderId: string;
        razorpayPaymentId: string | null;
        razorpayOrderId: string | null;
        razorpaySignature: string | null;
        gateway: string;
        amount: number;
        currency: string;
        paidAt: Date | null;
        rawPayloadJson: import("@prisma/client/runtime/client").JsonValue | null;
    }>;
}
