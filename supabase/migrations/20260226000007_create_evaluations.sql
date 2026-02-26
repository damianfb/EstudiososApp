-- Migration: create_evaluations
-- CRÍTICO: evaluator_id nunca debe ser expuesto en consultas públicas.
-- Cada jugador solo puede ver su propia evaluación.

CREATE TABLE IF NOT EXISTS evaluations (
  id            UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID              NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  evaluator_id  UUID              NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  status        evaluation_status NOT NULL DEFAULT 'pending',
  submitted_at  TIMESTAMPTZ,

  CONSTRAINT uq_evaluations_match_evaluator UNIQUE (match_id, evaluator_id)
);

ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;

-- CRÍTICO: cada jugador solo puede ver su propia evaluación
-- Se usa evaluator_id solo para filtrar hacia el propio usuario, nunca expuesto a otros
CREATE POLICY "Evaluators can view their own evaluation"
  ON evaluations
  FOR SELECT
  USING (
    evaluator_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Cada jugador puede insertar su propia evaluación
CREATE POLICY "Evaluators can insert their own evaluation"
  ON evaluations
  FOR INSERT
  WITH CHECK (
    evaluator_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Cada jugador puede actualizar su propia evaluación
CREATE POLICY "Evaluators can update their own evaluation"
  ON evaluations
  FOR UPDATE
  USING (
    evaluator_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );
