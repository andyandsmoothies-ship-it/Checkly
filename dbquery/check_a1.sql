\pset pager off

-- Check Test1, Test2, Test3, Test4 criteria
SELECT c.label, c.input_type, c.points_weight
FROM criteria c
JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
  AND c.label LIKE 'Test%'
ORDER BY c.label;
