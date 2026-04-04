import { AuthService } from './auth.service.js';
import { StudentRegisterDto, StudentLoginDto, CanteenRequestOtpDto, CanteenVerifyOtpDto, RefreshTokenDto, LogoutDto } from './dto/auth.dto.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    studentRegister(dto: StudentRegisterDto): Promise<ApiResponse<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            role: string;
        };
    }>>;
    studentLogin(dto: StudentLoginDto): Promise<ApiResponse<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: any;
            email: any;
            name: any;
            phoneNumber: any;
            role: string;
        };
    }>>;
    canteenRequestOtp(dto: CanteenRequestOtpDto): Promise<ApiResponse<{
        devOtp?: string | undefined;
        message: string;
        phoneNumber: string;
    }>>;
    canteenVerifyOtp(dto: CanteenVerifyOtpDto): Promise<ApiResponse<{
        accessToken: string;
        refreshToken: string;
        user: {
            id: string;
            name: string;
            phoneNumber: string;
            role: string;
        };
    }>>;
    refresh(dto: RefreshTokenDto): Promise<ApiResponse<{
        accessToken: string;
        refreshToken: string;
    }>>;
    logout(dto: LogoutDto): Promise<ApiResponse<{
        message: string;
    }>>;
    getProfile(user: any): Promise<ApiResponse<{
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
    }>>;
}
