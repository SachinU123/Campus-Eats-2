"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ApiResponse = void 0;
class ApiResponse {
    success;
    message;
    data;
    errors;
    constructor(partial) {
        Object.assign(this, partial);
    }
    static ok(data, message = 'Success') {
        return new ApiResponse({ success: true, message, data });
    }
    static error(message, errors) {
        return new ApiResponse({ success: false, message, errors });
    }
}
exports.ApiResponse = ApiResponse;
//# sourceMappingURL=api-response.dto.js.map