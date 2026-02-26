-- Migration: create_match_summary
-- Solo puede ser insertado/actualizado por el sistema (Edge Functions mediante service role).
-- Todos los miembros del equipo pueden leer el resumen cuando el partido está closed.

CREATE TABLE IF NOT EXISTS match_summary (
  id                  UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id            UUID    NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  mvp_ids             UUID[]  NOT NULL DEFAULT '{}',
  play_protagonist_id UUID    REFERENCES team_members(id) ON DELETE SET NULL,
  play_descriptions   TEXT[],
  generated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE match_summary ENABLE ROW LEVEL SECURITY;

-- Todos los miembros del equipo pueden leer el resumen cuando el partido está closed
CREATE POLICY "Team members can read match summary when match is closed"
  ON match_summary
  FOR SELECT
  USING (
    match_id IN (
      SELECT m.id FROM matches m
      JOIN team_members tm ON tm.team_id = m.team_id
      WHERE tm.user_id = auth.uid() AND m.status = 'closed'
    )
  );

-- Solo el service role puede insertar/actualizar el resumen (Edge Functions).
-- No se crea política para INSERT/UPDATE desde el cliente; el service role bypasea RLS.
