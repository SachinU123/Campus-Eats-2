import { IsEmail, IsNotEmpty, IsString, MinLength, IsOptional } from 'class-validator';

export class StudentRegisterDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsNotEmpty()
  @IsString()
  phoneNumber: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;
}

export class StudentLoginDto {
  @IsEmail()
  email: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;
}

export class FacultyRegisterDto {
  @IsNotEmpty()
  @IsString()
  name: string;

  @IsEmail()
  email: string;

  @IsNotEmpty()
  @IsString()
  phoneNumber: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  department?: string;

  @IsOptional()
  @IsString()
  roomNumber?: string;
}

export class FacultyLoginDto {
  @IsEmail()
  email: string;

  @IsNotEmpty()
  @MinLength(6)
  password: string;
}

export class CanteenRequestOtpDto {
  @IsNotEmpty()
  @IsString()
  phoneNumber: string;
}

export class CanteenVerifyOtpDto {
  @IsNotEmpty()
  @IsString()
  phoneNumber: string;

  @IsNotEmpty()
  @IsString()
  otp: string;

  @IsOptional()
  @IsString()
  deviceId?: string;

  @IsOptional()
  @IsString()
  deviceName?: string;
}

export class RefreshTokenDto {
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}

export class LogoutDto {
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}
