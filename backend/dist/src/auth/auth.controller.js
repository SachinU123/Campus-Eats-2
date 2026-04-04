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
exports.AuthController = void 0;
const common_1 = require("@nestjs/common");
const auth_service_js_1 = require("./auth.service.js");
const auth_dto_js_1 = require("./dto/auth.dto.js");
const jwt_auth_guard_js_1 = require("../common/guards/jwt-auth.guard.js");
const current_user_decorator_js_1 = require("../common/decorators/current-user.decorator.js");
const api_response_dto_js_1 = require("../common/dto/api-response.dto.js");
let AuthController = class AuthController {
    authService;
    constructor(authService) {
        this.authService = authService;
    }
    async studentRegister(dto) {
        const result = await this.authService.registerStudent(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, 'Registration successful');
    }
    async studentLogin(dto) {
        const result = await this.authService.loginStudent(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, 'Login successful');
    }
    async canteenRequestOtp(dto) {
        const result = await this.authService.requestCanteenOtp(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, result.message);
    }
    async canteenVerifyOtp(dto) {
        const result = await this.authService.verifyCanteenOtp(dto);
        return api_response_dto_js_1.ApiResponse.ok(result, 'OTP verified successfully');
    }
    async refresh(dto) {
        const tokens = await this.authService.refreshToken(dto);
        return api_response_dto_js_1.ApiResponse.ok(tokens, 'Token refreshed');
    }
    async logout(dto) {
        const result = await this.authService.logout(dto.refreshToken);
        return api_response_dto_js_1.ApiResponse.ok(result, result.message);
    }
    async getProfile(user) {
        const profile = await this.authService.getProfile(user.sub, user.role);
        return api_response_dto_js_1.ApiResponse.ok(profile, 'Profile retrieved');
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('student/register'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.StudentRegisterDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "studentRegister", null);
__decorate([
    (0, common_1.Post)('student/login'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.StudentLoginDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "studentLogin", null);
__decorate([
    (0, common_1.Post)('canteen/request-otp'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.CanteenRequestOtpDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "canteenRequestOtp", null);
__decorate([
    (0, common_1.Post)('canteen/verify-otp'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.CanteenVerifyOtpDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "canteenVerifyOtp", null);
__decorate([
    (0, common_1.Post)('refresh'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.RefreshTokenDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "refresh", null);
__decorate([
    (0, common_1.Post)('logout'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.LogoutDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "logout", null);
__decorate([
    (0, common_1.Get)('me'),
    (0, common_1.UseGuards)(jwt_auth_guard_js_1.JwtAuthGuard),
    __param(0, (0, current_user_decorator_js_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getProfile", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('auth'),
    __metadata("design:paramtypes", [auth_service_js_1.AuthService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map