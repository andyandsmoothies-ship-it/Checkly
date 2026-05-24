-- =========================================
-- Store Visit Template Data Fix
-- Template: 615a7dc3-40d8-460f-831e-0f3a152838a8
-- =========================================

\pset pager off

-- 1. Set scoring mode to 'accumulation' via scoring_logic_config
UPDATE templates
SET scoring_logic_config = '{"scoringMode":"accumulation","features":{"ccp_enabled":true,"risk_enabled":true,"confirm_required":false,"progressive_repeat":false}}'
WHERE id = '615a7dc3-40d8-460f-831e-0f3a152838a8';

-- 2. Change scored criteria from 'single_choice' to 'pass_fail'
--    Only where points > 0 (actual compliance checks)
--    OR is_risk = true (RISK criteria with 0 pts)
UPDATE criteria
SET input_type = 'pass_fail', updated_at = now()
WHERE group_id IN (
  SELECT id FROM groups 
  WHERE template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
    AND is_active = true
)
AND is_active = true
AND input_type = 'single_choice'
AND (points_weight > 0 OR is_risk = true);

-- 3. Leave text criteria (sections 9, 11) untouched
-- 4. Leave the survey single_choice (section 10, pts=0, not risk) untouched

-- Verify results
SELECT input_type, COUNT(*) as count, SUM(points_weight) as total_pts
FROM criteria c
JOIN groups g ON c.group_id = g.id
WHERE g.template_id = '615a7dc3-40d8-460f-831e-0f3a152838a8'
  AND c.is_active = true
GROUP BY input_type;

SELECT 'Template config:' as label, scoring_logic_config as config
FROM templates WHERE id = '615a7dc3-40d8-460f-831e-0f3a152838a8';
