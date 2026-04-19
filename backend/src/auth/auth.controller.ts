import {
  Controller,
  Post,
  Body,
  Get,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { AuthService } from './auth.service.js';
import {
  StudentRegisterDto,
  StudentLoginDto,
  FacultyRegisterDto,
  FacultyLoginDto,
  CanteenRequestOtpDto,
  CanteenVerifyOtpDto,
  RefreshTokenDto,
  LogoutDto,
} from './dto/auth.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // ─── Student ─────────────────────────────────────────────────

  @Post('register')
  async studentRegister(@Body() dto: StudentRegisterDto) {
    return this.authService.registerStudent(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async studentLogin(@Body() dto: StudentLoginDto) {
    return this.authService.loginStudent(dto);
  }

  // ─── Faculty ─────────────────────────────────────────────────

  @Post('faculty/register')
  async facultyRegister(@Body() dto: FacultyRegisterDto) {
    return this.authService.registerFaculty(dto);
  }

  @Post('faculty/login')
  @HttpCode(HttpStatus.OK)
  async facultyLogin(@Body() dto: FacultyLoginDto) {
    return this.authService.loginFaculty(dto);
  }

  // ─── Canteen ──────────────────────────────────────────────────

  @Post('canteen/request-otp')
  @HttpCode(HttpStatus.OK)
  async requestCanteenOtp(@Body() dto: CanteenRequestOtpDto) {
    return this.authService.requestCanteenOtp(dto);
  }

  @Post('canteen/verify-otp')
  @HttpCode(HttpStatus.OK)
  async verifyCanteenOtp(@Body() dto: CanteenVerifyOtpDto) {
    return this.authService.verifyCanteenOtp(dto);
  }

  // ─── Session management ───────────────────────────────────────

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshToken(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  async logout(@Body() dto: LogoutDto) {
    return this.authService.logout(dto.refreshToken);
  }

  // ─── Profile ──────────────────────────────────────────────────

  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req: any) {
    return this.authService.getProfile(req.user.sub, req.user.role);
  }
}
