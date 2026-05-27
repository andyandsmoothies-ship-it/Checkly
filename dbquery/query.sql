SELECT COUNT(*) FROM submission_section_scores ss LEFT JOIN submissions s ON s.id = ss.submission_id WHERE s.id IS NULL;
