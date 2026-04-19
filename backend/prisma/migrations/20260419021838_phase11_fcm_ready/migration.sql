-- CampusEats Phase 11 Migration: FCM Token + readyAt
-- Safe to run on production: all columns are nullable, no backfill required.

-- Add FCM token storage for push notification delivery
ALTER TABLE "students" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;
ALTER TABLE "faculty"  ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;

-- Add explicit readyAt field (Phase 11 ready signal)
-- Separate from printedAt (slip printed) and completedAt (order collected).
-- Set by the canteen when food is ready for pickup; triggers customer push.
ALTER TABLE "orders" ADD COLUMN IF NOT EXISTS "readyAt" TIMESTAMP(3);
