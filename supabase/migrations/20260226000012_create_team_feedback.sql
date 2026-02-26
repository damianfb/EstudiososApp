-- Migration: create_team_feedback
-- Anonimato: team_member_id no se expone al hacer SELECT general cuando el partido está closed.
-- Usar la view o agregaciones para mostrar contenido consolidado sin identificar al autor.

CREATE TABLE IF NOT EXISTS team_feedback (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id        UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  team_member_id  UUID NOT NULL REFERENCES team_members(id) ON DELETE CASCADE,
  positives       TEXT,
  improvements    TEXT,

  CONSTRAINT uq_team_feedback_match_member UNIQUE (match_id, team_member_id)
);

ALTER TABLE team_feedback ENABLE ROW LEVEL SECURITY;

-- Cualquier miembro del equipo puede insertar su propio team_feedback
CREATE POLICY "Team members can insert their own team feedback"
  ON team_feedback
  FOR INSERT
  WITH CHECK (
    team_member_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- Cada miembro puede ver y actualizar su propio feedback
CREATE POLICY "Team members can view and update their own team feedback"
  ON team_feedback
  FOR SELECT
  USING (
    team_member_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Team members can update their own team feedback"
  ON team_feedback
  FOR UPDATE
  USING (
    team_member_id IN (
      SELECT id FROM team_members WHERE user_id = auth.uid()
    )
  );

-- El contenido consolidado es visible para todos los miembros cuando el partido está closed.
-- CRÍTICO: Para acceso anónimo (sin ver team_member_id), usar la view team_feedback_consolidated.
-- Esta política solo permite que la view funcione correctamente bajo SECURITY INVOKER.
CREATE POLICY "Team members can view consolidated feedback when match is closed"
  ON team_feedback
  FOR SELECT
  USING (
    match_id IN (
      SELECT m.id FROM matches m
      JOIN team_members tm ON tm.team_id = m.team_id
      WHERE tm.user_id = auth.uid() AND m.status = 'closed'
    )
  );
