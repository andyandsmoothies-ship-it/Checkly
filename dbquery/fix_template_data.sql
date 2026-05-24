-- =============================================================
-- FIX: Template Data Quality — Weights & Points
-- 2026-03-20
-- =============================================================

BEGIN;

-- ═══════ 1. NULL weights on 13 templates with bogus weight=1.0 ═══════

UPDATE groups SET weight = NULL
WHERE template_id IN (
  SELECT id FROM templates WHERE title IN (
    'Construction Site Safety',
    'Customer Feedback Form',
    'Daily Opening Checklist',
    'Employee Satisfaction Survey',
    'Employee Training Quiz',
    'Food Handler Certification',
    'ISO Maturity Assessment',
    'Post-Training Feedback',
    'Pre-Flight Aircraft Checklist',
    'Safety Equipment Verification',
    'Shift Handover Checklist',
    'Test2',
    'TnD checklist khu vuc HCM 2026'
  )
) AND is_active = true;

-- ═══════ 2. NULL weights on ALL sub-sections (including correct templates) ═══════
-- Sub-sections never participate in weighted density

UPDATE groups SET weight = NULL
WHERE parent_id IS NOT NULL
  AND weight IS NOT NULL
  AND is_active = true;

-- ═══════ 3. NULL points_weight on survey templates ═══════

UPDATE criteria SET points_weight = NULL
WHERE group_id IN (
  SELECT g.id FROM groups g
  JOIN templates t ON g.template_id = t.id
  WHERE t.title IN (
    'Customer Feedback Form',
    'Employee Satisfaction Survey',
    'Post-Training Feedback'
  ) AND g.is_active = true
) AND is_active = true;

-- ═══════ 4. NULL points_weight on checklist templates ═══════

UPDATE criteria SET points_weight = NULL
WHERE group_id IN (
  SELECT g.id FROM groups g
  JOIN templates t ON g.template_id = t.id
  WHERE t.title IN (
    'Daily Opening Checklist',
    'Pre-Flight Aircraft Checklist',
    'Safety Equipment Verification',
    'Shift Handover Checklist'
  ) AND g.is_active = true
) AND is_active = true;

-- ═══════ 5. ISO Maturity: points_weight = 5 (max scale option) ═══════

UPDATE criteria SET points_weight = 5
WHERE group_id IN (
  SELECT g.id FROM groups g
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'ISO Maturity Assessment'
    AND g.is_active = true
) AND input_type = 'scale'
  AND is_active = true;

-- ═══════ VERIFICATION ═══════

SELECT '--- Remaining weight=1.0 on top-level groups ---' AS check;
SELECT t.title, g.title AS section, g.weight
FROM groups g JOIN templates t ON g.template_id = t.id
WHERE g.is_active AND t.is_active AND g.parent_id IS NULL AND g.weight = 1.0;

SELECT '--- Remaining non-null weight on sub-sections ---' AS check;
SELECT count(*) AS count FROM groups
WHERE parent_id IS NOT NULL AND weight IS NOT NULL AND is_active;

SELECT '--- Survey/checklist criteria still with points_weight ---' AS check;
SELECT count(*) AS count FROM criteria c
JOIN groups g ON c.group_id = g.id
JOIN templates t ON g.template_id = t.id
WHERE t.scoring_logic_config::text LIKE '%survey%'
  AND c.points_weight IS NOT NULL AND c.is_active;

COMMIT;
