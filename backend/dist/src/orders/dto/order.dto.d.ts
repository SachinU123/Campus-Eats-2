export declare class CreateOrderItemDto {
    menuItemId: string;
    quantity: number;
}
export declare class CreateOrderDto {
    items: CreateOrderItemDto[];
    notes?: string;
    scheduledFor?: string;
}
export declare class UpdateOrderStatusDto {
    status: string;
}
