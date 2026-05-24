SELECT 
    t.title AS template,
    g.title AS section,
    c.label AS criterion,
    c.input_type,
    CASE WHEN c.metadata IS NULL THEN 'NULL' ELSE LEFT(c.metadata::text, 60) END AS metadata_preview
FROM criteria c
JOIN groups g ON c.group_id = g.id
JOIN templates t ON g.template_id = t.id
WHERE c.is_active = true 
  AND g.is_active = true 
  AND t.is_active = true
  AND c.input_type IN ('scale', 'single_choice', 'multi_choice')
ORDER BY t.title, g.order_index, c.order_index;
