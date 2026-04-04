"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentController = void 0;
const common_1 = require("@nestjs/common");
const payments_service_js_1 = require("./payments.service.js");
const payment_dto_js_1 = require("./dto/payment.dto.js");
const jwt_auth_guard_js_1 = require("../common/guards/jwt-auth.guard.js");
const api_response_dto_js_1 = require("../common/dto/api-response.dto.js");
let PaymentController = class PaymentController {
    paymentService;
    constructor(paymentService) {
        this.paymentService = paymentService;
    }
    async createPaymentOrder(dto) {
        const result = await this.paymentService.createPaymentOrder(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, 'Razorpay order created');
    }
    async verifyPayment(dto) {
        const result = await this.paymentService.verifyPayment(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, 'Payment verified successfully');
    }
    async getPayment(orderId) {
        const payment = await this.paymentService.getPaymentByOrderId(orderId);
        return api_response_dto_js_1.ApiResponse.ok(payment, 'Payment retrieved');
    }
};
exports.PaymentController = PaymentController;
__decorate([
    (0, common_1.Post)('create-order'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [payment_dto_js_1.CreatePaymentOrderDto]),
    __metadata("design:returntype", Promise)
], PaymentController.prototype, "createPaymentOrder", null);
__decorate([
    (0, common_1.Post)('verify'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [payment_dto_js_1.VerifyPaymentDto]),
    __metadata("design:returntype", Promise)
], PaymentController.prototype, "verifyPayment", null);
__decorate([
    (0, common_1.Get)(':orderId'),
    __param(0, (0, common_1.Param)('orderId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], PaymentController.prototype, "getPayment", null);
exports.PaymentController = PaymentController = __decorate([
    (0, common_1.Controller)('payments'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    __metadata("design:paramtypes", [payments_service_js_1.PaymentService])
], PaymentController);
//# sourceMappingURL=payments.controller.js.map