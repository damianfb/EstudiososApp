-- Migration: create_leagues

CREATE TABLE IF NOT EXISTS leagues (
  id         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id    UUID         NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  name       VARCHAR(100) NOT NULL,
  season     VARCHAR(50),
  created_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

ALTER TABLE leagues ENABLE ROW LEVEL SECURITY;

-- Miembros del equipo pueden leer ligas de su equipo
CREATE POLICY "Team members can read their team's leagues"
  ON leagues
  FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Solo admins del equipo pueden crear/actualizar ligas
CREATE POLICY "Team admins can insert leagues"
  ON leagues
  FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "Team admins can update leagues"
  ON leagues
  FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );
