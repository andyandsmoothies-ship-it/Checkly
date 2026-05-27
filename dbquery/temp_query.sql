SELECT "SectionTitle", COUNT(*), AVG("Score"), AVG("MaxScore")
FROM "SubmissionSectionScores"
GROUP BY "SectionTitle";
