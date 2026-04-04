import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service.js';
import {
  StudentRegisterDto,
  StudentLoginDto,
  CanteenRequestOtpDto,
  CanteenVerifyOtpDto,
  RefreshTokenDto,
  LogoutDto,
} from './dto/auth.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ─── Student ────────────────────────────────────────────────

  @Post('student/register')
  async studentRegister(@Body() dto: StudentRegisterDto) {
    const result = await this.authService.registerStudent(dto);
    return ApiResponse.ok(result, 'Registration successful');
  }

  @Post('student/login')
  @HttpCode(HttpStatus.OK)
  async studentLogin(@Body() dto: StudentLoginDto) {
    const result = await this.authService.loginStudent(dto);
    return ApiResponse.ok(result, 'Login successful');
  }

  // ─── Canteen ────────────────────────────────────────────────

  @Post('canteen/request-otp')
  @HttpCode(HttpStatus.OK)
  async canteenRequestOtp(@Body() dto: CanteenRequestOtpDto) {
    const result = await this.authService.requestCanteenOtp(dto);
    return ApiResponse.ok(result, result.message);
  }

  @Post('canteen/verify-otp')
  @HttpCode(HttpStatus.OK)
  async canteenVerifyOtp(@Body() dto: CanteenVerifyOtpDto) {
    const result = await this.authService.verifyCanteenOtp(dto);
    return ApiResponse.ok(result, 'OTP verified successfully');
  }

  // ─── Common ─────────────────────────────────────────────────

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto) {
    const tokens = await this.authService.refreshToken(dto);
    return ApiResponse.ok(tokens, 'Token refreshed');
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout(@Body() dto: LogoutDto) {
    const result = await this.authService.logout(dto.refreshToken);
    return ApiResponse.ok(result, result.message);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@CurrentUser() user: any) {
    const profile = await this.authService.getProfile(user.sub, user.role);
    return ApiResponse.ok(profile, 'Profile retrieved');
  }
}
