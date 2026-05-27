SELECT DISTINCT section_title, COUNT(*) FROM submission_section_scores GROUP BY section_title;
SELECT id, template_title, status, total_score, section_scores FROM submissions LIMIT 5;
SELECT COUNT(*) FROM submission_section_scores;
