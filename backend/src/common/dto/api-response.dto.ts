export class ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  errors?: any;

  constructor(partial: Partial<ApiResponse<T>>) {
    Object.assign(this, partial);
  }

  static ok<T>(data: T, message = 'Success'): ApiResponse<T> {
    return new ApiResponse({ success: true, message, data });
  }

  static error(message: string, errors?: any): ApiResponse {
    return new ApiResponse({ success: false, message, errors });
  }
}
