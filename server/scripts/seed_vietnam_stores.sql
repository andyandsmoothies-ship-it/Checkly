-- Seed Vietnam stores with GPS and area assignments
-- Uses area IDs from the database

SET client_encoding = 'UTF8';

-- Assign existing stores to areas (HCM 1)
UPDATE stores SET area_id = 'd1a7f2eb-d953-4d3e-bf90-165223e2b636' WHERE area_id IS NULL;

-- Insert new stores across Vietnam
INSERT INTO stores (id, name, address, area_id, gps_lat, gps_lng, is_active, created_at, updated_at)
VALUES
  -- HCM 1 stores
  (gen_random_uuid(), 'Checkly Quan 1',       '45 Le Duan, Quan 1, TP.HCM',          'd1a7f2eb-d953-4d3e-bf90-165223e2b636', 10.7769, 106.7009, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Quan 7',       '12 Nguyen Luong Bang, Quan 7, TP.HCM', 'd1a7f2eb-d953-4d3e-bf90-165223e2b636', 10.7340, 106.7218, true, NOW(), NOW()),

  -- HCM 2 stores
  (gen_random_uuid(), 'Checkly Tan Binh',     '200 Hoang Van Thu, Tan Binh, TP.HCM', '1efa6b59-c396-4664-88de-1ddd22ecd666', 10.8025, 106.6632, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Go Vap',       '55 Quang Trung, Go Vap, TP.HCM',     '1efa6b59-c396-4664-88de-1ddd22ecd666', 10.8386, 106.6649, true, NOW(), NOW()),

  -- Mien Bac stores (Hanoi)
  (gen_random_uuid(), 'Checkly Hoan Kiem',    '1 Hang Bai, Hoan Kiem, Ha Noi',       '8b037163-48bb-4ce5-9ce6-fad7c5e067e7', 21.0285, 105.8542, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Cau Giay',     '120 Xuan Thuy, Cau Giay, Ha Noi',     '8b037163-48bb-4ce5-9ce6-fad7c5e067e7', 21.0351, 105.7950, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Hai Ba Trung', '88 Pho Hue, Hai Ba Trung, Ha Noi',    '8b037163-48bb-4ce5-9ce6-fad7c5e067e7', 21.0117, 105.8588, true, NOW(), NOW()),

  -- Mien Trung stores (Da Nang + Hue)
  (gen_random_uuid(), 'Checkly Hai Chau',     '35 Bach Dang, Hai Chau, Da Nang',     'cdcb4497-5803-4db6-a192-00cd36324b80', 16.0678, 108.2208, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Son Tra',      '18 An Thuong, Son Tra, Da Nang',      'cdcb4497-5803-4db6-a192-00cd36324b80', 16.0868, 108.2316, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Hue',          '5 Le Loi, TP Hue',                    'cdcb4497-5803-4db6-a192-00cd36324b80', 16.4637, 107.5909, true, NOW(), NOW()),

  -- Mien Dong stores (Binh Duong + Dong Nai)
  (gen_random_uuid(), 'Checkly Thu Dau Mot',  '10 CMT8, Thu Dau Mot, Binh Duong',    'dd998a33-5e9e-4418-bed3-6e06cc925677', 11.0060, 106.6519, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Bien Hoa',     '22 Nguyen Ai Quoc, Bien Hoa, Dong Nai','dd998a33-5e9e-4418-bed3-6e06cc925677', 10.9574, 106.8427, true, NOW(), NOW()),

  -- Mien Tay stores (Can Tho + Long An)
  (gen_random_uuid(), 'Checkly Ninh Kieu',    '88 Ngo Quyen, Ninh Kieu, Can Tho',    'dcbd16b4-8573-4fda-a826-4eadcb121e14', 10.0341, 105.7675, true, NOW(), NOW()),
  (gen_random_uuid(), 'Checkly Tan An',       '12 Quoc Lo 1A, Tan An, Long An',      'dcbd16b4-8573-4fda-a826-4eadcb121e14', 10.5330, 106.4113, true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Verify result
SELECT name, area_id, gps_lat, gps_lng FROM stores ORDER BY name;
