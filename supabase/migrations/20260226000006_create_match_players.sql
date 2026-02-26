-- Migration: create_match_players

CREATE TYPE IF NOT EXISTS evaluation_status AS ENUM ('pending', 'completed', 'incomplete');

CREATE TABLE IF NOT EXISTS match_players (
  id               UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id         UUID              NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  team_member_id   UUID              NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  evaluation_status evaluation_status NOT NULL DEFAULT 'pending',

  CONSTRAINT uq_match_players_match_member UNIQUE (match_id, team_member_id)
);

ALTER TABLE match_players ENABLE ROW LEVEL SECURITY;

-- Miembros del equipo pueden ver los participantes de un partido
CREATE POLICY "Team members can view match players"
  ON match_players
  FOR SELECT
  USING (
    match_id IN (
      SELECT m.id FROM matches m
      JOIN team_members tm ON tm.team_id = m.team_id
      WHERE tm.user_id = auth.uid()
    )
  );

-- Solo admins pueden insertar/actualizar match_players
CREATE POLICY "Team admins can insert match players"
  ON match_players
  FOR INSERT
  WITH CHECK (
    match_id IN (
      SELECT m.id FROM matches m
      JOIN team_members tm ON tm.team_id = m.team_id
      WHERE tm.user_id = auth.uid() AND tm.is_admin = true
    )
  );

CREATE POLICY "Team admins can update match players"
  ON match_players
  FOR UPDATE
  USING (
    match_id IN (
      SELECT m.id FROM matches m
      JOIN team_members tm ON tm.team_id = m.team_id
      WHERE tm.user_id = auth.uid() AND tm.is_admin = true
    )
  );
