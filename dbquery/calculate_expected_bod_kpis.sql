-- totalAudits
SELECT 'totalAudits' AS metric, COUNT(*)::text AS val FROM submissions
WHERE status = 'completed'
  AND (review_status IS NULL OR review_status != 'rejected')
  AND completed_at IS NOT NULL
  AND completed_at <= '2026-06-01 23:59:59.999'

UNION ALL

-- avgScore (last 30 days completed submissions)
SELECT 'avgScore' AS metric, ROUND(AVG(total_score), 1)::text AS val FROM submissions
WHERE status = 'completed'
  AND (review_status IS NULL OR review_status != 'rejected')
  AND completed_at IS NOT NULL
  AND completed_at >= '2026-05-02 00:00:00'
  AND completed_at <= '2026-06-01 23:59:59.999'
  AND (scoring_mode IS NULL OR scoring_mode != 'survey')
  AND total_score IS NOT NULL

UNION ALL

-- activeStores
SELECT 'activeStores' AS metric, COUNT(*)::text FROM stores WHERE is_active = true

UNION ALL

-- totalAuditors
SELECT 'totalAuditors' AS metric, COUNT(DISTINCT auditor_id)::text FROM submissions
WHERE status = 'completed'
  AND (review_status IS NULL OR review_status != 'rejected')
  AND completed_at IS NOT NULL
  AND completed_at >= '2026-05-02 00:00:00'
  AND completed_at <= '2026-06-01 23:59:59.999'
  AND auditor_id IS NOT NULL

UNION ALL

-- completionRate
SELECT 'completionRate' AS metric, 
  ROUND((
    (SELECT COUNT(*) FROM submissions
     WHERE status = 'completed'
       AND (review_status IS NULL OR review_status != 'rejected')
       AND completed_at IS NOT NULL
       AND completed_at >= '2026-05-02 00:00:00'
       AND completed_at <= '2026-06-01 23:59:59.999')::decimal
    /
    (SELECT COUNT(*) FROM submissions
     WHERE (review_status IS NULL OR review_status != 'rejected')
       AND created_at >= '2026-05-02 00:00:00'
       AND created_at <= '2026-06-01 23:59:59.999')::decimal
  ) * 100, 1)::text

UNION ALL

-- openActionPlans
SELECT 'openActionPlans' AS metric, COUNT(*)::text FROM action_plans WHERE status = 'open'

UNION ALL

-- overdueActionPlans
SELECT 'overdueActionPlans' AS metric, COUNT(*)::text FROM action_plans WHERE status = 'open' AND deadline <= '2026-06-01 23:59:59.999'

UNION ALL

-- geofenceBypassCount
SELECT 'geofenceBypassCount' AS metric, COALESCE(SUM(CASE WHEN is_geofence_bypassed = true THEN 1 ELSE 0 END), 0)::text FROM submissions
WHERE status = 'completed'
  AND (review_status IS NULL OR review_status != 'rejected')
  AND completed_at IS NOT NULL
  AND completed_at >= '2026-05-02 00:00:00'
  AND completed_at <= '2026-06-01 23:59:59.999';
