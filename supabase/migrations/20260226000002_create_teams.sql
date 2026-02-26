-- Migration: create_teams

CREATE TABLE IF NOT EXISTS teams (
  id                           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name                         VARCHAR(100) NOT NULL,
  shield_url                   TEXT,
  invite_code                  VARCHAR(20)  UNIQUE NOT NULL,
  evaluation_time_limit_hours  INTEGER      NOT NULL DEFAULT 48,
  created_at                   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at                   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

-- Usuarios autenticados pueden leer equipos en los que son miembros
CREATE POLICY "Team members can read their team"
  ON teams
  FOR SELECT
  USING (
    id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Solo admins del equipo pueden actualizar
CREATE POLICY "Team admins can update their team"
  ON teams
  FOR UPDATE
  USING (
    id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );
