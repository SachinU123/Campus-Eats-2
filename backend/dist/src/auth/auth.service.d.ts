import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { StudentRegisterDto, StudentLoginDto, CanteenRequestOtpDto, CanteenVerifyOtpDto, RefreshTokenDto } from './dto/auth.dto.js';
export declare class AuthService {
    private readonly prisma;
    private readonly jwt;
    private readonly config;
    constructor(prisma: PrismaService, jwt: JwtService, config: ConfigService);
    registerStudent(dto: StudentRegisterDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            role: string;
        };
    }>;
    loginStudent(dto: StudentLoginDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            role: string;
        };
    }>;
    requestCanteenOtp(dto: CanteenRequestOtpDto): Promise<{
        devOtp?: string | undefined;
        message: string;
        phoneNumber: string;
    }>;
    verifyCanteenOtp(dto: CanteenVerifyOtpDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: string;
            name: string;
            phoneNumber: string;
            role: string;
        };
    }>;
    refreshToken(dto: RefreshTokenDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    logout(refreshToken: string): Promise<{
        message: string;
    }>;
    getProfile(userId: string, role: string): Promise<{
        id: any;
        email: any;
        name: any;
        phoneNumber: any;
        role: string;
    } | {
        id: string;
        name: string;
        phoneNumber: string;
        role: string;
    }>;
    private generateTokens;
    private createSession;
    private hashToken;
    private sanitizeStudent;
}
