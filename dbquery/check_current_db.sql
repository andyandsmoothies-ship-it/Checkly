-- Check answers count
SELECT count(*) FROM answers WHERE submission_id = '0172ddab-45c6-4da5-88c7-112a74295280';

-- Check submission_section_scores count
SELECT count(*) FROM submission_section_scores WHERE submission_id = '0172ddab-45c6-4da5-88c7-112a74295280';

-- Check submission_risks count
SELECT count(*) FROM submission_risks WHERE submission_id = '0172ddab-45c6-4da5-88c7-112a74295280';
