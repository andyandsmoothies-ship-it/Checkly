SELECT p.title, a.store_id, count(*) as count
FROM program_assignments a
JOIN programs p ON a.program_id = p.id
WHERE a.store_id IN (
    SELECT store_id FROM profile_store_assignments WHERE profile_id = (
        SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am2@checkly.local'
    )
)
GROUP BY p.title, a.store_id
HAVING count(*) > 1;
