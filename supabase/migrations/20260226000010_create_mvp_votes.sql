-- Migration: create_mvp_votes
-- CRÍTICO para anonimato: voter_id NUNCA se expone a otros usuarios.
-- Los resultados (conteo de votos) solo son visibles cuando el partido está closed.

CREATE TABLE IF NOT EXISTS mvp_votes (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  voter_id     UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  voted_for_id UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,

  -- 1 voto por jugador por partido
  CONSTRAINT uq_mvp_votes_match_voter UNIQUE (match_id, voter_id)
);

ALTER TABLE mvp_votes ENABLE ROW LEVEL SECURITY;

-- Cada jugador puede insertar su propio voto
CREATE POLICY "Players can insert their own MVP vote"
  ON mvp_votes
  FOR INSERT
  WITH CHECK (
    voter_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Cada jugador puede ver su propio voto
CREATE POLICY "Players can view their own MVP vote"
  ON mvp_votes
  FOR SELECT
  USING (
    voter_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- CRÍTICO: No se otorga SELECT general para evitar exponer voter_id a otros usuarios.
-- Los resultados del MVP se consumen a través de match_summary (calculado por Edge Function con service role).
