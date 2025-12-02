-- Seed household members for dev household
-- Run as superuser to bypass RLS

INSERT INTO household_members (household_id, name, email, is_active)
SELECT '00000000-0000-0000-0000-000000000001', 'Cooper', 'cooper@mccall.home', true
WHERE NOT EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = '00000000-0000-0000-0000-000000000001' AND name = 'Cooper'
);

INSERT INTO household_members (household_id, name, email, is_active)
SELECT '00000000-0000-0000-0000-000000000001', 'Ashlyn', 'ashlyn@mccall.home', true
WHERE NOT EXISTS (
    SELECT 1 FROM household_members
    WHERE household_id = '00000000-0000-0000-0000-000000000001' AND name = 'Ashlyn'
);
