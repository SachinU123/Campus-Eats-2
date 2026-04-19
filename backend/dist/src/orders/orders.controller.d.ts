import { OrderService } from './orders.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
export declare class OrderController {
    private readonly orderService;
    constructor(orderService: OrderService);
    createOrder(callerId: string, callerRole: string, dto: CreateOrderDto): Promise<ApiResponse<{
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
                isUnavailableToday: boolean;
                isSpecial: boolean;
                specialLabel: string;
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
            fcmToken: string | null;
        } | null;
        faculty: {
            id: string;
            phoneNumber: string;
            name: string;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            email: string;
            passwordHash: string;
            fcmToken: string | null;
            department: string;
            roomNumber: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    getMyOrders(callerId: string, callerRole: string): Promise<ApiResponse<({
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
            gateway: string;
            razorpayOrderId: string | null;
            razorpayPaymentId: string | null;
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
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    })[]>>;
    registerFcmToken(userId: string, userRole: string, body: {
        token: string;
    }): Promise<ApiResponse<{}>>;
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
            fcmToken: string | null;
        } | null;
        paymentTransaction: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            status: string;
            orderId: string;
            gateway: string;
            razorpayOrderId: string | null;
            razorpayPaymentId: string | null;
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
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
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
        } | null;
        faculty: {
            id: string;
            phoneNumber: string;
            name: string;
            email: string;
            department: string;
            roomNumber: string;
        } | null;
        paymentTransaction: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            status: string;
            orderId: string;
            gateway: string;
            razorpayOrderId: string | null;
            razorpayPaymentId: string | null;
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
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    })[]>>;
    pollOrders(): Promise<ApiResponse<{
        count: number;
        latestOrderedAt: string | null;
    }>>;
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
            fcmToken: string | null;
        } | null;
        paymentTransaction: {
            id: string;
            createdAt: Date;
            updatedAt: Date;
            status: string;
            orderId: string;
            gateway: string;
            razorpayOrderId: string | null;
            razorpayPaymentId: string | null;
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
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    getSlip(id: string): Promise<ApiResponse<{
        id: string;
        createdAt: Date;
        orderId: string;
        printablePayloadJson: import("@prisma/client/runtime/client").JsonValue;
        generatedAt: Date;
    }>>;
    verifyOrder(body: {
        token: string;
    }, canteenUserId: string): Promise<ApiResponse<{
        found: boolean;
        reason: string;
        message: string;
    }>>;
    completeOrder(id: string, dto: UpdateOrderStatusDto): Promise<ApiResponse<({
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
            fcmToken: string | null;
        } | null;
        faculty: {
            id: string;
            phoneNumber: string;
            name: string;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            email: string;
            passwordHash: string;
            fcmToken: string | null;
            department: string;
            roomNumber: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }) | null>>;
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
            fcmToken: string | null;
        } | null;
        faculty: {
            id: string;
            phoneNumber: string;
            name: string;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            email: string;
            passwordHash: string;
            fcmToken: string | null;
            department: string;
            roomNumber: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
        hiddenFromCanteenAt: Date | null;
    }>>;
    markOrderReady(id: string): Promise<ApiResponse<{
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
            fcmToken: string | null;
        } | null;
        faculty: {
            id: string;
            phoneNumber: string;
            name: string;
            isActive: boolean;
            createdAt: Date;
            updatedAt: Date;
            email: string;
            passwordHash: string;
            fcmToken: string | null;
            department: string;
            roomNumber: string;
        } | null;
    } & {
        id: string;
        createdAt: Date;
        updatedAt: Date;
        studentId: string | null;
        facultyId: string | null;
        notes: string | null;
        scheduledFor: Date | null;
        status: string;
        customerRole: string;
        tokenNumber: string;
        subtotal: number;
        total: number;
        paymentStatus: string;
        paymentMethod: string | null;
        estimatedReadyAt: Date | null;
        orderedAt: Date;
        completedAt: Date | null;
        printedAt: Date | null;
        readyAt: Date | null;
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
