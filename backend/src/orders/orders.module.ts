import { Module } from '@nestjs/common';
import { OrderService } from './orders.service.js';
import {
  OrderController,
  CanteenOrderController,
  CanteenReportsController,
} from './orders.controller.js';
import { AuthModule } from '../auth/auth.module.js';
import { SettingsModule } from '../settings/settings.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [AuthModule, SettingsModule, NotificationsModule],
  controllers: [OrderController, CanteenOrderController, CanteenReportsController],
  providers: [OrderService],
  exports: [OrderService],
})
export class OrdersModule {}

