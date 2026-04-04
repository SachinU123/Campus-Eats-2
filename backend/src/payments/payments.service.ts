import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';
import { PrismaService } from '../prisma/prisma.service.js';
import { OrderService } from '../orders/orders.service.js';
import { CreatePaymentOrderDto, VerifyPaymentDto } from './dto/payment.dto.js';

@Injectable()
export class PaymentService {
  private razorpay: any;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    private readonly orderService: OrderService,
  ) {
    this.initRazorpay();
  }

  private async initRazorpay() {
    // Dynamic import for razorpay (CommonJS module)
    try {
      const Razorpay = (await import('razorpay')).default;
      this.razorpay = new Razorpay({
        key_id: this.config.get<string>('RAZORPAY_KEY_ID')!,
        key_secret: this.config.get<string>('RAZORPAY_KEY_SECRET')!,
      });
    } catch (err) {
      console.error('Failed to initialize Razorpay:', err);
    }
  }

  // ─── Create Razorpay Order ─────────────────────────────────

  async createPaymentOrder(dto: CreatePaymentOrderDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { paymentTransaction: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.paymentStatus === 'paid') {
      throw new BadRequestException('Order already paid');
    }

    // If there's already a Razorpay order, return it
    if (order.paymentTransaction?.razorpayOrderId) {
      return {
        razorpayOrderId: order.paymentTransaction.razorpayOrderId,
        amount: order.total * 100, // paise
        currency: 'INR',
        keyId: this.config.get<string>('RAZORPAY_KEY_ID'),
      };
    }

    // Create Razorpay order
    const amountInPaise = Math.round(order.total * 100);

    if (!this.razorpay) {
      await this.initRazorpay();
    }

    const razorpayOrder = await this.razorpay.orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt: `receipt_${order.id.slice(0, 8)}`,
      notes: {
        orderId: order.id,
        tokenNumber: order.tokenNumber,
      },
    });

    // Create payment transaction record
    await this.prisma.paymentTransaction.create({
      data: {
        orderId: order.id,
        gateway: 'razorpay',
        razorpayOrderId: razorpayOrder.id,
        amount: order.total,
        currency: 'INR',
        status: 'created',
      },
    });

    // Update order status
    await this.prisma.order.update({
      where: { id: order.id },
      data: { status: 'payment_pending' },
    });

    return {
      razorpayOrderId: razorpayOrder.id,
      amount: amountInPaise,
      currency: 'INR',
      keyId: this.config.get<string>('RAZORPAY_KEY_ID'),
    };
  }

  // ─── Verify Payment ───────────────────────────────────────

  async verifyPayment(dto: VerifyPaymentDto) {
    const order = await this.prisma.order.findUnique({
      where: { id: dto.orderId },
      include: { paymentTransaction: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (!order.paymentTransaction) {
      throw new BadRequestException('No payment transaction found');
    }

    // Verify Razorpay signature
    const keySecret = this.config.get<string>('RAZORPAY_KEY_SECRET')!;
    const body = `${dto.razorpayOrderId}|${dto.razorpayPaymentId}`;
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(body)
      .digest('hex');

    const isValid = expectedSignature === dto.razorpaySignature;

    if (!isValid) {
      // Mark payment as failed
      await this.prisma.paymentTransaction.update({
        where: { id: order.paymentTransaction.id },
        data: {
          status: 'failed',
          razorpayPaymentId: dto.razorpayPaymentId,
          razorpaySignature: dto.razorpaySignature,
          rawPayloadJson: {
            verified: false,
            error: 'Signature mismatch',
          },
        },
      });

      await this.prisma.order.update({
        where: { id: order.id },
        data: { paymentStatus: 'failed' },
      });

      throw new BadRequestException('Payment verification failed');
    }

    // Mark payment as captured
    await this.prisma.paymentTransaction.update({
      where: { id: order.paymentTransaction.id },
      data: {
        status: 'captured',
        razorpayPaymentId: dto.razorpayPaymentId,
        razorpaySignature: dto.razorpaySignature,
        paidAt: new Date(),
        rawPayloadJson: {
          verified: true,
          razorpayOrderId: dto.razorpayOrderId,
          razorpayPaymentId: dto.razorpayPaymentId,
        },
      },
    });

    // Finalize order (status → paid, generate receipt)
    const finalizedOrder = await this.orderService.finalizeOrder(order.id);

    return {
      verified: true,
      order: finalizedOrder,
    };
  }

  // ─── Get Payment Info ─────────────────────────────────────

  async getPaymentByOrderId(orderId: string) {
    const payment = await this.prisma.paymentTransaction.findUnique({
      where: { orderId },
    });
    if (!payment) throw new NotFoundException('Payment not found');
    return payment;
  }
}
