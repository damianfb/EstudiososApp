-- Migration: create_player_ratings
-- CRÍTICO para anonimato: un jugador NO puede leer las puntuaciones individuales de otros evaluadores.
-- Los promedios se consultan mediante la view player_match_ratings_summary, solo cuando el partido está closed.

CREATE TABLE IF NOT EXISTS player_ratings (
  id                    UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  evaluation_id         UUID         NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
  rated_team_member_id  UUID         NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  score                 DECIMAL(3,1) NOT NULL CHECK (score >= 1 AND score <= 10),

  CONSTRAINT uq_player_ratings_eval_member UNIQUE (evaluation_id, rated_team_member_id)
);

ALTER TABLE player_ratings ENABLE ROW LEVEL SECURITY;

-- CRÍTICO: solo el dueño de la evaluación puede insertar y leer sus propios ratings.
-- NO se permite SELECT general que exponga qué evaluador asignó qué puntuación.
-- Los promedios se consultan exclusivamente mediante la view player_match_ratings_summary.
CREATE POLICY "Evaluators can view their own ratings"
  ON player_ratings
  FOR SELECT
  USING (
    evaluation_id IN (
      SELECT id FROM evaluations WHERE evaluator_id IN (
        SELECT id FROM team_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Evaluators can insert their own ratings"
  ON player_ratings
  FOR INSERT
  WITH CHECK (
    evaluation_id IN (
      SELECT id FROM evaluations WHERE evaluator_id IN (
        SELECT id FROM team_members WHERE user_id = auth.uid()
      )
    )
  );
