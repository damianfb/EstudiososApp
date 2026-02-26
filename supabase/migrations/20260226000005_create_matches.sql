-- Migration: create_matches

CREATE TYPE IF NOT EXISTS match_type AS ENUM ('friendly', 'official');
CREATE TYPE IF NOT EXISTS match_status AS ENUM ('pending', 'played', 'evaluating', 'closed');

CREATE TABLE IF NOT EXISTS matches (
  id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id             UUID         NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  league_id           UUID         REFERENCES leagues(id) ON DELETE SET NULL,
  opponent_name       VARCHAR(100) NOT NULL,
  match_type          match_type   NOT NULL,
  played_at           TIMESTAMPTZ  NOT NULL,
  goals_for           INTEGER,
  goals_against       INTEGER,
  captain_id          UUID         REFERENCES team_members(id) ON DELETE SET NULL,
  status              match_status NOT NULL DEFAULT 'pending',
  evaluation_deadline TIMESTAMPTZ,
  created_by          UUID         NOT NULL REFERENCES users(id),
  created_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ  NOT NULL DEFAULT now()
);

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- Miembros del equipo pueden ver partidos de su equipo
CREATE POLICY "Team members can view their team's matches"
  ON matches
  FOR SELECT
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Solo admins pueden crear partidos
CREATE POLICY "Team admins can insert matches"
  ON matches
  FOR INSERT
  WITH CHECK (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );

-- Solo admins pueden actualizar partidos
CREATE POLICY "Team admins can update matches"
  ON matches
  FOR UPDATE
  USING (
    team_id IN (
      SELECT team_id FROM team_members WHERE user_id = auth.uid() AND is_admin = true
    )
  );
