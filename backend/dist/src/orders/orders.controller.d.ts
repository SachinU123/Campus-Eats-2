import { OrderService } from './orders.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
export declare class OrderController {
    private readonly orderService;
    constructor(orderService: OrderService);
    createOrder(studentId: string, dto: CreateOrderDto): Promise<ApiResponse<{
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
                prepTimeMinutes: number;
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    getMyOrders(studentId: string): Promise<ApiResponse<({
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
            gateway: string;
            razorpayOrderId: string | null;
            razorpaySignature: string | null;
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    })[]>>;
    getOrderById(id: string): Promise<ApiResponse<{
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
            gateway: string;
            razorpayOrderId: string | null;
            razorpaySignature: string | null;
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    getSlip(id: string): Promise<ApiResponse<{
        id: string;
        createdAt: Date;
        orderId: string;
        printablePayloadJson: import("@prisma/client/runtime/client").JsonValue;
        generatedAt: Date;
    }>>;
}
export declare class CanteenOrderController {
    private readonly orderService;
    constructor(orderService: OrderService);
    getCanteenOrders(status?: string): Promise<ApiResponse<({
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
            gateway: string;
            razorpayOrderId: string | null;
            razorpaySignature: string | null;
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    })[]>>;
    getOrderById(id: string): Promise<ApiResponse<{
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
            gateway: string;
            razorpayOrderId: string | null;
            razorpaySignature: string | null;
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    getSlip(id: string): Promise<ApiResponse<{
        id: string;
        createdAt: Date;
        orderId: string;
        printablePayloadJson: import("@prisma/client/runtime/client").JsonValue;
        generatedAt: Date;
    }>>;
    completeOrder(id: string, dto: UpdateOrderStatusDto): Promise<ApiResponse<{
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    printOrder(id: string): Promise<ApiResponse<{
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
        scheduledFor: Date | null;
        status: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
}
export declare class CanteenReportsController {
    private readonly orderService;
    constructor(orderService: OrderService);
    getReports(): Promise<ApiResponse<{
        today: {
            orderCount: number;
            revenue: number;
        };
        thisMonth: {
            orderCount: number;
            revenue: number;
            avgDailyOrders: number;
        };
        topItems: {
            name: string;
            totalQuantity: number;
        }[];
    }>>;
    clearCompletedHistory(canteenUserId: string): Promise<ApiResponse<{
        cleared: number;
    }>>;
}
