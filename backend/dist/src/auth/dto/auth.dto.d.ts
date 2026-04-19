export declare class StudentRegisterDto {
    name: string;
    email: string;
    phoneNumber: string;
    password: string;
}
export declare class StudentLoginDto {
    email: string;
    password: string;
}
export declare class FacultyRegisterDto {
    name: string;
    email: string;
    phoneNumber: string;
    password: string;
    department?: string;
    roomNumber?: string;
}
export declare class FacultyLoginDto {
    email: string;
    password: string;
}
export declare class CanteenRequestOtpDto {
    phoneNumber: string;
}
export declare class CanteenVerifyOtpDto {
    phoneNumber: string;
    otp: string;
    deviceId?: string;
    deviceName?: string;
}
export declare class RefreshTokenDto {
    refreshToken: string;
}
export declare class LogoutDto {
    refreshToken: string;
}
