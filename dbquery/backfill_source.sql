UPDATE action_plans ap
SET "SourceTitle" = 
    CASE 
        WHEN p.title IS NOT NULL THEN 'Campaign: ' || p.title
        WHEN s.template_title IS NOT NULL THEN 'Audit: ' || s.template_title
        ELSE 'Audit: Unknown'
    END
FROM submissions s
LEFT JOIN program_assignments pa ON s.program_assignment_id = pa.id
LEFT JOIN programs p ON pa.program_id = p.id
WHERE ap.submission_id = s.id AND ap."SourceTitle" IS NULL;
