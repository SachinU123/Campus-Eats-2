-- Phase 2: Add prepTimeMinutes to menu_items, scheduledFor + estimatedReadyAt to orders
-- Migration: 20260406_phase2_eta_schedule
-- Safe: all columns have defaults, no breaking changes

-- Add prep time to menu items (default 5 minutes per item)
ALTER TABLE "menu_items" ADD COLUMN IF NOT EXISTS "prepTimeMinutes" INTEGER NOT NULL DEFAULT 5;

-- Add schedule and ETA fields to orders (both nullable)
ALTER TABLE "orders" ADD COLUMN IF NOT EXISTS "scheduledFor" TIMESTAMP(3);
ALTER TABLE "orders" ADD COLUMN IF NOT EXISTS "estimatedReadyAt" TIMESTAMP(3);

-- Index for scheduled order queries
CREATE INDEX IF NOT EXISTS "orders_scheduledFor_idx" ON "orders"("scheduledFor");
