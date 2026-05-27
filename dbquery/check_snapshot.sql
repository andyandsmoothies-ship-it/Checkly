SELECT date, status, jsonb_object_keys(payload) as key FROM bod_report_snapshots;
