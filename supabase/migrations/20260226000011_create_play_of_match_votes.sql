-- Migration: create_play_of_match_votes
-- CRÍTICO para anonimato: voter_id NUNCA se expone a otros usuarios.
-- Los resultados solo son visibles cuando el partido está closed.

CREATE TABLE IF NOT EXISTS play_of_match_votes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  voter_id        UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  protagonist_id  UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  description     TEXT NOT NULL,

  -- 1 voto por jugador por partido
  CONSTRAINT uq_play_of_match_votes_match_voter UNIQUE (match_id, voter_id)
);

ALTER TABLE play_of_match_votes ENABLE ROW LEVEL SECURITY;

-- Cada jugador puede insertar su propio voto
CREATE POLICY "Players can insert their own play vote"
  ON play_of_match_votes
  FOR INSERT
  WITH CHECK (
    voter_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Cada jugador puede ver su propio voto
CREATE POLICY "Players can view their own play vote"
  ON play_of_match_votes
  FOR SELECT
  USING (
    voter_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- CRÍTICO: No se otorga SELECT general para evitar exponer voter_id a otros usuarios.
-- Los resultados de la jugada del partido se consumen a través de match_summary (calculado por Edge Function con service role).
