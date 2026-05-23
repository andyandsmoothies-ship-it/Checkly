SELECT s.name
FROM profile_store_assignments a
JOIN stores s ON a.store_id = s.id
WHERE a.profile_id = (
    SELECT "Id" FROM "AspNetUsers" WHERE "Email" = 'am2@checkly.local'
);
