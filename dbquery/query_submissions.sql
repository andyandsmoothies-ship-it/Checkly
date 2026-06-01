SELECT s.id, s.store_id, s.store_name, s.template_id, s.template_title, s.template_type, s.total_score, s.completed_at
FROM submissions s
WHERE s.status = 'completed'
  AND (s.review_status IS NULL OR s.review_status != 'rejected')
  AND s.completed_at >= '2026-05-02'
  AND s.completed_at <= '2026-06-01 23:59:59.999';
