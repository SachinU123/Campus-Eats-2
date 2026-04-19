import { Module } from '@nestjs/common';
import { MenuService } from './menu.service.js';
import { MenuController } from './menu.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  // AuthModule provides JwtService + ConfigService needed by JwtAuthGuard
  // on the protected management endpoints (GET /menu/manage, PATCH /menu/items/:id/*)
  imports: [AuthModule],
  controllers: [MenuController],
  providers: [MenuService],
  exports: [MenuService],
})
export class MenuModule {}
