import { PaymentService } from './payments.service.js';
import { CreatePaymentOrderDto, VerifyPaymentDto } from './dto/payment.dto.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
export declare class PaymentController {
    private readonly paymentService;
    constructor(paymentService: PaymentService);
    createPaymentOrder(dto: CreatePaymentOrderDto): Promise<ApiResponse<{
        razorpayOrderId: any;
        amount: number;
        currency: string;
        keyId: string | undefined;
    }>>;
    verifyPayment(dto: VerifyPaymentDto): Promise<ApiResponse<{
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
        };
    }>>;
    getPayment(orderId: string): Promise<ApiResponse<{
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
    }>>;
}
