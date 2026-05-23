SELECT p.title, count(a.store_id) as global_assigned_stores
FROM program_assignments a
JOIN programs p ON a.program_id = p.id
GROUP BY p.title;
