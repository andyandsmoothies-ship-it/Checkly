SELECT id, status, template_title, total_score, created_at, scheduled_at, started_at
FROM submissions
ORDER BY created_at DESC
LIMIT 10;
