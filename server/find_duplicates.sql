SELECT store_id, COUNT(profile_id) FROM profile_store_assignments GROUP BY store_id HAVING COUNT(profile_id) > 1;
