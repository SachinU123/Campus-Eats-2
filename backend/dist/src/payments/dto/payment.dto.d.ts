export declare class CreatePaymentOrderDto {
    orderId: string;
}
export declare class VerifyPaymentDto {
    orderId: string;
    razorpayOrderId: string;
    razorpayPaymentId: string;
    razorpaySignature: string;
}
