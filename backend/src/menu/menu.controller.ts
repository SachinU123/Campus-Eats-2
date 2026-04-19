import {
  Controller,
  Get,
  Param,
  Query,
  Patch,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { MenuService } from './menu.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { Roles } from '../common/decorators/roles.decorator.js';


// ── DTOs for Phase 6 management ─────────────────────────────────

class SetUnavailableTodayDto {
  isUnavailableToday!: boolean;
}

class SetSpecialDto {
  isSpecial!: boolean;
  specialLabel?: string;
}

// ── Controller ──────────────────────────────────────────────────

@Controller('menu')
export class MenuController {
  constructor(private readonly menuService: MenuService) {}

  // ── Customer-facing (public, no auth needed) ─────────────────

  @Get('categories')
  async getCategories() {
    const categories = await this.menuService.getCategories();
    return ApiResponse.ok(categories, 'Categories retrieved');
  }

  @Get('items')
  async getItems(
    @Query('category') category?: string,
    @Query('search') search?: string,
  ) {
    if (search) {
      const items = await this.menuService.searchItems(search);
      return ApiResponse.ok(items, 'Search results');
    }
    const items = await this.menuService.getItems(category);
    return ApiResponse.ok(items, 'Items retrieved');
  }

  @Get('items/:id')
  async getItemById(@Param('id') id: string) {
    const item = await this.menuService.getItemById(id);
    if (!item) {
      return ApiResponse.error('Item not found');
    }
    return ApiResponse.ok(item, 'Item retrieved');
  }

  // ── Canteen/Operations management (canteen auth required) ─────

  /** GET /menu/manage — full item list for the management screen. */
  @Get('manage')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async getAllItemsForManagement() {
    const items = await this.menuService.getAllItemsForManagement();
    return ApiResponse.ok(items, 'Management list retrieved');
  }

  /**
   * PATCH /menu/items/:id/availability
   * Body: { isUnavailableToday: boolean }
   * Marks an item unavailable (or available again) for today.
   */
  @Patch('items/:id/availability')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async setUnavailableToday(
    @Param('id') id: string,
    @Body() dto: SetUnavailableTodayDto,
    @Request() req: any,
  ) {
    const item = await this.menuService.setUnavailableToday(
      id,
      dto.isUnavailableToday,
    );
    return ApiResponse.ok(
      item,
      dto.isUnavailableToday
        ? 'Item marked unavailable today'
        : 'Item marked available',
    );
  }

  /**
   * PATCH /menu/items/:id/special
   * Body: { isSpecial: boolean, specialLabel?: string }
   * Marks an item as special/event food, or clears that flag.
   */
  @Patch('items/:id/special')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('canteen')
  async setSpecial(
    @Param('id') id: string,
    @Body() dto: SetSpecialDto,
    @Request() req: any,
  ) {
    const item = await this.menuService.setSpecial(
      id,
      dto.isSpecial,
      dto.specialLabel,
    );
    return ApiResponse.ok(
      item,
      dto.isSpecial ? 'Item marked as special' : 'Special flag cleared',
    );
  }
}
