SELECT 
    p.title, 
    COUNT(a.store_id) as assigned_stores, 
    SUM(CASE WHEN a.status IN ('submitted', 'verified', 'needs_revision') THEN 1 ELSE 0 END) as completed_stores
FROM program_assignments a
JOIN programs p ON a.program_id = p.id
WHERE a.store_id IN (
    SELECT store_id FROM profile_store_assignments WHERE profile_id = (
        SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am1@checkly.local'
    )
)
GROUP BY p.title
ORDER BY MAX(p.deadline) DESC;

SELECT count(store_id) as am1_total_stores FROM profile_store_assignments WHERE profile_id = (
    SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am1@checkly.local'
);
