import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service.js';
import { StudentRegisterDto, StudentLoginDto, FacultyRegisterDto, FacultyLoginDto, CanteenRequestOtpDto, CanteenVerifyOtpDto, RefreshTokenDto } from './dto/auth.dto.js';
export declare class AuthService {
    private readonly prisma;
    private readonly jwt;
    private readonly config;
    private readonly logger;
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
    registerFaculty(dto: FacultyRegisterDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            department: any;
            roomNumber: any;
            role: string;
        };
    }>;
    loginFaculty(dto: FacultyLoginDto): Promise<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            department: any;
            roomNumber: any;
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
            canteenRole: string;
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
    private sanitizeFaculty;
}
