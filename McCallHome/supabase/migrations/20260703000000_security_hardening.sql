-- =====================================================
-- Security Hardening
-- =====================================================
-- Closes the RLS holes left by earlier migrations:
--   1. household_invitations SELECT/UPDATE had "OR true" — any
--      authenticated user could read and modify every invitation.
--      Token-based acceptance already goes through the SECURITY DEFINER
--      RPCs get_invitation_by_token / accept_invitation, so the open
--      policies were never needed.
--   2. honeydew_tasks / house_staples carried a hardcoded dev-household
--      backdoor ('00000000-...-0001') in some migration generations.
--      Dropped and recreated definitively here.
--   3. households INSERT was WITH CHECK (true) — anonymous inserts allowed.
--   4. users UPDATE had no WITH CHECK — any user could point their own
--      row at any household_id and read that household's data.
--      Joining a household now goes through the join_household() RPC.
--   5. users INSERT allowed pointing a brand-new profile at any existing
--      household. New profiles may only be inserted into an EMPTY
--      (freshly created) household; joining an occupied household goes
--      through accept_invitation() or join_household().
--
-- Everything here is idempotent; safe to run on a database in any of the
-- intermediate states the migration history could have produced.
-- Verification queries are at the bottom.

-- -----------------------------------------------------
-- Helper functions (SECURITY DEFINER to avoid RLS recursion)
-- -----------------------------------------------------

-- Already exists from 20241205000001; re-assert so this migration stands alone.
CREATE OR REPLACE FUNCTION get_my_household_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT household_id FROM users WHERE id = auth.uid()
$$;

-- True when no users row references the household yet.
-- Used to restrict fresh-profile INSERTs to newly created households.
CREATE OR REPLACE FUNCTION household_is_empty(target_household_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT NOT EXISTS (SELECT 1 FROM users WHERE household_id = target_household_id)
$$;

-- RPC for the homerun://join deep link. Validates the target household and
-- moves ONLY the calling user. Replaces the app's former direct UPDATE of
-- users.household_id, which the tightened users_update policy now blocks.
CREATE OR REPLACE FUNCTION join_household(target_household_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM households WHERE id = target_household_id) THEN
        RAISE EXCEPTION 'Household not found';
    END IF;

    UPDATE users SET household_id = target_household_id WHERE id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User profile not found';
    END IF;
END;
$$;

REVOKE EXECUTE ON FUNCTION join_household(UUID) FROM anon, public;
GRANT EXECUTE ON FUNCTION join_household(UUID) TO authenticated;

-- -----------------------------------------------------
-- 1. household_invitations — remove the "OR true" policies
-- -----------------------------------------------------
DROP POLICY IF EXISTS "Users can view their household invitations" ON household_invitations;
DROP POLICY IF EXISTS "Users can create invitations for their household" ON household_invitations;
DROP POLICY IF EXISTS "Users can revoke invitations they created" ON household_invitations;
DROP POLICY IF EXISTS "Allow all for household_invitations" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_select" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_insert" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_update" ON household_invitations;
DROP POLICY IF EXISTS "household_invitations_delete" ON household_invitations;

CREATE POLICY "household_invitations_select" ON household_invitations FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "household_invitations_insert" ON household_invitations FOR INSERT
    WITH CHECK (
        household_id = get_my_household_id()
        AND invited_by = (SELECT auth.uid())
    );

CREATE POLICY "household_invitations_update" ON household_invitations FOR UPDATE
    USING (household_id = get_my_household_id())
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "household_invitations_delete" ON household_invitations FOR DELETE
    USING (household_id = get_my_household_id());

-- -----------------------------------------------------
-- 2a. honeydew_tasks — kill the dev-household backdoor
-- -----------------------------------------------------
DROP POLICY IF EXISTS "Allow all for honeydew_tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can view tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can create tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can update tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can delete tasks in their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can view their household tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can create tasks for their household" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can update their household tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "Users can delete their household tasks" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_select" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_insert" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_update" ON honeydew_tasks;
DROP POLICY IF EXISTS "honeydew_tasks_delete" ON honeydew_tasks;

CREATE POLICY "honeydew_tasks_select" ON honeydew_tasks FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_insert" ON honeydew_tasks FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_update" ON honeydew_tasks FOR UPDATE
    USING (household_id = get_my_household_id())
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "honeydew_tasks_delete" ON honeydew_tasks FOR DELETE
    USING (household_id = get_my_household_id());

-- -----------------------------------------------------
-- 2b. house_staples — same backdoor pattern
-- -----------------------------------------------------
DROP POLICY IF EXISTS "Allow all for house_staples" ON house_staples;
DROP POLICY IF EXISTS "house_staples_select" ON house_staples;
DROP POLICY IF EXISTS "house_staples_insert" ON house_staples;
DROP POLICY IF EXISTS "house_staples_update" ON house_staples;
DROP POLICY IF EXISTS "house_staples_delete" ON house_staples;

CREATE POLICY "house_staples_select" ON house_staples FOR SELECT
    USING (household_id = get_my_household_id());

CREATE POLICY "house_staples_insert" ON house_staples FOR INSERT
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "house_staples_update" ON house_staples FOR UPDATE
    USING (household_id = get_my_household_id())
    WITH CHECK (household_id = get_my_household_id());

CREATE POLICY "house_staples_delete" ON house_staples FOR DELETE
    USING (household_id = get_my_household_id());

-- -----------------------------------------------------
-- 2c. household_members — drop legacy allow-all names in case the
--     20241205000000 cleanup never ran against this database
-- -----------------------------------------------------
DROP POLICY IF EXISTS "Allow all for household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all reads on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all writes on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all updates on household_members" ON household_members;
DROP POLICY IF EXISTS "Allow all deletes on household_members" ON household_members;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'household_members' AND policyname = 'household_members_select'
    ) THEN
        EXECUTE 'CREATE POLICY "household_members_select" ON household_members FOR SELECT
                     USING (household_id = get_my_household_id())';
        EXECUTE 'CREATE POLICY "household_members_insert" ON household_members FOR INSERT
                     WITH CHECK (household_id = get_my_household_id())';
        EXECUTE 'CREATE POLICY "household_members_update" ON household_members FOR UPDATE
                     USING (household_id = get_my_household_id())';
        EXECUTE 'CREATE POLICY "household_members_delete" ON household_members FOR DELETE
                     USING (household_id = get_my_household_id())';
    END IF;
