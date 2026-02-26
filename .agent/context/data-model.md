# Modelo de Datos

## `users`
| Campo | Tipo | Restricciones |
|-------|------|---------------|
| id | UUID | PK |
| name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(150) | UNIQUE, NOT NULL |
| password_hash | VARCHAR | NOT NULL |
| avatar_url | VARCHAR | NULLABLE |
| created_at | TIMESTAMP | NOT NULL |
| updated_at | TIMESTAMP | NOT NULL |

---

## `teams`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| name | VARCHAR(100) | NOT NULL | |
| shield_url | VARCHAR | NULLABLE | Escudo del equipo |
| invite_code | VARCHAR(20) | UNIQUE, NOT NULL | Código de invitación |
| evaluation_time_limit_hours | INTEGER | NOT NULL, DEFAULT 48 | Horas límite para evaluar |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

---

## `team_members`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| team_id | UUID | FK → teams | |
| user_id | UUID | FK → users | |
| is_admin | BOOLEAN | DEFAULT false | Puede gestionar el equipo |
| is_coach | BOOLEAN | DEFAULT false | Rol de DT (opcional) |
| jersey_number | INTEGER | NULLABLE | Número de camiseta |
| position | VARCHAR(50) | NULLABLE | Posición habitual |
| is_active | BOOLEAN | DEFAULT true | Baja lógica |
| joined_at | TIMESTAMP | NOT NULL | |

- Índice único: `(team_id, user_id)`
- Un usuario puede tener múltiples filas en esta tabla (una por equipo).
- `is_admin` e `is_coach` son independientes entre sí y del rol de jugador.

---

## `leagues`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| team_id | UUID | FK → teams | Equipo que la creó |
| name | VARCHAR(100) | NOT NULL | |
| season | VARCHAR(50) | NULLABLE | Ej: "2025", "Apertura 2025" |
| created_at | TIMESTAMP | NOT NULL | |

> MVP: dato informativo, sin gestión de fixtures ni tabla de posiciones.

---

## `matches`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| team_id | UUID | FK → teams | |
| league_id | UUID | FK → leagues, NULLABLE | Solo si es partido oficial de una liga |
| opponent_name | VARCHAR(100) | NOT NULL | |
| match_type | ENUM | NOT NULL | `friendly` / `official` |
| played_at | TIMESTAMP | NOT NULL | |
| goals_for | INTEGER | NULLABLE | Cargado por Admin al marcar como jugado |
| goals_against | INTEGER | NULLABLE | Cargado por Admin al marcar como jugado |
| captain_id | UUID | FK → team_members, NULLABLE | |
| status | ENUM | NOT NULL | `pending` / `played` / `evaluating` / `closed` |
| evaluation_deadline | TIMESTAMP | NULLABLE | Calculado al pasar a `played` |
| created_by | UUID | FK → users | |
| created_at | TIMESTAMP | NOT NULL | |
| updated_at | TIMESTAMP | NOT NULL | |

---

## `match_players`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| team_member_id | UUID | FK → team_members | |
| evaluation_status | ENUM | NOT NULL, DEFAULT `pending` | `pending` / `completed` / `incomplete` |

- Índice único: `(match_id, team_member_id)`

---

## `evaluations`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| evaluator_id | UUID | FK → team_members | Quien evalúa |
| status | ENUM | NOT NULL | `pending` / `completed` / `incomplete` |
| submitted_at | TIMESTAMP | NULLABLE | |

- Índice único: `(match_id, evaluator_id)`

---

## `player_ratings`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| evaluation_id | UUID | FK → evaluations | |
| rated_team_member_id | UUID | FK → team_members | Jugador puntuado |
| score | DECIMAL(3,1) | NOT NULL, CHECK 1-10 | |

- Índice único: `(evaluation_id, rated_team_member_id)`
- Incluye autopuntuación (el evaluador puede puntuarse a sí mismo).
- El anonimato se garantiza porque nunca se expone `evaluation_id` relacionado al evaluador en consultas públicas.

---

## `feedback_assignments`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| giver_id | UUID | FK → team_members | Quien da la devolución |
| receiver_id | UUID | FK → team_members | Quien la recibe |
| strengths | TEXT | NULLABLE | Virtudes |
| improvements | TEXT | NULLABLE | Aspectos a mejorar |
| is_completed | BOOLEAN | DEFAULT false | |

- Índice único: `(match_id, giver_id, receiver_id)`
- Las filas se generan automáticamente al pasar el partido a `evaluating` (Edge Function `assign-feedback`).
- El jugador completa las devoluciones desde la app.
- `giver_id` **nunca** se expone al receiver (anonimato garantizado por RLS).

---

## `mvp_votes`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| voter_id | UUID | FK → team_members | |
| voted_for_id | UUID | FK → team_members | |

- Índice único: `(match_id, voter_id)` → 1 voto por jugador por partido.

---

## `play_of_match_votes`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| voter_id | UUID | FK → team_members | |
| protagonist_id | UUID | FK → team_members | Jugador protagonista de la jugada |
| description | TEXT | NOT NULL | Descripción libre de la jugada |

- Índice único: `(match_id, voter_id)` → 1 voto por jugador por partido.

---

## `team_feedback`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches | |
| team_member_id | UUID | FK → team_members | |
| positives | TEXT | NULLABLE | |
| improvements | TEXT | NULLABLE | |

- Índice único: `(match_id, team_member_id)`

---

## `match_summary`
| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | UUID | PK | |
| match_id | UUID | FK → matches, UNIQUE | 1 resumen por partido |
| mvp_ids | UUID[] | NOT NULL | Destacado(s) más votados (puede haber empate) |
| play_protagonist_id | UUID | FK → team_members, NULLABLE | |
| play_descriptions | TEXT[] | NULLABLE | 2-3 descripciones al azar |
| generated_at | TIMESTAMP | NOT NULL | |

---

## Diagrama de relaciones

```
users
 └──< team_members >──── teams
                          └──< leagues
                          └──< matches
                                ├── captain_id → team_members
                                └──< match_players → team_members

matches
 └──< evaluations (por jugador)
       └──< player_ratings
 └──< feedback_assignments (giver → receiver)
 └──< mvp_votes
 └──< play_of_match_votes
 └──< team_feedback
 └── match_summary
```
