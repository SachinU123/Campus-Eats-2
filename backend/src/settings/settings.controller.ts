import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { SettingsService } from './settings.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { Roles } from '../common/decorators/roles.decorator.js';

// ── DTOs ─────────────────────────────────────────────────────────────────

class SetCanteenStatusDto {
  status!: 'open' | 'paused' | 'closed';
  message?: string;
}

class SetStaffActiveDto {
  isActive!: boolean;
}

// ── Inline admin guard helper ─────────────────────────────────────────────

function requireAdmin(req: any) {
  // canteen_admin has canteenRole = 'canteen_admin' in the JWT payload
  if (req.user?.canteenRole !== 'canteen_admin') {
    throw new ForbiddenException('Admin access required');
  }
}

// ── Controller ───────────────────────────────────────────────────────────

@Controller('settings')
export class SettingsController {
  constructor(private readonly settings: SettingsService) {}

  /**
   * GET /settings/status — PUBLIC (no auth needed).
   * Customer/canteen client uses this to show operational state.
   */
  @Get('status')
  async getStatus() {
    const status = await this.settings.getCanteenStatus();
    return ApiResponse.ok(status, 'Status retrieved');
  }

  /**
   * PATCH /settings/status — Admin only.
   * Body: { status: 'open' | 'paused' | 'closed', message?: string }
   */
  @Patch('status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async setStatus(@Body() dto: SetCanteenStatusDto, @Request() req: any) {
    requireAdmin(req);
    const result = await this.settings.setCanteenStatus(
      dto.status,
      dto.message ?? '',
    );
    return ApiResponse.ok(result, `Canteen status set to ${dto.status}`);
  }

  /**
   * GET /settings/staff — Admin only.
   * Returns all canteen staff accounts.
   */
  @Get('staff')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async listStaff(@Request() req: any) {
    requireAdmin(req);
    const staff = await this.settings.listStaff();
    return ApiResponse.ok(staff, 'Staff list retrieved');
  }

  /**
   * PATCH /settings/staff/:id/active — Admin only.
   * Body: { isActive: boolean }
   * Enables or disables a canteen staff account.
   */
  @Patch('staff/:id/active')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async setStaffActive(
    @Param('id') id: string,
    @Body() dto: SetStaffActiveDto,
    @Request() req: any,
  ) {
    requireAdmin(req);
    const updated = await this.settings.setStaffActive(id, dto.isActive);
    return ApiResponse.ok(
      updated,
      dto.isActive ? 'Staff account enabled' : 'Staff account disabled',
    );
  }
}
