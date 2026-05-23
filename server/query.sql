SELECT p.title, count(a.store_id) as assigned_stores,
       sum(case when a.status in ('submitted', 'verified', 'needs_revision') then 1 else 0 end) as completed_stores
FROM program_assignments a
JOIN programs p ON a.program_id = p.id
WHERE a.store_id IN (
    SELECT store_id FROM profile_store_assignments WHERE profile_id = (
        SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am2@checkly.local'
    )
)
GROUP BY p.title;

SELECT count(*) as am2_total_stores FROM profile_store_assignments WHERE profile_id = (
        SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am2@checkly.local'
);
