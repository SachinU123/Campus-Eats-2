import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { OrderService } from './orders.service.js';
import { CreateOrderDto, UpdateOrderStatusDto } from './dto/order.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { RolesGuard } from '../common/guards/roles.guard.js';
import { Roles } from '../common/decorators/roles.decorator.js';
import { CurrentUser } from '../common/decorators/current-user.decorator.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';

@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  // ─── Student: Create Order ─────────────────────────────────

  @Post()
  @UseGuards(RolesGuard)
  @Roles('student')
  async createOrder(
    @CurrentUser('sub') studentId: string,
    @Body() dto: CreateOrderDto,
  ) {
    const order = await this.orderService.createOrder(studentId, dto);
    return ApiResponse.ok(order, 'Order created');
  }

  // ─── Student: My Orders ────────────────────────────────────

  @Get('my')
  @UseGuards(RolesGuard)
  @Roles('student')
  async getMyOrders(@CurrentUser('sub') studentId: string) {
    const orders = await this.orderService.getStudentOrders(studentId);
    return ApiResponse.ok(orders, 'Orders retrieved');
  }

  // ─── Get Order Detail ──────────────────────────────────────

  @Get(':id')
  async getOrderById(@Param('id') id: string) {
    const order = await this.orderService.getOrderById(id);
    return ApiResponse.ok(order, 'Order retrieved');
  }

  // ─── Get Slip ──────────────────────────────────────────────

  @Get(':id/slip')
  async getSlip(@Param('id') id: string) {
    const slip = await this.orderService.getSlip(id);
    return ApiResponse.ok(slip, 'Slip retrieved');
  }
}

// ─── Canteen Controller ──────────────────────────────────────

@Controller('canteen/orders')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('canteen')
export class CanteenOrderController {
  constructor(private readonly orderService: OrderService) {}

  @Get()
  async getCanteenOrders(@Query('status') status?: string) {
    const orders = await this.orderService.getCanteenOrders(status);
    return ApiResponse.ok(orders, 'Canteen orders retrieved');
  }

  @Get(':id')
  async getOrderById(@Param('id') id: string) {
    const order = await this.orderService.getOrderById(id);
    return ApiResponse.ok(order, 'Order retrieved');
  }

  @Get(':id/slip')
  async getSlip(@Param('id') id: string) {
    const slip = await this.orderService.getSlip(id);
    return ApiResponse.ok(slip, 'Slip retrieved');
  }

  @Patch(':id/complete')
  async completeOrder(
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    const order = await this.orderService.updateOrderStatus(id, dto);
    return ApiResponse.ok(order, `Order status updated to ${dto.status}`);
  }
}
