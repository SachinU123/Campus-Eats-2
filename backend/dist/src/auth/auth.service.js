"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const config_1 = require("@nestjs/config");
const bcrypt = __importStar(require("bcrypt"));
const prisma_service_js_1 = require("../prisma/prisma.service.js");
let AuthService = class AuthService {
    prisma;
    jwt;
    config;
    constructor(prisma, jwt, config) {
        this.prisma = prisma;
        this.jwt = jwt;
        this.config = config;
    }
    async registerStudent(dto) {
        const existing = await this.prisma.student.findUnique({
            where: { email: dto.email },
        });
        if (existing) {
            throw new common_1.ConflictException('Email already registered');
        }
        const passwordHash = await bcrypt.hash(dto.password, 12);
        const student = await this.prisma.student.create({
            data: {
                email: dto.email,
                name: dto.name,
                phoneNumber: dto.phoneNumber,
                passwordHash,
            },
        });
        const tokens = await this.generateTokens({
            sub: student.id,
            role: 'student',
            email: student.email,
            name: student.name,
        });
        await this.createSession(student.id, 'student', tokens.refreshToken);
        return {
            user: this.sanitizeStudent(student),
            ...tokens,
        };
    }
    async loginStudent(dto) {
        const student = await this.prisma.student.findUnique({
            where: { email: dto.email },
        });
        if (!student || !student.isActive) {
            throw new common_1.UnauthorizedException('Invalid email or password');
        }
        const valid = await bcrypt.compare(dto.password, student.passwordHash);
        if (!valid) {
            throw new common_1.UnauthorizedException('Invalid email or password');
        }
        const tokens = await this.generateTokens({
            sub: student.id,
            role: 'student',
            email: student.email,
            name: student.name,
        });
        await this.createSession(student.id, 'student', tokens.refreshToken);
        return {
            user: this.sanitizeStudent(student),
            ...tokens,
        };
    }
    async requestCanteenOtp(dto) {
        const canteenUser = await this.prisma.canteenUser.findUnique({
            where: { phoneNumber: dto.phoneNumber },
        });
        if (!canteenUser || !canteenUser.isActive) {
            throw new common_1.BadRequestException('Phone number not registered');
        }
        const recentOtps = await this.prisma.otpCode.count({
            where: {
                phoneNumber: dto.phoneNumber,
                purpose: 'canteen_login',
                consumedAt: null,
                createdAt: { gte: new Date(Date.now() - 5 * 60 * 1000) },
            },
        });
        if (recentOtps >= 5) {
            throw new common_1.BadRequestException('Too many OTP requests. Try again in 5 minutes.');
        }
        const code = Math.floor(1000 + Math.random() * 9000).toString();
        const expiryMinutes = this.config.get('OTP_EXPIRY_MINUTES') || 5;
        await this.prisma.otpCode.create({
            data: {
                phoneNumber: dto.phoneNumber,
                code,
                purpose: 'canteen_login',
                expiresAt: new Date(Date.now() + expiryMinutes * 60 * 1000),
            },
        });
        const isDevMode = this.config.get('OTP_DEV_MODE') === 'true';
        if (isDevMode) {
            console.log(`\n🔑 [DEV] OTP for ${dto.phoneNumber}: ${code}\n`);
        }
        return {
            message: 'OTP sent successfully',
            phoneNumber: dto.phoneNumber,
            ...(isDevMode ? { devOtp: code } : {}),
        };
    }
    async verifyCanteenOtp(dto) {
        const canteenUser = await this.prisma.canteenUser.findUnique({
            where: { phoneNumber: dto.phoneNumber },
        });
        if (!canteenUser || !canteenUser.isActive) {
            throw new common_1.UnauthorizedException('Phone number not linked to canteen');
        }
        const maxAttempts = this.config.get('OTP_MAX_ATTEMPTS') || 5;
        const otpRecord = await this.prisma.otpCode.findFirst({
            where: {
                phoneNumber: dto.phoneNumber,
                purpose: 'canteen_login',
                consumedAt: null,
                expiresAt: { gte: new Date() },
            },
            orderBy: { createdAt: 'desc' },
        });
        if (!otpRecord) {
            throw new common_1.BadRequestException('No valid OTP found. Please request a new one.');
        }
        if (otpRecord.attempts >= maxAttempts) {
            throw new common_1.BadRequestException('Too many attempts. Request a new OTP.');
        }
        await this.prisma.otpCode.update({
            where: { id: otpRecord.id },
            data: { attempts: { increment: 1 } },
        });
        if (otpRecord.code !== dto.otp) {
            throw new common_1.UnauthorizedException('Invalid OTP');
        }
        await this.prisma.otpCode.update({
            where: { id: otpRecord.id },
            data: { consumedAt: new Date() },
        });
        const tokens = await this.generateTokens({
            sub: canteenUser.id,
            role: 'canteen',
            name: canteenUser.name,
            phoneNumber: canteenUser.phoneNumber,
        });
        await this.createSession(canteenUser.id, 'canteen', tokens.refreshToken, dto.deviceId, dto.deviceName);
        return {
            user: {
                id: canteenUser.id,
                name: canteenUser.name,
                phoneNumber: canteenUser.phoneNumber,
                role: canteenUser.role,
            },
            ...tokens,
        };
    }
    async refreshToken(dto) {
        let payload;
        try {
            payload = await this.jwt.verifyAsync(dto.refreshToken, {
                secret: this.config.get('JWT_REFRESH_SECRET'),
            });
        }
        catch {
            throw new common_1.UnauthorizedException('Invalid or expired refresh token');
        }
        const tokenHash = await this.hashToken(dto.refreshToken);
        const session = await this.prisma.refreshSession.findFirst({
            where: {
                userId: payload.sub,
                refreshTokenHash: tokenHash,
                revokedAt: null,
                expiresAt: { gte: new Date() },
            },
        });
        if (!session) {
            throw new common_1.UnauthorizedException('Session not found or revoked');
        }
        const newTokens = await this.generateTokens({
            sub: payload.sub,
            role: payload.role,
            ...(payload.email ? { email: payload.email } : {}),
            ...(payload.name ? { name: payload.name } : {}),
            ...(payload.phoneNumber ? { phoneNumber: payload.phoneNumber } : {}),
        });
        const newTokenHash = await this.hashToken(newTokens.refreshToken);
        await this.prisma.refreshSession.update({
            where: { id: session.id },
            data: {
                refreshTokenHash: newTokenHash,
                lastUsedAt: new Date(),
                expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            },
        });
        return newTokens;
    }
    async logout(refreshToken) {
        try {
            const tokenHash = await this.hashToken(refreshToken);
            await this.prisma.refreshSession.updateMany({
                where: { refreshTokenHash: tokenHash, revokedAt: null },
                data: { revokedAt: new Date() },
            });
        }
        catch {
        }
        return { message: 'Logged out successfully' };
    }
    async getProfile(userId, role) {
        if (role === 'student') {
            const student = await this.prisma.student.findUnique({
                where: { id: userId },
            });
            if (!student)
                throw new common_1.UnauthorizedException('Student not found');
            return this.sanitizeStudent(student);
        }
        if (role === 'canteen') {
            const canteen = await this.prisma.canteenUser.findUnique({
                where: { id: userId },
            });
            if (!canteen)
                throw new common_1.UnauthorizedException('Canteen user not found');
            return {
                id: canteen.id,
                name: canteen.name,
                phoneNumber: canteen.phoneNumber,
                role: canteen.role,
            };
        }
        throw new common_1.UnauthorizedException('Invalid role');
    }
    async generateTokens(payload) {
        const accessExpiresIn = parseInt(this.config.get('JWT_ACCESS_EXPIRES_IN') || '900', 10) || 900;
        const refreshExpiresIn = parseInt(this.config.get('JWT_REFRESH_EXPIRES_IN') || '2592000', 10) || 2592000;
        const [accessToken, refreshToken] = await Promise.all([
            this.jwt.signAsync(payload, {
                secret: this.config.get('JWT_ACCESS_SECRET'),
                expiresIn: accessExpiresIn,
            }),
            this.jwt.signAsync(payload, {
                secret: this.config.get('JWT_REFRESH_SECRET'),
                expiresIn: refreshExpiresIn,
            }),
        ]);
        return { accessToken, refreshToken };
    }
    async createSession(userId, userType, refreshToken, deviceId, deviceName) {
        const tokenHash = await this.hashToken(refreshToken);
        const sessionData = {
            userId,
            userType,
            refreshTokenHash: tokenHash,
            deviceId,
            deviceName,
            expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        };
        if (userType === 'student') {
            sessionData.studentId = userId;
        }
        else if (userType === 'canteen') {
            sessionData.canteenUserId = userId;
        }
        await this.prisma.refreshSession.create({ data: sessionData });
    }
    async hashToken(token) {
        return bcrypt.hash(token.slice(-32), 4);
    }
    sanitizeStudent(student) {
        return {
            id: student.id,
            email: student.email,
            name: student.name,
            phoneNumber: student.phoneNumber,
            role: 'student',
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_js_1.PrismaService,
        jwt_1.JwtService,
        config_1.ConfigService])
], AuthService);
//# sourceMappingURL=auth.service.js.map