-- ============================================================
-- Hotfix: Backfill Unified Template Engine Columns
-- ============================================================
-- Run this script to update existing databases created before the 
-- Template Engine updates (scoring_logic_config, display_noun, minus_impact).

SET client_encoding = 'UTF8';

-- 1. Templates: Default to Penalty mode and 'Audit' display noun
UPDATE templates 
SET scoring_logic_config = '{"scoringMode":"penalty"}',
    display_noun = 'Audit'
WHERE scoring_logic_config IS NULL OR display_noun IS NULL;

-- 2. Criteria: Default minus_impact to points_weight for backwards compatibility
-- This ensures Penalty scoring works mechanically the same as the old engine.
UPDATE criteria
SET minus_impact = points_weight
WHERE minus_impact IS NULL AND points_weight IS NOT NULL;

-- 3. Criteria: Fix any legacy 'boolean' input types to 'pass_fail'
UPDATE criteria
SET input_type = 'pass_fail'
WHERE input_type = 'boolean';

SELECT 'Hotfix applied successfully. Affected templates updated.' AS status;
