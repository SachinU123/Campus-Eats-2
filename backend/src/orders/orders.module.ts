import { Module } from '@nestjs/common';
import { OrderService } from './orders.service.js';
import { OrderController, CanteenOrderController } from './orders.controller.js';
import { AuthModule } from '../auth/auth.module.js';

@Module({
  imports: [AuthModule],
  controllers: [OrderController, CanteenOrderController],
  providers: [OrderService],
  exports: [OrderService],
})
export class OrdersModule {}
