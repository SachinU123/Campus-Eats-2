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
exports.CanteenReportsController = exports.CanteenOrderController = exports.OrderController = void 0;
const common_1 = require("@nestjs/common");
const orders_service_js_1 = require("./orders.service.js");
const order_dto_js_1 = require("./dto/order.dto.js");
const jwt_auth_guard_js_1 = require("../common/guards/jwt-auth.guard.js");
const roles_guard_js_1 = require("../common/guards/roles.guard.js");
const roles_decorator_js_1 = require("../common/decorators/roles.decorator.js");
const current_user_decorator_js_1 = require("../common/decorators/current-user.decorator.js");
const api_response_dto_js_1 = require("../common/dto/api-response.dto.js");
let OrderController = class OrderController {
    orderService;
    constructor(orderService) {
        this.orderService = orderService;
    }
    async createOrder(callerId, callerRole, dto) {
        const order = await this.orderService.createOrder(callerId, dto, callerRole);
        return api_response_dto_js_1.ApiResponse.ok(order, 'Order created');
    }
    async getMyOrders(callerId, callerRole) {
        if (callerRole === 'faculty') {
            const orders = await this.orderService.getFacultyOrders(callerId);
            return api_response_dto_js_1.ApiResponse.ok(orders, 'Orders retrieved');
        }
        const orders = await this.orderService.getStudentOrders(callerId);
        return api_response_dto_js_1.ApiResponse.ok(orders, 'Orders retrieved');
    }
    async registerFcmToken(userId, userRole, body) {
        if (!body?.token || typeof body.token !== 'string') {
            return api_response_dto_js_1.ApiResponse.ok({}, 'Token skipped — empty');
        }
        await this.orderService.registerFcmToken(userId, userRole, body.token);
        return api_response_dto_js_1.ApiResponse.ok({}, 'FCM token registered');
    }
    async getOrderById(id) {
        const order = await this.orderService.getOrderById(id);
        return api_response_dto_js_1.ApiResponse.ok(order, 'Order retrieved');
    }
    async getSlip(id) {
        const slip = await this.orderService.getSlip(id);
        return api_response_dto_js_1.ApiResponse.ok(slip, 'Slip retrieved');
    }
};
exports.OrderController = OrderController;
__decorate([
    (0, common_1.Post)(),
    (0, common_1.UseGuards)(roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('student', 'faculty'),
    __param(0, (0, current_user_decorator_js_1.CurrentUser)('sub')),
    __param(1, (0, current_user_decorator_js_1.CurrentUser)('role')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, order_dto_js_1.CreateOrderDto]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "createOrder", null);
__decorate([
    (0, common_1.Get)('my'),
    (0, common_1.UseGuards)(roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('student', 'faculty'),
    __param(0, (0, current_user_decorator_js_1.CurrentUser)('sub')),
    __param(1, (0, current_user_decorator_js_1.CurrentUser)('role')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "getMyOrders", null);
__decorate([
    (0, common_1.Post)('fcm-token'),
    (0, common_1.UseGuards)(roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('student', 'faculty'),
    __param(0, (0, current_user_decorator_js_1.CurrentUser)('sub')),
    __param(1, (0, current_user_decorator_js_1.CurrentUser)('role')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "registerFcmToken", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "getOrderById", null);
__decorate([
    (0, common_1.Get)(':id/slip'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "getSlip", null);
exports.OrderController = OrderController = __decorate([
    (0, common_1.Controller)('orders'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    __metadata("design:paramtypes", [orders_service_js_1.OrderService])
], OrderController);
let CanteenOrderController = class CanteenOrderController {
    orderService;
    constructor(orderService) {
        this.orderService = orderService;
    }
    async getCanteenOrders(status) {
        const orders = await this.orderService.getCanteenOrders(status);
        return api_response_dto_js_1.ApiResponse.ok(orders, 'Canteen orders retrieved');
    }
    async pollOrders() {
        const data = await this.orderService.getOrderQueueCount();
        return api_response_dto_js_1.ApiResponse.ok(data, 'Poll OK');
    }
    async getOrderById(id) {
        const order = await this.orderService.getOrderById(id);
        return api_response_dto_js_1.ApiResponse.ok(order, 'Order retrieved');
    }
    async getSlip(id) {
        const slip = await this.orderService.getSlip(id);
        return api_response_dto_js_1.ApiResponse.ok(slip, 'Slip retrieved');
    }
    async verifyOrder(body, canteenUserId) {
        if (!body?.token || typeof body.token !== 'string' || body.token.trim().length === 0) {
            return api_response_dto_js_1.ApiResponse.ok({ found: false, reason: 'INVALID_TOKEN', message: 'Token is required' }, 'Invalid token');
        }
        const result = await this.orderService.verifyAndCompleteByToken(body.token.trim(), canteenUserId);
        return api_response_dto_js_1.ApiResponse.ok(result, result.message);
    }
    async completeOrder(id, dto) {
        const order = await this.orderService.updateOrderStatus(id, dto);
        return api_response_dto_js_1.ApiResponse.ok(order, `Order status updated to ${dto.status}`);
    }
    async printOrder(id) {
        const order = await this.orderService.printOrder(id);
        return api_response_dto_js_1.ApiResponse.ok(order, 'Order marked as printed');
    }
    async markOrderReady(id) {
        const order = await this.orderService.markOrderReady(id);
        return api_response_dto_js_1.ApiResponse.ok(order, 'Order marked as ready — notification dispatched');
    }
};
exports.CanteenOrderController = CanteenOrderController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, common_1.Query)('status')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "getCanteenOrders", null);
__decorate([
    (0, common_1.Get)('poll'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "pollOrders", null);
__decorate([
    (0, common_1.Get)(':id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "getOrderById", null);
__decorate([
    (0, common_1.Get)(':id/slip'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "getSlip", null);
__decorate([
    (0, common_1.Post)('verify'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_js_1.CurrentUser)('sub')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "verifyOrder", null);
__decorate([
    (0, common_1.Patch)(':id/complete'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, order_dto_js_1.UpdateOrderStatusDto]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "completeOrder", null);
__decorate([
    (0, common_1.Patch)(':id/print'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "printOrder", null);
__decorate([
    (0, common_1.Patch)(':id/ready'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenOrderController.prototype, "markOrderReady", null);
exports.CanteenOrderController = CanteenOrderController = __decorate([
    (0, common_1.Controller)('canteen/orders'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __metadata("design:paramtypes", [orders_service_js_1.OrderService])
], CanteenOrderController);
let CanteenReportsController = class CanteenReportsController {
    orderService;
    constructor(orderService) {
        this.orderService = orderService;
    }
    async getReports() {
        const data = await this.orderService.getCanteenReports();
        return api_response_dto_js_1.ApiResponse.ok(data, 'Reports retrieved');
    }
    async clearCompletedHistory(canteenUserId) {
        const result = await this.orderService.clearCompletedHistory(canteenUserId);
        return api_response_dto_js_1.ApiResponse.ok(result, `Cleared ${result.cleared} completed orders`);
    }
};
exports.CanteenReportsController = CanteenReportsController;
__decorate([
    (0, common_1.Get)('reports'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], CanteenReportsController.prototype, "getReports", null);
__decorate([
    (0, common_1.Delete)('history/completed'),
    __param(0, (0, current_user_decorator_js_1.CurrentUser)('sub')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], CanteenReportsController.prototype, "clearCompletedHistory", null);
exports.CanteenReportsController = CanteenReportsController = __decorate([
    (0, common_1.Controller)('canteen'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __metadata("design:paramtypes", [orders_service_js_1.OrderService])
], CanteenReportsController);
//# sourceMappingURL=orders.controller.js.map