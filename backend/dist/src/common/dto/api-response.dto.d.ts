export declare class ApiResponse<T = any> {
    success: boolean;
    message: string;
    data?: T;
    errors?: any;
    constructor(partial: Partial<ApiResponse<T>>);
    static ok<T>(data: T, message?: string): ApiResponse<T>;
    static error(message: string, errors?: any): ApiResponse;
}