END $$;

-- -----------------------------------------------------
-- 3. households — INSERT requires authentication
-- -----------------------------------------------------
DROP POLICY IF EXISTS "Allow all for households" ON households;
DROP POLICY IF EXISTS "households_insert" ON households;

CREATE POLICY "households_insert" ON households FOR INSERT
    WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

-- -----------------------------------------------------
-- 4. users — pin household_id on UPDATE, restrict INSERT
-- -----------------------------------------------------
-- get_my_household_id() is STABLE, so within the UPDATE statement it reads
-- the pre-update snapshot: the WITH CHECK below means "the new row must keep
-- the household_id you already had". Moving households happens only through
-- the SECURITY DEFINER RPCs (accept_invitation, join_household).
DROP POLICY IF EXISTS "Allow all for users" ON users;
DROP POLICY IF EXISTS "users_update" ON users;
DROP POLICY IF EXISTS "users_insert" ON users;

CREATE POLICY "users_update" ON users FOR UPDATE
    USING (id = (SELECT auth.uid()))
    WITH CHECK (
        id = (SELECT auth.uid())
        AND household_id = get_my_household_id()
    );

-- A new profile may only be created for yourself, in a household nobody
-- belongs to yet (i.e. the one the signup flow just created).
CREATE POLICY "users_insert" ON users FOR INSERT
    WITH CHECK (
        id = (SELECT auth.uid())
        AND household_is_empty(household_id)
    );

-- -----------------------------------------------------
-- 5. profiles — vestigial table; lock it down if present
-- -----------------------------------------------------
-- The app uses the `users` table exclusively. If `profiles` still exists,
-- remove its allow-all policy and leave it RLS-enabled with no policies
-- (inaccessible). Once you've confirmed it holds nothing you need, you can
-- run: DROP TABLE profiles CASCADE;
DO $$
BEGIN
    IF to_regclass('public.profiles') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE profiles ENABLE ROW LEVEL SECURITY';
        EXECUTE 'DROP POLICY IF EXISTS "Allow all for profiles" ON profiles';
    END IF;
END $$;

-- -----------------------------------------------------
-- 6. google_tokens — owner-only, if the table exists
-- -----------------------------------------------------
-- The table is referenced by older migrations but never created by one
-- (it was made in the dashboard, or never). Guarded so this runs anywhere.
DO $$
BEGIN
    IF to_regclass('public.google_tokens') IS NOT NULL THEN
        EXECUTE 'ALTER TABLE google_tokens ENABLE ROW LEVEL SECURITY';
        EXECUTE 'DROP POLICY IF EXISTS "Allow all for google_tokens" ON google_tokens';
        EXECUTE 'DROP POLICY IF EXISTS "Users can all own google_tokens" ON google_tokens';
        EXECUTE 'DROP POLICY IF EXISTS "google_tokens_select" ON google_tokens';
        EXECUTE 'DROP POLICY IF EXISTS "google_tokens_insert" ON google_tokens';
        EXECUTE 'DROP POLICY IF EXISTS "google_tokens_update" ON google_tokens';
        EXECUTE 'DROP POLICY IF EXISTS "google_tokens_delete" ON google_tokens';
        EXECUTE 'CREATE POLICY "google_tokens_select" ON google_tokens FOR SELECT
                     USING (user_id = (SELECT auth.uid()))';
        EXECUTE 'CREATE POLICY "google_tokens_insert" ON google_tokens FOR INSERT
                     WITH CHECK (user_id = (SELECT auth.uid()))';
        EXECUTE 'CREATE POLICY "google_tokens_update" ON google_tokens FOR UPDATE
                     USING (user_id = (SELECT auth.uid()))
                     WITH CHECK (user_id = (SELECT auth.uid()))';
        EXECUTE 'CREATE POLICY "google_tokens_delete" ON google_tokens FOR DELETE
                     USING (user_id = (SELECT auth.uid()))';
    END IF;
END $$;

-- -----------------------------------------------------
-- Verification (run these after applying; expected results noted)
-- -----------------------------------------------------
-- No policy should contain 'true' as a bare qual on these tables:
--   SELECT tablename, policyname, qual, with_check
--   FROM pg_policies
--   WHERE tablename IN ('household_invitations','honeydew_tasks','house_staples','users','households')
--   ORDER BY tablename, policyname;
--   -- expect: no 'OR true', no '00000000-0000-0000-0000-000000000001'
--
-- Every table in the app should have rowsecurity = true:
--   SELECT relname, relrowsecurity FROM pg_class
--   WHERE relnamespace = 'public'::regnamespace AND relkind = 'r'
--   ORDER BY relname;
--
-- The join RPC exists and is restricted:
--   SELECT proname, prosecdef FROM pg_proc WHERE proname IN
--   ('join_household','get_my_household_id','household_is_empty','accept_invitation','get_invitation_by_token');
