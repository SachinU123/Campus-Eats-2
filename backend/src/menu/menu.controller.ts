import { Controller, Get, Param, Query } from '@nestjs/common';
import { MenuService } from './menu.service.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';

@Controller('menu')
export class MenuController {
  constructor(private readonly menuService: MenuService) {}

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
}
