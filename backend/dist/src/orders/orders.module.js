"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrdersModule = void 0;
const common_1 = require("@nestjs/common");
const orders_service_js_1 = require("./orders.service.js");
const orders_controller_js_1 = require("./orders.controller.js");
const auth_module_js_1 = require("../auth/auth.module.js");
let OrdersModule = class OrdersModule {
};
exports.OrdersModule = OrdersModule;
exports.OrdersModule = OrdersModule = __decorate([
    (0, common_1.Module)({
        imports: [auth_module_js_1.AuthModule],
        controllers: [orders_controller_js_1.OrderController, orders_controller_js_1.CanteenOrderController, orders_controller_js_1.CanteenReportsController],
        providers: [orders_service_js_1.OrderService],
        exports: [orders_service_js_1.OrderService],
    })
], OrdersModule);
//# sourceMappingURL=orders.module.js.map