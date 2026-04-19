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

  // ─── Student/Faculty: Create Order ─────────────────────────

  @Post()
  @UseGuards(RolesGuard)
  @Roles('student', 'faculty')
  async createOrder(
    @CurrentUser('sub') callerId: string,
    @CurrentUser('role') callerRole: string,
    @Body() dto: CreateOrderDto,
  ) {
    const order = await this.orderService.createOrder(
      callerId,
      dto,
      callerRole as 'student' | 'faculty',
    );
    return ApiResponse.ok(order, 'Order created');
  }

  // ─── Student/Faculty: My Orders ────────────────────────────

  @Get('my')
  @UseGuards(RolesGuard)
  @Roles('student', 'faculty')
  async getMyOrders(
    @CurrentUser('sub') callerId: string,
    @CurrentUser('role') callerRole: string,
  ) {
    if (callerRole === 'faculty') {
      const orders = await this.orderService.getFacultyOrders(callerId);
      return ApiResponse.ok(orders, 'Orders retrieved');
    }
    const orders = await this.orderService.getStudentOrders(callerId);
    return ApiResponse.ok(orders, 'Orders retrieved');
  }

  // ─── Student/Faculty: Register FCM Token (Phase 11) ──────────
  // POST /orders/fcm-token
  // Called anytime the FCM token refreshes on the device.
  // Roles: student, faculty

  @Post('fcm-token')
  @UseGuards(RolesGuard)
  @Roles('student', 'faculty')
  async registerFcmToken(
    @CurrentUser('sub') userId: string,
    @CurrentUser('role') userRole: string,
    @Body() body: { token: string },
  ) {
    if (!body?.token || typeof body.token !== 'string') {
      return ApiResponse.ok({}, 'Token skipped — empty');
    }
    await this.orderService.registerFcmToken(
      userId,
      userRole as 'student' | 'faculty',
      body.token,
    );
    return ApiResponse.ok({}, 'FCM token registered');
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

  // GET /canteen/orders/poll — ultra-lightweight queue count for smart polling
  // Returns { count, latestOrderedAt } only — no full order data.
  // Static route declared BEFORE parameterized :id routes (NestJS priority).
  @Get('poll')
  async pollOrders() {
    const data = await this.orderService.getOrderQueueCount();
    return ApiResponse.ok(data, 'Poll OK');
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

  // POST /canteen/orders/verify — verify token/QR and complete order atomically
  @Post('verify')
  async verifyOrder(
    @Body() body: { token: string },
    @CurrentUser('sub') canteenUserId: string,
  ) {
    if (!body?.token || typeof body.token !== 'string' || body.token.trim().length === 0) {
      return ApiResponse.ok({ found: false, reason: 'INVALID_TOKEN', message: 'Token is required' }, 'Invalid token');
    }
    const result = await this.orderService.verifyAndCompleteByToken(body.token.trim(), canteenUserId);
    return ApiResponse.ok(result, result.message);
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

  // PATCH /canteen/orders/:id/ready — mark order as READY, fires push (Phase 11)
  // Idempotent: calling again on an already-ready order is safe.
  // IMPORTANT: ready is separate from printed and completed.
  @Patch(':id/ready')
  async markOrderReady(@Param('id') id: string) {
    const order = await this.orderService.markOrderReady(id);
    return ApiResponse.ok(order, 'Order marked as ready — notification dispatched');
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
