SELECT id, template_title, status, total_score, section_scores
FROM submissions
WHERE status = 'completed';
