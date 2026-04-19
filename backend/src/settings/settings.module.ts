import { Module } from '@nestjs/common';
import { SettingsService } from './settings.service.js';
import { SettingsController } from './settings.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [AuthModule], // needed for JwtAuthGuard
  controllers: [SettingsController],
  providers: [SettingsService],
  exports: [SettingsService], // OrdersModule imports this to check canteen status
})
export class SettingsModule {}
