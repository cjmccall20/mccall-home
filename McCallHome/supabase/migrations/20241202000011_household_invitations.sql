-- =====================================================
-- Household Invitations Table
-- =====================================================
-- Manages invitations to join households via email

CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'declined', 'expired', 'revoked');

CREATE TABLE IF NOT EXISTS household_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    household_id UUID NOT NULL REFERENCES households(id) ON DELETE CASCADE,

    -- Invitation details
    email TEXT NOT NULL,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Token for secure acceptance (using UUID without hyphens as token)
    token TEXT NOT NULL UNIQUE DEFAULT replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),

    -- Status tracking
    status invitation_status DEFAULT 'pending',
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),

    -- Response tracking
    responded_at TIMESTAMPTZ,
    accepted_by UUID REFERENCES users(id),

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invitations_household ON household_invitations(household_id);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON household_invitations(email);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON household_invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_status ON household_invitations(status);

-- Enable RLS
ALTER TABLE household_invitations ENABLE ROW LEVEL SECURITY;

-- Users can view invitations for their household
CREATE POLICY "Users can view their household invitations"
    ON household_invitations FOR SELECT
    USING (household_id IN (
        SELECT household_id FROM users WHERE id = auth.uid()
    ));

-- Users can create invitations for their household
CREATE POLICY "Users can create invitations for their household"
    ON household_invitations FOR INSERT
    WITH CHECK (
        household_id IN (
            SELECT household_id FROM users WHERE id = auth.uid()
        )
        AND invited_by = auth.uid()
    );

-- Users can revoke invitations they created
CREATE POLICY "Users can revoke invitations they created"
    ON household_invitations FOR UPDATE
    USING (invited_by = auth.uid())
    WITH CHECK (status = 'revoked');

-- Anyone can view invitations by token (for acceptance flow)
-- This is handled via a secure function instead of direct RLS

-- Function to accept invitation by token
CREATE OR REPLACE FUNCTION accept_invitation(invitation_token TEXT, accepting_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    inv RECORD;
    result JSONB;
BEGIN
    -- Find the invitation
    SELECT * INTO inv FROM household_invitations
    WHERE token = invitation_token
    AND status = 'pending'
    AND expires_at > NOW();

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Invalid or expired invitation');
    END IF;

    -- Update user's household
    UPDATE users
    SET household_id = inv.household_id
    WHERE id = accepting_user_id;

    -- Mark invitation as accepted
    UPDATE household_invitations
    SET status = 'accepted',
        responded_at = NOW(),
        accepted_by = accepting_user_id
    WHERE id = inv.id;

    -- Create a household member entry
    INSERT INTO household_members (household_id, name, email)
    SELECT inv.household_id, u.name, u.email
    FROM users u WHERE u.id = accepting_user_id
    ON CONFLICT DO NOTHING;

    RETURN jsonb_build_object(
        'success', true,
        'household_id', inv.household_id,
        'message', 'Successfully joined household'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get invitation details by token (public)
CREATE OR REPLACE FUNCTION get_invitation_by_token(invitation_token TEXT)
RETURNS JSONB AS $$
DECLARE
    inv RECORD;
BEGIN
    SELECT
        i.id,
        i.email,
        i.status,
        i.expires_at,
        h.name as household_name,
        u.name as invited_by_name
    INTO inv
    FROM household_invitations i
    JOIN households h ON h.id = i.household_id
    JOIN users u ON u.id = i.invited_by
    WHERE i.token = invitation_token;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('found', false);
    END IF;

    RETURN jsonb_build_object(
        'found', true,
        'id', inv.id,
        'email', inv.email,
        'status', inv.status,
        'expires_at', inv.expires_at,
        'household_name', inv.household_name,
        'invited_by_name', inv.invited_by_name,
        'is_valid', inv.status = 'pending' AND inv.expires_at > NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
