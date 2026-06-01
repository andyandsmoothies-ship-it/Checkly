SELECT date, status, computed_at, LEFT(payload::text, 300) as payload_preview FROM bod_report_snapshots ORDER BY date DESC;
