SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'submissions'
  AND column_name ILIKE '%template%'
ORDER BY column_name;
