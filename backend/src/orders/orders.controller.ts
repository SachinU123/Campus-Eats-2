import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
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

  // GET /canteen/orders?status=paid  — fetch paid/completed orders
  @Get()
  async getCanteenOrders(@Query('status') status?: string) {
    const orders = await this.orderService.getCanteenOrders(status);
    return ApiResponse.ok(orders, 'Canteen orders retrieved');
  }

  // GET /canteen/orders/:id
  @Get(':id')
  async getOrderById(@Param('id') id: string) {
    const order = await this.orderService.getOrderById(id);
    return ApiResponse.ok(order, 'Order retrieved');
  }

  // GET /canteen/orders/:id/slip
  @Get(':id/slip')
  async getSlip(@Param('id') id: string) {
    const slip = await this.orderService.getSlip(id);
    return ApiResponse.ok(slip, 'Slip retrieved');
  }

  // PATCH /canteen/orders/:id/complete — transition status (paid → completed | cancelled)
  @Patch(':id/complete')
  async completeOrder(
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    const order = await this.orderService.updateOrderStatus(id, dto);
    return ApiResponse.ok(order, `Order status updated to ${dto.status}`);
  }

  // PATCH /canteen/orders/:id/print — mark slip as printed (idempotent)
  @Patch(':id/print')
  async printOrder(@Param('id') id: string) {
    const order = await this.orderService.printOrder(id);
    return ApiResponse.ok(order, 'Order marked as printed');
  }
}

// ─── Canteen Reports + History Controller ──────────────────

@Controller('canteen')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('canteen')
export class CanteenReportsController {
  constructor(private readonly orderService: OrderService) {}

  // GET /canteen/reports — real aggregated report data
  @Get('reports')
  async getReports() {
    const data = await this.orderService.getCanteenReports();
    return ApiResponse.ok(data, 'Reports retrieved');
  }

  // DELETE /canteen/history/completed — clear completed orders only
  @Delete('history/completed')
  async clearCompletedHistory(@CurrentUser('sub') canteenUserId: string) {
    const result = await this.orderService.clearCompletedHistory(canteenUserId);
    return ApiResponse.ok(result, `Cleared ${result.cleared} completed orders`);
  }
}
