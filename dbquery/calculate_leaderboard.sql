SELECT store_name, ROUND(AVG(total_score), 1) as avg_score, COUNT(*) as audit_count
FROM submissions s
WHERE s.status = 'completed'
  AND (s.review_status IS NULL OR s.review_status != 'rejected')
  AND s.completed_at >= '2026-05-02'
  AND s.completed_at <= '2026-06-01 23:59:59.999'
  AND s.scoring_mode != 'survey'
  AND s.total_score IS NOT NULL
  AND s.store_id IS NOT NULL
  AND (s.template_type = 'qc' OR s.template_type = 'QC')
GROUP BY store_name
ORDER BY avg_score DESC, audit_count DESC;
