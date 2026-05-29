-- Verify the new Action Plans Summary
SELECT 
    status,
    COUNT(*) AS ap_count
FROM action_plans
GROUP BY status;

-- Verify Overdue Action Plans vs All Open Action Plans
SELECT 
    COUNT(*) AS total_open_aps,
    COUNT(CASE WHEN deadline <= NOW() THEN 1 END) AS overdue_aps
FROM action_plans
WHERE status = 'open';
