-- Phase 6: Menu Availability & Special Food Support
-- Adds operational flags to menu_items without touching existing columns.

ALTER TABLE "menu_items"
  ADD COLUMN IF NOT EXISTS "isUnavailableToday" BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS "isSpecial"          BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS "specialLabel"        TEXT    NOT NULL DEFAULT '';
