-- Migration: create_feedback_assignments
-- CRÍTICO para anonimato: giver_id NUNCA se expone al receiver.
-- El receiver puede ver strengths e improvements solo cuando el partido está closed,
-- pero nunca puede ver quién los escribió.

CREATE TABLE IF NOT EXISTS feedback_assignments (
  id           UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID    NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  giver_id     UUID    NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  receiver_id  UUID    NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  strengths    TEXT,
  improvements TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT false,

  CONSTRAINT uq_feedback_assignments_match_giver_receiver UNIQUE (match_id, giver_id, receiver_id)
);

ALTER TABLE feedback_assignments ENABLE ROW LEVEL SECURITY;

-- El giver puede ver y actualizar sus propias asignaciones
CREATE POLICY "Givers can view their own assignments"
  ON feedback_assignments
  FOR SELECT
  USING (
    giver_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Givers can update their own assignments"
  ON feedback_assignments
  FOR UPDATE
  USING (
    giver_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- CRÍTICO: El receiver puede ver su propia fila (incluyendo giver_id en la tabla raw).
-- Para garantizar anonimato, los receptores deben consultar SIEMPRE la view feedback_received
-- (que excluye giver_id). Esta política solo sirve para que la view pueda funcionar correctamente.
-- Ver: supabase/migrations/20260226000014_create_views.sql
CREATE POLICY "Receivers can view their received feedback"
  ON feedback_assignments
  FOR SELECT
  USING (
    receiver_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
    AND match_id IN (
      SELECT id FROM matches WHERE status = 'closed'
    )
  );
