\pset pager off
SET client_encoding = 'UTF8';
\t on
\a
SELECT id, '|', name FROM areas ORDER BY name;
SELECT id, '|', name, '|', area_id FROM stores ORDER BY name;
