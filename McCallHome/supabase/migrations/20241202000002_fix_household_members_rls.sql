-- Allow public access for dev mode (household members)
-- In production, you'd want proper auth

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their household members" ON household_members;
DROP POLICY IF EXISTS "Users can manage their household members" ON household_members;

-- Create permissive policies for dev
CREATE POLICY "Allow all reads on household_members"
    ON household_members FOR SELECT
    USING (true);

CREATE POLICY "Allow all writes on household_members"
    ON household_members FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Allow all updates on household_members"
    ON household_members FOR UPDATE
    USING (true);

CREATE POLICY "Allow all deletes on household_members"
    ON household_members FOR DELETE
    USING (true);
