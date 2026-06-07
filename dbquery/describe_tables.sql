SELECT p.full_name, p.email, psa.store_id, s.name AS store_name
FROM profile_store_assignments psa
JOIN profiles p ON psa.profile_id = p.id
JOIN stores s ON psa.store_id = s.id
ORDER BY p.full_name, s.name;
