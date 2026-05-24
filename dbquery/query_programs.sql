SELECT p.title, p.status, p.deadline
FROM programs p
WHERE p.id IN (
    SELECT DISTINCT a.program_id 
    FROM program_assignments a
    WHERE a.store_id IN (
        SELECT store_id FROM profile_store_assignments WHERE profile_id = (
            SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am2@checkly.local'
        )
    )
);
