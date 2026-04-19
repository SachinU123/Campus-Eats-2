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
exports.SettingsController = void 0;
const common_1 = require("@nestjs/common");
const settings_service_js_1 = require("./settings.service.js");
const api_response_dto_js_1 = require("../common/dto/api-response.dto.js");
const jwt_auth_guard_js_1 = require("../common/guards/jwt-auth.guard.js");
const roles_guard_js_1 = require("../common/guards/roles.guard.js");
const roles_decorator_js_1 = require("../common/decorators/roles.decorator.js");
class SetCanteenStatusDto {
    status;
    message;
}
class SetStaffActiveDto {
    isActive;
}
function requireAdmin(req) {
    if (req.user?.canteenRole !== 'canteen_admin') {
        throw new common_1.ForbiddenException('Admin access required');
    }
}
let SettingsController = class SettingsController {
    settings;
    constructor(settings) {
        this.settings = settings;
    }
    async getStatus() {
        const status = await this.settings.getCanteenStatus();
        return api_response_dto_js_1.ApiResponse.ok(status, 'Status retrieved');
    }
    async setStatus(dto, req) {
        requireAdmin(req);
        const result = await this.settings.setCanteenStatus(dto.status, dto.message ?? '');
        return api_response_dto_js_1.ApiResponse.ok(result, `Canteen status set to ${dto.status}`);
    }
    async listStaff(req) {
        requireAdmin(req);
        const staff = await this.settings.listStaff();
        return api_response_dto_js_1.ApiResponse.ok(staff, 'Staff list retrieved');
    }
    async setStaffActive(id, dto, req) {
        requireAdmin(req);
        const updated = await this.settings.setStaffActive(id, dto.isActive);
        return api_response_dto_js_1.ApiResponse.ok(updated, dto.isActive ? 'Staff account enabled' : 'Staff account disabled');
    }
};
exports.SettingsController = SettingsController;
__decorate([
    (0, common_1.Get)('status'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "getStatus", null);
__decorate([
    (0, common_1.Patch)('status'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [SetCanteenStatusDto, Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "setStatus", null);
__decorate([
    (0, common_1.Get)('staff'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __param(0, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "listStaff", null);
__decorate([
    (0, common_1.Patch)('staff/:id/active'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SetStaffActiveDto, Object]),
    __metadata("design:returntype", Promise)
], SettingsController.prototype, "setStaffActive", null);
exports.SettingsController = SettingsController = __decorate([
    (0, common_1.Controller)('settings'),
    __metadata("design:paramtypes", [settings_service_js_1.SettingsService])
], SettingsController);
//# sourceMappingURL=settings.controller.js.map