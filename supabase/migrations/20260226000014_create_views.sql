-- Migration: create_views

-- View: player_match_ratings_summary
-- Expone el puntaje promedio recibido por cada jugador en cada partido, sin revelar quién asignó cada nota.
-- Solo muestra datos de partidos en estado 'closed' para garantizar el anonimato hasta el cierre.
CREATE OR REPLACE VIEW player_match_ratings_summary AS
SELECT
  pr.rated_team_member_id,
  e.match_id,
  ROUND(AVG(pr.score), 2) AS average_score,
  COUNT(pr.id)            AS total_ratings
FROM player_ratings pr
JOIN evaluations e ON e.id = pr.evaluation_id
JOIN matches m ON m.id = e.match_id
WHERE m.status = 'closed'
GROUP BY pr.rated_team_member_id, e.match_id;

-- View: feedback_received
-- Expone las devoluciones recibidas por cada jugador excluyendo intencionalmente giver_id.
-- Garantiza el anonimato del que escribió la devolución a nivel de base de datos.
-- Los receptores deben consultar esta view en lugar de la tabla feedback_assignments.
CREATE OR REPLACE VIEW feedback_received AS
SELECT
  fa.id,
  fa.match_id,
  fa.receiver_id,
  fa.strengths,
  fa.improvements,
  fa.is_completed
FROM feedback_assignments fa
JOIN matches m ON m.id = fa.match_id
WHERE m.status = 'closed';
-- Nota: giver_id intencionalmente excluido de esta view para garantizar anonimato

-- View: team_feedback_consolidated
-- Expone el contenido colectivo del equipo para un partido sin revelar quién escribió cada ítem.
-- Solo muestra datos de partidos en estado 'closed'.
CREATE OR REPLACE VIEW team_feedback_consolidated AS
SELECT
  tf.id,
  tf.match_id,
  tf.positives,
  tf.improvements
FROM team_feedback tf
JOIN matches m ON m.id = tf.match_id
WHERE m.status = 'closed';
-- Nota: team_member_id intencionalmente excluido de esta view para garantizar anonimato
