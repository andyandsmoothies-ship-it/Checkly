ALTER TABLE groups ADD COLUMN IF NOT EXISTS minus_per_fault decimal NULL;

UPDATE groups
SET max_deduction_points = (metadata->>'subsection_max_points')::numeric
WHERE metadata IS NOT NULL
  AND metadata->>'subsection_max_points' IS NOT NULL
  AND max_deduction_points IS NULL;

UPDATE groups
SET minus_per_fault = (metadata->>'minus_per_fault')::numeric
WHERE metadata IS NOT NULL
  AND metadata->>'minus_per_fault' IS NOT NULL;
