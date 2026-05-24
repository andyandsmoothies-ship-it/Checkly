SELECT id, title, is_active, type FROM templates ORDER BY created_at;
SELECT COUNT(*) AS total_templates FROM templates;
SELECT COUNT(*) AS active_templates FROM templates WHERE is_active = true;
SELECT COUNT(*) AS inactive_or_null FROM templates WHERE is_active IS NULL OR is_active = false;
SELECT id, title, is_active FROM templates WHERE is_active IS NULL OR is_active = false;
