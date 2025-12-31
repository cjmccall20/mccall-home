-- Function to get household by ID (bypasses RLS for join flow)
-- This allows users to see the name of a household they're being invited to join
CREATE OR REPLACE FUNCTION get_household_by_id(target_household_id UUID)
RETURNS JSONB AS $$
BEGIN
    RETURN (
        SELECT jsonb_build_object('id', id, 'name', name)
        FROM households WHERE id = target_household_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
