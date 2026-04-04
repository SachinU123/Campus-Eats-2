import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  StudentRegisterDto,
  StudentLoginDto,
  CanteenRequestOtpDto,
  CanteenVerifyOtpDto,
  RefreshTokenDto,
} from './dto/auth.dto.js';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ─── Student Registration ───────────────────────────────────

  async registerStudent(dto: StudentRegisterDto) {
    const existing = await this.prisma.student.findUnique({
      where: { email: dto.email },
    });
    if (existing) {
      throw new ConflictException('Email already registered');
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

  // ─── Student Login ──────────────────────────────────────────

  async loginStudent(dto: StudentLoginDto) {
    const student = await this.prisma.student.findUnique({
      where: { email: dto.email },
    });
    if (!student || !student.isActive) {
      throw new UnauthorizedException('Invalid email or password');
    }

    const valid = await bcrypt.compare(dto.password, student.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
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

  // ─── Canteen OTP Request ────────────────────────────────────

  async requestCanteenOtp(dto: CanteenRequestOtpDto) {
    const canteenUser = await this.prisma.canteenUser.findUnique({
      where: { phoneNumber: dto.phoneNumber },
    });
    if (!canteenUser || !canteenUser.isActive) {
      throw new BadRequestException('Phone number not registered');
    }

    // Rate limiting: check recent unused OTPs
    const recentOtps = await this.prisma.otpCode.count({
      where: {
        phoneNumber: dto.phoneNumber,
        purpose: 'canteen_login',
        consumedAt: null,
        createdAt: { gte: new Date(Date.now() - 5 * 60 * 1000) },
      },
    });
    if (recentOtps >= 5) {
      throw new BadRequestException(
        'Too many OTP requests. Try again in 5 minutes.',
      );
    }

    // Generate 4-digit OTP
    const code = Math.floor(1000 + Math.random() * 9000).toString();
    const expiryMinutes = this.config.get<number>('OTP_EXPIRY_MINUTES') || 5;

    await this.prisma.otpCode.create({
      data: {
        phoneNumber: dto.phoneNumber,
        code,
        purpose: 'canteen_login',
        expiresAt: new Date(Date.now() + expiryMinutes * 60 * 1000),
      },
    });

    // In dev mode, log the OTP
    const isDevMode = this.config.get<string>('OTP_DEV_MODE') === 'true';
    if (isDevMode) {
      console.log(`\n🔑 [DEV] OTP for ${dto.phoneNumber}: ${code}\n`);
    }

    // In production, integrate with SMS gateway here

    return {
      message: 'OTP sent successfully',
      phoneNumber: dto.phoneNumber,
      ...(isDevMode ? { devOtp: code } : {}),
    };
  }

  // ─── Canteen OTP Verify ─────────────────────────────────────

  async verifyCanteenOtp(dto: CanteenVerifyOtpDto) {
    const canteenUser = await this.prisma.canteenUser.findUnique({
      where: { phoneNumber: dto.phoneNumber },
    });
    if (!canteenUser || !canteenUser.isActive) {
      throw new UnauthorizedException('Phone number not linked to canteen');
    }

    const maxAttempts = this.config.get<number>('OTP_MAX_ATTEMPTS') || 5;

    // Find the latest unused OTP for this phone
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
      throw new BadRequestException('No valid OTP found. Please request a new one.');
    }

    if (otpRecord.attempts >= maxAttempts) {
      throw new BadRequestException('Too many attempts. Request a new OTP.');
    }

    // Increment attempt count
    await this.prisma.otpCode.update({
      where: { id: otpRecord.id },
      data: { attempts: { increment: 1 } },
    });

    if (otpRecord.code !== dto.otp) {
      throw new UnauthorizedException('Invalid OTP');
    }

    // Mark OTP as consumed
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

    await this.createSession(
      canteenUser.id,
      'canteen',
      tokens.refreshToken,
      dto.deviceId,
      dto.deviceName,
    );

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

  // ─── Refresh Token ──────────────────────────────────────────

  async refreshToken(dto: RefreshTokenDto) {
    let payload: any;
    try {
      payload = await this.jwt.verifyAsync(dto.refreshToken, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
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
      throw new UnauthorizedException('Session not found or revoked');
    }

    // Rotate refresh token
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
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
      },
    });

    return newTokens;
  }

  // ─── Logout ─────────────────────────────────────────────────

  async logout(refreshToken: string) {
    try {
      const tokenHash = await this.hashToken(refreshToken);
      await this.prisma.refreshSession.updateMany({
        where: { refreshTokenHash: tokenHash, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    } catch {
      // Silent — don't reveal session info on logout errors
    }
    return { message: 'Logged out successfully' };
  }

  // ─── Get Profile ────────────────────────────────────────────

  async getProfile(userId: string, role: string) {
    if (role === 'student') {
      const student = await this.prisma.student.findUnique({
        where: { id: userId },
      });
      if (!student) throw new UnauthorizedException('Student not found');
      return this.sanitizeStudent(student);
    }

    if (role === 'canteen') {
      const canteen = await this.prisma.canteenUser.findUnique({
        where: { id: userId },
      });
      if (!canteen) throw new UnauthorizedException('Canteen user not found');
      return {
        id: canteen.id,
        name: canteen.name,
        phoneNumber: canteen.phoneNumber,
        role: canteen.role,
      };
    }

    throw new UnauthorizedException('Invalid role');
  }

  // ─── Private Helpers ────────────────────────────────────────

  private async generateTokens(payload: Record<string, any>) {
    const accessExpiresIn = parseInt(this.config.get<string>('JWT_ACCESS_EXPIRES_IN') || '900', 10) || 900;
    const refreshExpiresIn = parseInt(this.config.get<string>('JWT_REFRESH_EXPIRES_IN') || '2592000', 10) || 2592000;

    const [accessToken, refreshToken] = await Promise.all([
      this.jwt.signAsync(payload, {
        secret: this.config.get<string>('JWT_ACCESS_SECRET'),
        expiresIn: accessExpiresIn,
      } as any),
      this.jwt.signAsync(payload, {
        secret: this.config.get<string>('JWT_REFRESH_SECRET'),
        expiresIn: refreshExpiresIn,
      } as any),
    ]);

    return { accessToken, refreshToken };
  }

  private async createSession(
    userId: string,
    userType: string,
    refreshToken: string,
    deviceId?: string,
    deviceName?: string,
  ) {
    const tokenHash = await this.hashToken(refreshToken);

    const sessionData: any = {
      userId,
      userType,
      refreshTokenHash: tokenHash,
      deviceId,
      deviceName,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
    };

    if (userType === 'student') {
      sessionData.studentId = userId;
    } else if (userType === 'canteen') {
      sessionData.canteenUserId = userId;
    }

    await this.prisma.refreshSession.create({ data: sessionData });
  }

  private async hashToken(token: string): Promise<string> {
    return bcrypt.hash(token.slice(-32), 4); // Lightweight hash of token tail
  }

  private sanitizeStudent(student: any) {
    return {
      id: student.id,
      email: student.email,
      name: student.name,
      phoneNumber: student.phoneNumber,
      role: 'student',
    };
  }
}
