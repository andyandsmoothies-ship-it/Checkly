-- Backfill: activate all templates that should be visible
UPDATE templates SET is_active = true WHERE is_active = false;
SELECT id, title, is_active FROM templates ORDER BY created_at;
