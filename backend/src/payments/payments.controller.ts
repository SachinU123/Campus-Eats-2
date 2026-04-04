import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { PaymentService } from './payments.service.js';
import { CreatePaymentOrderDto, VerifyPaymentDto } from './dto/payment.dto.js';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard.js';
import { ApiResponse } from '../common/dto/api-response.dto.js';

@Controller('payments')
@UseGuards(JwtAuthGuard)
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('create-order')
  async createPaymentOrder(@Body() dto: CreatePaymentOrderDto) {
    const result = await this.paymentService.createPaymentOrder(dto);
    return ApiResponse.ok(result, 'Razorpay order created');
  }

  @Post('verify')
  async verifyPayment(@Body() dto: VerifyPaymentDto) {
    const result = await this.paymentService.verifyPayment(dto);
    return ApiResponse.ok(result, 'Payment verified successfully');
  }

  @Get(':orderId')
  async getPayment(@Param('orderId') orderId: string) {
    const payment = await this.paymentService.getPaymentByOrderId(orderId);
    return ApiResponse.ok(payment, 'Payment retrieved');
  }
}
