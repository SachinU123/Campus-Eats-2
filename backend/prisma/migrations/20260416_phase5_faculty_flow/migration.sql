-- Phase 5: Faculty Flow
-- Adds faculty table, extends orders with facultyId + customerRole,
-- extends refresh_sessions with optional facultyId FK.

-- 1. Create faculty table
CREATE TABLE "faculty" (
    "id"           TEXT NOT NULL DEFAULT gen_random_uuid(),
    "email"        TEXT NOT NULL,
    "name"         TEXT NOT NULL,
    "phoneNumber"  TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "department"   TEXT NOT NULL DEFAULT '',
    "roomNumber"   TEXT NOT NULL DEFAULT '',
    "isActive"     BOOLEAN NOT NULL DEFAULT true,
    "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "faculty_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "faculty_email_key" ON "faculty"("email");
CREATE UNIQUE INDEX "faculty_phoneNumber_key" ON "faculty"("phoneNumber");

-- 2. Extend orders: make studentId nullable, add facultyId + customerRole
ALTER TABLE "orders"
    ALTER COLUMN "studentId" DROP NOT NULL,
    ADD COLUMN IF NOT EXISTS "facultyId"    TEXT,
    ADD COLUMN IF NOT EXISTS "customerRole" TEXT NOT NULL DEFAULT 'student';

-- 3. Add FK from orders -> faculty
ALTER TABLE "orders"
    ADD CONSTRAINT "orders_facultyId_fkey"
    FOREIGN KEY ("facultyId") REFERENCES "faculty"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 4. Index for facultyId on orders
CREATE INDEX IF NOT EXISTS "orders_facultyId_idx" ON "orders"("facultyId");

-- 5. Extend refresh_sessions: add optional facultyId FK
ALTER TABLE "refresh_sessions"
    ADD COLUMN IF NOT EXISTS "facultyId" TEXT;

ALTER TABLE "refresh_sessions"
    ADD CONSTRAINT "refresh_sessions_facultyId_fkey"
    FOREIGN KEY ("facultyId") REFERENCES "faculty"("id")
    ON DELETE CASCADE ON UPDATE CASCADE;
