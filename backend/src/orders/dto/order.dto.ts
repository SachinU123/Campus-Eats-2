import {
  IsArray,
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOrderItemDto {
  @IsNotEmpty()
  @IsString()
  menuItemId: string;

  @IsNumber()
  @Min(1)
  quantity: number;
}

export class CreateOrderDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDto)
  items: CreateOrderItemDto[];

  @IsOptional()
  @IsString()
  notes?: string;

  /**
   * Optional scheduled pickup time (ISO 8601 string).
   * Enforced rules (backend):
   *   - Must be at least 30 minutes from now
   *   - Must be at most 2 hours from now
   * Leave null/undefined for an immediate order.
   */
  @IsOptional()
  @IsDateString()
  scheduledFor?: string;
}

export class UpdateOrderStatusDto {
  @IsNotEmpty()
  @IsString()
  status: string; // completed, cancelled
}
