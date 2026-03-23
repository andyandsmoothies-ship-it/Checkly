\o c:/Users/HP/Documents/GitHub/Checkly/server/tmp/check_result.txt
SELECT t.id, t.title, t.scoring_logic_config, g.title as group, c.label, c.minus_impact 
FROM templates t 
JOIN groups g ON t.id = g.template_id 
JOIN criteria c ON g.id = c.group_id 
ORDER BY t.created_at ASC 
LIMIT 10;
