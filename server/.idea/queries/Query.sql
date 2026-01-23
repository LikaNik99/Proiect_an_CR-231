-- Subjects
INSERT INTO subjects (id, name) VALUES
  ('55555555-5555-5555-5555-555555555555'::uuid, 'Mathematics'),
  ('66666666-6666-6666-6666-666666666666'::uuid, 'History');

-- Schools
INSERT INTO schools (id, name, location, phone, email, created_at, updated_at) VALUES
  ('11111111-1111-1111-1111-111111111111'::uuid, 'Liceul Nr.1', 'Str. Exemplu 1, City', '0211234567', 'contact@liceu1.example', now(), now()),
  ('22222222-2222-2222-2222-222222222222'::uuid, 'Scoala Gimnaziala 2', 'Str. Alt Exemplu 2, City', NULL, NULL, now(), now());

-- Classes (referencing schools)
INSERT INTO classes (id, name, school_id, created_at, updated_at) VALUES
  ('33333333-3333-3333-3333-333333333333'::uuid, '10A', '11111111-1111-1111-1111-111111111111'::uuid, now(), now()),
  ('44444444-4444-4444-4444-444444444444'::uuid, '9B', '22222222-2222-2222-2222-222222222222'::uuid, now(), now());

-- Users
INSERT INTO users (id, username, email, password, role, is_activated, school_id, class_id, created_at, updated_at) VALUES
  ('77777777-7777-7777-7777-777777777777'::uuid, 'Sasa', 'admin@example.com', NULL, 'ADMIN', true, NULL, NULL, now(), now()),
  ('88888888-8888-8888-8888-888888888888'::uuid, 'director1', 'director1@liceu1.example', NULL, 'DIRECTOR', true, '11111111-1111-1111-1111-111111111111'::uuid, NULL, now(), now()),
  ('99999999-9999-9999-9999-999999999999'::uuid, 'teacher1', 'teacher1@liceu1.example', NULL, 'TEACHER', true, '11111111-1111-1111-1111-111111111111'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, now(), now()),
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'::uuid, 'parent1', 'parent1@example.com', NULL, 'PARENT', true, NULL, NULL, now(), now()),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 'student1', 'student1@liceu1.example', NULL, 'STUDENT', true, '11111111-1111-1111-1111-111111111111'::uuid, '33333333-3333-3333-3333-333333333333'::uuid, now(), now());

-- Parents
INSERT INTO parents (id, full_name, phone, email) VALUES
  ('cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid, 'Ioana Popescu', '0712345678', 'ioana.popescu@example.com');

-- Directors (user_id is primary key referencing users.id)
INSERT INTO directors (user_id) VALUES
  ('88888888-8888-8888-8888-888888888888'::uuid);

-- Teachers (user_id is primary key referencing users.id)
INSERT INTO teachers (user_id, is_homeroom) VALUES
  ('99999999-9999-9999-9999-999999999999'::uuid, true);

-- Students (user_id is primary key referencing users.id)
INSERT INTO students (user_id, parent_id) VALUES
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, 'cccccccc-cccc-cccc-cccc-cccccccccccc'::uuid);

-- Grades (respect CheckConstraint value between 2 and 10)
INSERT INTO grades (id, value, types, created_at, updated_at, student_id, teacher_id, subject_id) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd'::uuid, 9, 'EXAM', now(), now(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, '99999999-9999-9999-9999-999999999999'::uuid, '55555555-5555-5555-5555-555555555555'::uuid),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'::uuid, 8, 'TEST', now(), now(), 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'::uuid, '99999999-9999-9999-9999-999999999999'::uuid, '66666666-6666-6666-6666-666666666666'::uuid);
