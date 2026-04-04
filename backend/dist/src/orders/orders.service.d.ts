import { PrismaService } from '../prisma/prisma.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';
export declare class OrderService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    createOrder(studentId: string, dto: CreateOrderDto): Promise<{
        items: ({
            menuItem: {
                id: string;
                name: string;
                createdAt: Date;
                updatedAt: Date;
                emoji: string;
                isPopular: boolean;
                categoryId: string;
                description: string;
                imageUrl: string;
                price: number;
                isVeg: boolean;
                isAvailable: boolean;
            };
        } & {
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
        })[];
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
    }>;
    getStudentOrders(studentId: string): Promise<({
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
    })[]>;
    getOrderById(orderId: string): Promise<{
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
        receipt: {
            id: string;
            createdAt: Date;
            orderId: string;
            printablePayloadJson: import("@prisma/client/runtime/client").JsonValue;
            generatedAt: Date;
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
    }>;
    getCanteenOrders(status?: string): Promise<({
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
            email: string;
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
    })[]>;
    updateOrderStatus(orderId: string, dto: UpdateOrderStatusDto): Promise<{
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
    }>;
    finalizeOrder(orderId: string): Promise<{
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
    }>;
    getSlip(orderId: string): Promise<{
        id: string;
        createdAt: Date;
        orderId: string;
        printablePayloadJson: import("@prisma/client/runtime/client").JsonValue;
        generatedAt: Date;
    }>;
    private generateToken;
    private generateReceipt;
    private buildPrintText;
}
