"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentsModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const payments_service_js_1 = require("./payments.service.js");
const payments_controller_js_1 = require("./payments.controller.js");
const orders_module_js_1 = require("../orders/orders.module.js");
const auth_module_js_1 = require("../auth/auth.module.js");
let PaymentsModule = class PaymentsModule {
};
exports.PaymentsModule = PaymentsModule;
exports.PaymentsModule = PaymentsModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule, orders_module_js_1.OrdersModule, auth_module_js_1.AuthModule],
        controllers: [payments_controller_js_1.PaymentController],
        providers: [payments_service_js_1.PaymentService],
        exports: [payments_service_js_1.PaymentService],
    })
], PaymentsModule);
//# sourceMappingURL=payments.module.js.map