-- Migration: create_team_members

CREATE TABLE IF NOT EXISTS team_members (
  id             UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id        UUID         NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id        UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_admin       BOOLEAN      NOT NULL DEFAULT false,
  is_coach       BOOLEAN      NOT NULL DEFAULT false,
  jersey_number  INTEGER,
  position       VARCHAR(50),
  is_active      BOOLEAN      NOT NULL DEFAULT true,
  joined_at      TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CONSTRAINT uq_team_members_team_user UNIQUE (team_id, user_id)
);

ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

-- Miembros de un equipo pueden ver a los otros miembros del mismo equipo
CREATE POLICY "Team members can view other members of their team"
  ON team_members
  FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Solo admins pueden insertar/actualizar/desactivar miembros
CREATE POLICY "Team admins can insert members"
  ON team_members
  FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Team admins can update members"
  ON team_members
  FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );
