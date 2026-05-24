-- Clear stale weight on all groups
-- Root cause: HasDefaultValue(1.0m) in AppDbContext set weight=1 for all groups
UPDATE groups SET weight = NULL;

-- Remove the DB-level default on the column
ALTER TABLE groups ALTER COLUMN weight DROP DEFAULT;
