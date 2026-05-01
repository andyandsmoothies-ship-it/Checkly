-- Migration: AddProgramsRejectionFields
-- Adds rejection_comment and verified_at to program_assignments.
-- Updates the status CHECK constraint to include 'needs_revision' and 'verified'.
-- Run: psql -d checkly -f server/Migrations/AddProgramsRejectionFields.sql

BEGIN;

-- Add the two new nullable columns
ALTER TABLE program_assignments
    ADD COLUMN IF NOT EXISTS rejection_comment text,
    ADD COLUMN IF NOT EXISTS verified_at       timestamptz;

-- Drop old CHECK constraint on status (name from AddProgramsModule.sql) and recreate
-- with the full Slice 4 status machine: pending → submitted → needs_revision → verified.
-- The constraint name may not exist if the original migration omitted it — use IF EXISTS.
ALTER TABLE program_assignments
    DROP CONSTRAINT IF EXISTS program_assignments_status_check;

ALTER TABLE program_assignments
    ADD CONSTRAINT program_assignments_status_check
        CHECK (status IN ('pending', 'submitted', 'needs_revision', 'verified'));

COMMIT;
