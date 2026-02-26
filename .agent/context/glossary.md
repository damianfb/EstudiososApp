# Glosario de Términos del Dominio

| Término (ES) | Término (EN) | Definición |
|---|---|---|
| **Equipo** | Team | Grupo de jugadores que compiten juntos. Un usuario puede pertenecer a más de un equipo simultáneamente. Tabla: `teams`. |
| **Miembro del equipo** | Team Member | Relación entre un usuario y un equipo. Contiene roles y datos específicos del equipo (número de camiseta, posición, etc.). Tabla: `team_members`. |
| **Administrador de Equipo** | Team Admin | Miembro con `is_admin = true`. Gestiona el equipo, crea partidos, carga resultados y puede cerrar evaluaciones manualmente. |
| **Director Técnico (DT)** | Coach | Miembro con `is_coach = true`. Rol opcional. Evalúa a todos los jugadores del partido. Puede ser también jugador. |
| **Capitán del partido** | Match Captain | Jugador designado para un partido específico (campo `captain_id` en `matches`). Tiene el doble de devoluciones asignadas (6 vs. 3). |
| **Partido** | Match | Encuentro deportivo registrado en la app. Puede ser amistoso (`friendly`) u oficial (`official`). Tabla: `matches`. |
| **Liga** | League | Competición en la que participa el equipo. Dato informativo en el MVP (sin fixtures ni tabla de posiciones). Tabla: `leagues`. |
| **Evaluación** | Evaluation | Conjunto de acciones que un jugador realiza sobre un partido en estado `EVALUATING`: puntuar a compañeros, completar devoluciones, votar MVP, etc. Tabla: `evaluations`. |
| **Puntuación** | Rating | Nota del 1 al 10 que un jugador asigna a cada participante del partido, incluyéndose a sí mismo. Tabla: `player_ratings`. |
| **Devolución** | Feedback | Comentario estructurado con dos campos (virtudes + aspectos a mejorar) que un jugador da a otro de forma anónima. Tabla: `feedback_assignments`. |
| **Asignación de devolución** | Feedback Assignment | Registro generado automáticamente por el sistema al pasar a `EVALUATING`. Indica quién debe dar devolución a quién. |
| **Destacado** | MVP | Jugador más votado del partido. En caso de empate, se muestran todos los más votados. Tabla: `mvp_votes`. |
| **Jugada del partido** | Play of the Match | Jugada votada por los participantes. Se muestra el protagonista más votado + 2-3 descripciones seleccionadas al azar. Tabla: `play_of_match_votes`. |
| **Aspectos del equipo** | Team Feedback | Reflexión colectiva sobre el partido a nivel equipo: positivos y aspectos a mejorar del equipo como conjunto. Tabla: `team_feedback`. |
| **Resumen del partido** | Match Summary | Documento generado automáticamente al cerrar el partido. Consolida MVP, jugada del partido y aspectos del equipo. Tabla: `match_summary`. |
| **Plantel** | Roster | Conjunto de jugadores activos (`is_active = true`) de un equipo. |
| **Código de invitación** | Invite Code | Código único de un equipo (`invite_code` en `teams`) que los jugadores usan para unirse. |
| **Tiempo límite de evaluación** | Evaluation Time Limit | Horas disponibles para evaluar desde que el partido pasa a `PLAYED`. Configurable por equipo (`evaluation_time_limit_hours`, default 48 hs). |
| **Fecha límite de evaluación** | Evaluation Deadline | Timestamp calculado al pasar el partido a `PLAYED`. Determina cuándo se cierra automáticamente el período de evaluación. Campo `evaluation_deadline` en `matches`. |
| **Estado del partido** | Match Status | Ciclo de vida del partido: `pending` → `played` → `evaluating` → `closed`. |
| **Estado de evaluación** | Evaluation Status | Estado de la evaluación de un jugador en un partido: `pending` / `completed` / `incomplete`. Campo `evaluation_status` en `match_players`. |
| **Baja lógica** | Soft Delete | El campo `is_active = false` en `team_members` indica que un jugador ya no está activo en el equipo, sin eliminar el registro. |
| **RLS** | Row Level Security | Mecanismo de PostgreSQL/Supabase que restringe el acceso a filas según el usuario autenticado. Garantiza el anonimato de puntuaciones y devoluciones a nivel de base de datos. |
| **Edge Function** | Edge Function | Función serverless de Supabase escrita en TypeScript. Se usa para lógica de negocio compleja: `assign-feedback`, `close-match`, `generate-summary`. |
| **Realtime** | Realtime | Funcionalidad de Supabase para notificaciones en tiempo real. Se usa para avisar a jugadores cuando un partido pasa a `evaluating` o `closed`. |
