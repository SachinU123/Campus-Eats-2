import { AuthService } from './auth.service.js';
import { StudentRegisterDto, StudentLoginDto, FacultyRegisterDto, FacultyLoginDto, CanteenRequestOtpDto, CanteenVerifyOtpDto, RefreshTokenDto, LogoutDto } from './dto/auth.dto.js';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    studentRegister(dto: StudentRegisterDto): Promise<{
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
    studentLogin(dto: StudentLoginDto): Promise<{
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
    facultyRegister(dto: FacultyRegisterDto): Promise<{
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
    facultyLogin(dto: FacultyLoginDto): Promise<{
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
    refresh(dto: RefreshTokenDto): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    logout(dto: LogoutDto): Promise<{
        message: string;
    }>;
    getProfile(req: any): Promise<{
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
}
