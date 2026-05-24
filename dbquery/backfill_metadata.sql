-- =============================================================
-- BACKFILL: Fix NULL metadata on scale/choice criteria
-- Created by Sentinel scan on 2026-03-19
-- =============================================================
-- Run: psql -h localhost -p 5432 -U postgres -d checkly -f backfill_metadata.sql

BEGIN;

-- ─── ISO Maturity Assessment (7 scale criteria) ───
-- Standard 5-level maturity scale: Initial → Optimizing
UPDATE criteria SET metadata = '{"scaleOptions": [
  {"label": "Initial",       "points": 1},
  {"label": "Managed",       "points": 2},
  {"label": "Defined",       "points": 3},
  {"label": "Controlled",    "points": 4},
  {"label": "Optimizing",    "points": 5}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'ISO Maturity Assessment'
    AND c.input_type = 'scale'
    AND c.metadata IS NULL
    AND c.is_active = true
);

-- ─── Customer Feedback Form ───

-- "What aspects did you enjoy?" (multi_choice)
UPDATE criteria SET metadata = '{"options": [
  {"label": "Customer Service", "value": "service",    "points": 0},
  {"label": "Product Quality",  "value": "quality",    "points": 0},
  {"label": "Store Atmosphere",  "value": "atmosphere", "points": 0},
  {"label": "Pricing",           "value": "pricing",    "points": 0},
  {"label": "Staff Friendliness","value": "staff",      "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Customer Feedback Form'
    AND c.label = 'What aspects did you enjoy?'
    AND c.metadata IS NULL
);

-- "How did you hear about us?" (single_choice)
UPDATE criteria SET metadata = '{"options": [
  {"label": "Social Media",    "value": "social",       "points": 0},
  {"label": "Friend / Family", "value": "referral",     "points": 0},
  {"label": "Website",         "value": "website",      "points": 0},
  {"label": "Advertisement",   "value": "ad",           "points": 0},
  {"label": "Other",           "value": "other",        "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Customer Feedback Form'
    AND c.label = 'How did you hear about us?'
    AND c.metadata IS NULL
);

-- "Would you recommend us?" (single_choice)
UPDATE criteria SET metadata = '{"options": [
  {"label": "Definitely Yes", "value": "yes",      "points": 0},
  {"label": "Probably",       "value": "probably",  "points": 0},
  {"label": "Not Sure",       "value": "not_sure",  "points": 0},
  {"label": "No",             "value": "no",        "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Customer Feedback Form'
    AND c.label = 'Would you recommend us?'
    AND c.metadata IS NULL
);

-- "Which products did you purchase?" (multi_choice)
UPDATE criteria SET metadata = '{"options": [
  {"label": "Food & Beverage",  "value": "food",       "points": 0},
  {"label": "Electronics",      "value": "electronics", "points": 0},
  {"label": "Clothing",         "value": "clothing",    "points": 0},
  {"label": "Home & Garden",    "value": "home",        "points": 0},
  {"label": "Other",            "value": "other",       "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Customer Feedback Form'
    AND c.label = 'Which products did you purchase?'
    AND c.metadata IS NULL
);

-- "Was the value for money fair?" (single_choice)
UPDATE criteria SET metadata = '{"options": [
  {"label": "Excellent", "value": "excellent", "points": 0},
  {"label": "Good",      "value": "good",      "points": 0},
  {"label": "Fair",      "value": "fair",      "points": 0},
  {"label": "Poor",      "value": "poor",      "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Customer Feedback Form'
    AND c.label = 'Was the value for money fair?'
    AND c.metadata IS NULL
);

-- ─── Employee Satisfaction Survey (7 single_choice — Likert 5-point) ───
-- All use the same satisfaction scale
UPDATE criteria SET metadata = '{"options": [
  {"label": "Very Satisfied",  "value": "5", "points": 0},
  {"label": "Satisfied",       "value": "4", "points": 0},
  {"label": "Neutral",         "value": "3", "points": 0},
  {"label": "Dissatisfied",    "value": "2", "points": 0},
  {"label": "Very Dissatisfied","value": "1", "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Employee Satisfaction Survey'
    AND c.input_type = 'single_choice'
    AND c.metadata IS NULL
    AND c.is_active = true
);

-- ─── Post-Training Feedback ───

-- Single-choice criteria (rating scale)
-- "Overall session rating", "Was the pace appropriate?", "Was the trainer knowledgeable?", "Would you attend again?"
UPDATE criteria SET metadata = '{"options": [
  {"label": "Excellent",  "value": "excellent",  "points": 0},
  {"label": "Good",       "value": "good",       "points": 0},
  {"label": "Average",    "value": "average",    "points": 0},
  {"label": "Below Average","value": "below",    "points": 0},
  {"label": "Poor",       "value": "poor",       "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Post-Training Feedback'
    AND c.input_type = 'single_choice'
    AND c.metadata IS NULL
    AND c.is_active = true
);

-- Multi-choice: "Which topics were most useful?" & "Which topics need more depth?"
UPDATE criteria SET metadata = '{"options": [
  {"label": "Theory / Concepts",  "value": "theory",    "points": 0},
  {"label": "Hands-on Exercises", "value": "hands_on",  "points": 0},
  {"label": "Case Studies",       "value": "cases",     "points": 0},
  {"label": "Group Discussions",  "value": "discussion", "points": 0},
  {"label": "Q&A Sessions",      "value": "qa",         "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Post-Training Feedback'
    AND c.input_type = 'multi_choice'
    AND c.metadata IS NULL
    AND c.is_active = true
);

-- ─── Test1 (1 multi_choice — generic test options) ───
UPDATE criteria SET metadata = '{"options": [
  {"label": "Option A", "value": "a", "points": 0},
  {"label": "Option B", "value": "b", "points": 0},
  {"label": "Option C", "value": "c", "points": 0}
]}'::jsonb
WHERE id IN (
  SELECT c.id FROM criteria c
  JOIN groups g ON c.group_id = g.id
  JOIN templates t ON g.template_id = t.id
  WHERE t.title = 'Test1'
    AND c.input_type = 'multi_choice'
    AND c.metadata IS NULL
    AND c.is_active = true
);

-- ─── Verification: count remaining NULL metadata ───
SELECT count(*) AS remaining_null
FROM criteria c
JOIN groups g ON c.group_id = g.id
JOIN templates t ON g.template_id = t.id
WHERE c.is_active = true
  AND t.is_active = true
  AND c.input_type IN ('scale', 'single_choice', 'multi_choice')
  AND c.metadata IS NULL;

COMMIT;
