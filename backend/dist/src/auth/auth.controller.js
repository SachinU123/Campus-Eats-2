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
let AuthController = class AuthController {
    authService;
    constructor(authService) {
        this.authService = authService;
    }
    async studentRegister(dto) {
        return this.authService.registerStudent(dto);
    }
    async studentLogin(dto) {
        return this.authService.loginStudent(dto);
    }
    async facultyRegister(dto) {
        return this.authService.registerFaculty(dto);
    }
    async facultyLogin(dto) {
        return this.authService.loginFaculty(dto);
    }
    async requestCanteenOtp(dto) {
        return this.authService.requestCanteenOtp(dto);
    }
    async verifyCanteenOtp(dto) {
        return this.authService.verifyCanteenOtp(dto);
    }
    async refresh(dto) {
        return this.authService.refreshToken(dto);
    }
    async logout(dto) {
        return this.authService.logout(dto.refreshToken);
    }
    async getProfile(req) {
        return this.authService.getProfile(req.user.sub, req.user.role);
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('register'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.StudentRegisterDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "studentRegister", null);
__decorate([
    (0, common_1.Post)('login'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.StudentLoginDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "studentLogin", null);
__decorate([
    (0, common_1.Post)('faculty/register'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.FacultyRegisterDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "facultyRegister", null);
__decorate([
    (0, common_1.Post)('faculty/login'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.FacultyLoginDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "facultyLogin", null);
__decorate([
    (0, common_1.Post)('canteen/request-otp'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.CanteenRequestOtpDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "requestCanteenOtp", null);
__decorate([
    (0, common_1.Post)('canteen/verify-otp'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [auth_dto_js_1.CanteenVerifyOtpDto]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyCanteenOtp", null);
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
    __param(0, (0, common_1.Req)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "getProfile", null);
exports.AuthController = AuthController = __decorate([
    (0, common_1.Controller)('auth'),
    __metadata("design:paramtypes", [auth_service_js_1.AuthService])
], AuthController);
//# sourceMappingURL=auth.controller.js.map