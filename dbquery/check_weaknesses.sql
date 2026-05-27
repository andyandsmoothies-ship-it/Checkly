SELECT date, status, payload->'weaknesses' as weaknesses FROM bod_report_snapshots WHERE date = '2026-05-25';
