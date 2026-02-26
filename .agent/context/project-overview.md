# Visión General del Proyecto

## Nombre
EstudiososApp

## Descripción
App mobile para gestión y progreso de equipos de fútbol amateur. Permite registrar partidos, evaluar jugadores de forma anónima, dar devoluciones entre compañeros y generar resúmenes del partido.

## Objetivo
Ayudar a equipos amateur a mejorar mediante evaluaciones anónimas post-partido, devoluciones entre compañeros y estadísticas de rendimiento.

## Mercado objetivo
- **MVP:** Equipos de fútbol amateur (más de 1000 equipos potenciales).
- **Futuro:** Hockey amateur y otros deportes de equipo.

## Plataforma
- **MVP:** Mobile (Flutter).
- **Futuro:** Web y multiplataforma.

## Stack tecnológico
| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Dart) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions, Realtime) |
| Base de datos | PostgreSQL (a través de Supabase) |
| Autenticación | Supabase Auth (email/password) |
| Lógica serverless | Edge Functions (TypeScript) |
| Almacenamiento | Supabase Storage |
| Tiempo real | Supabase Realtime |

## Roles de usuario

### Jugador
- Se registra con email/password.
- Pertenece a uno o más equipos simultáneamente.
- Participa de partidos y realiza evaluaciones post-partido.

### Administrador de Equipo
- Jugador con `is_admin = true` en `team_members`.
- Gestiona el equipo, el plantel y los partidos.
- Puede haber más de un administrador por equipo.
- Crea partidos, carga resultados y cierra evaluaciones manualmente.

### Capitán del partido
- Jugador designado por partido específico (campo `captain_id` en `matches`).
- Es un reconocimiento especial dentro del partido.
- Tiene el doble de devoluciones asignadas (6 vs. 3 del jugador normal).

### Director Técnico (DT / Coach)
- Rol opcional: miembro con `is_coach = true` en `team_members`.
- Puede ser también jugador (independiente de `is_admin`).
- Puntúa a todos los jugadores del partido (1-10).
- Puede dar devolución a todos (opcional, no asignado por sistema).

### *(Futuro)* Admin de Liga
- Rol a definir para gestionar ligas y calificaciones cruzadas entre equipos.

## Alcance del MVP
- Un equipo real con funcionalidades core de partido y evaluación.
- Flujo completo: crear partido → cargar resultado → evaluar → cerrar → ver resumen.
- Anonimato garantizado mediante RLS de Supabase.

## Roadmap futuro
- Plataforma multi-equipo.
- Ligas con calificaciones cruzadas entre equipos.
- Hockey amateur.
- Admin de Liga.
- Sistema de avisos y advertencias por evaluaciones incompletas.
- Votación de desempate en el destacado del partido.
