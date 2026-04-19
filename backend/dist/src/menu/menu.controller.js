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
exports.MenuController = void 0;
const common_1 = require("@nestjs/common");
const menu_service_js_1 = require("./menu.service.js");
const api_response_dto_js_1 = require("../common/dto/api-response.dto.js");
const jwt_auth_guard_js_1 = require("../common/guards/jwt-auth.guard.js");
const roles_guard_js_1 = require("../common/guards/roles.guard.js");
const roles_decorator_js_1 = require("../common/decorators/roles.decorator.js");
class SetUnavailableTodayDto {
    isUnavailableToday;
}
class SetSpecialDto {
    isSpecial;
    specialLabel;
}
let MenuController = class MenuController {
    menuService;
    constructor(menuService) {
        this.menuService = menuService;
    }
    async getCategories() {
        const categories = await this.menuService.getCategories();
        return api_response_dto_js_1.ApiResponse.ok(categories, 'Categories retrieved');
    }
    async getItems(category, search) {
        if (search) {
            const items = await this.menuService.searchItems(search);
            return api_response_dto_js_1.ApiResponse.ok(items, 'Search results');
        }
        const items = await this.menuService.getItems(category);
        return api_response_dto_js_1.ApiResponse.ok(items, 'Items retrieved');
    }
    async getItemById(id) {
        const item = await this.menuService.getItemById(id);
        if (!item) {
            return api_response_dto_js_1.ApiResponse.error('Item not found');
        }
        return api_response_dto_js_1.ApiResponse.ok(item, 'Item retrieved');
    }
    async getAllItemsForManagement() {
        const items = await this.menuService.getAllItemsForManagement();
        return api_response_dto_js_1.ApiResponse.ok(items, 'Management list retrieved');
    }
    async setUnavailableToday(id, dto, req) {
        const item = await this.menuService.setUnavailableToday(id, dto.isUnavailableToday);
        return api_response_dto_js_1.ApiResponse.ok(item, dto.isUnavailableToday
            ? 'Item marked unavailable today'
            : 'Item marked available');
    }
    async setSpecial(id, dto, req) {
        const item = await this.menuService.setSpecial(id, dto.isSpecial, dto.specialLabel);
        return api_response_dto_js_1.ApiResponse.ok(item, dto.isSpecial ? 'Item marked as special' : 'Special flag cleared');
    }
};
exports.MenuController = MenuController;
__decorate([
    (0, common_1.Get)('categories'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "getCategories", null);
__decorate([
    (0, common_1.Get)('items'),
    __param(0, (0, common_1.Query)('category')),
    __param(1, (0, common_1.Query)('search')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "getItems", null);
__decorate([
    (0, common_1.Get)('items/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "getItemById", null);
__decorate([
    (0, common_1.Get)('manage'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "getAllItemsForManagement", null);
__decorate([
    (0, common_1.Patch)('items/:id/availability'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SetUnavailableTodayDto, Object]),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "setUnavailableToday", null);
__decorate([
    (0, common_1.Patch)('items/:id/special'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard, roles_guard_js_1.RolesGuard),
    (0, roles_decorator_js_1.Roles)('canteen'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, common_1.Request)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, SetSpecialDto, Object]),
    __metadata("design:returntype", Promise)
], MenuController.prototype, "setSpecial", null);
exports.MenuController = MenuController = __decorate([
    (0, common_1.Controller)('menu'),
    __metadata("design:paramtypes", [menu_service_js_1.MenuService])
], MenuController);
//# sourceMappingURL=menu.controller.js.map