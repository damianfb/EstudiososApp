# Reglas de Negocio

## Gestión del equipo

- Puede haber más de un Administrador por equipo (`is_admin = true` en `team_members`).
- El DT es opcional y puede ser también jugador (`is_coach = true`, independiente de `is_admin`).
- Los jugadores se unen al equipo con un **código de invitación** único generado por el equipo (campo `invite_code` en `teams`).
- Un jugador puede pertenecer a más de un equipo simultáneamente (una fila en `team_members` por equipo).
- El **tiempo límite de evaluación** es configurable por equipo (campo `evaluation_time_limit_hours`, default 48 hs) y editable por partido.

---

## Partidos — Estados y transiciones

```
PENDING
    ↓ (Admin marca como jugado + carga resultado)
PLAYED
    ↓ (automático: sistema genera asignaciones de devoluciones)
EVALUATING
    ↓ se cierra cuando:
    ├── ⏱️ vence el tiempo límite (evaluation_deadline), O
    ├── ✅ todos los jugadores completaron su evaluación, O
    └── 🔒 Admin cierra manualmente
CLOSED
    └── Se genera el match_summary y se habilita la visualización
```

- El partido lo **crea** el Administrador de Equipo.
- El **resultado** (goles a favor y en contra) lo carga el Administrador de Equipo al pasar a `PLAYED`.
- El **Capitán del partido** se selecciona al crear el partido o al marcarlo como jugado.
- Al pasar a `EVALUATING`, el sistema genera automáticamente las `feedback_assignments`.
- El `evaluation_deadline` se calcula al pasar a `PLAYED` sumando `evaluation_time_limit_hours` a la fecha/hora actual.
- Un equipo puede participar en más de una liga simultáneamente.
- Las ligas son dato informativo en el MVP (creadas por el Admin del equipo, sin fixtures ni tabla de posiciones).

---

## Puntuaciones (`player_ratings`)

- Cada jugador puntúa a **todos los participantes del partido**, incluyéndose a sí mismo (escala 1-10).
- El DT puntúa a **todos los jugadores** (1-10).
- Las puntuaciones son **anónimas**: cada jugador puede ver su puntaje promedio recibido, pero **nunca** quién le asignó cada puntuación individual.
- Los resultados **no son visibles** hasta que el partido esté en estado `CLOSED`.

---

## Devoluciones (`feedback_assignments`)

- Al pasar a `EVALUATING`, el sistema genera automáticamente las asignaciones (Edge Function `assign-feedback`).
- **Jugador normal:** 3 devoluciones asignadas al azar por el sistema.
- **Capitán del partido:** 6 devoluciones asignadas al azar (doble que jugador normal).
- **DT:** puede dar devolución a todos (opcional, no asignado por el sistema).
- El algoritmo garantiza que **cada jugador recibe mínimo 2 devoluciones**.
- El capitán cubre más asignaciones, lo que alivia la carga del resto y ayuda a cumplir el mínimo garantizado.
- Cada devolución tiene dos campos separados: **virtudes** (`strengths`) y **aspectos a mejorar** (`improvements`).
- Las devoluciones son **anónimas**: cada jugador puede ver el contenido de las devoluciones que recibió (virtudes y aspectos a mejorar), pero **nunca** puede saber quién las escribió. El objetivo es que cada jugador sepa en qué áreas trabajar según la visión del equipo.

---

## Destacado del partido (`mvp_votes`)

- Cada jugador vota **1 destacado** por partido (puede votarse a sí mismo).
- Al cierre se muestran **todos los más votados** en caso de empate.
- *(Futuro)* votación de desempate entre empatados.

---

## Jugada del partido (`play_of_match_votes`)

- **Opcional** para todos los jugadores participantes.
- Cada votante selecciona el **jugador protagonista** y escribe una **descripción libre** de la jugada.
- Puede votarse a uno mismo como protagonista.
- Al cierre: se muestra el protagonista más votado + **2-3 descripciones seleccionadas al azar** entre todas las cargadas.
- La selección de descripciones es aleatoria (no hay votación de descripciones).

---

## Aspectos del equipo (`team_feedback`)

- Cualquier jugador participante del partido puede cargar **aspectos positivos** y **aspectos a mejorar** del equipo como conjunto.
- Al cierre se muestran consolidados en una lista simple.

---

## Evaluación incompleta

- Si un jugador no completa su evaluación antes del cierre del partido, su `evaluation_status` en `match_players` queda como `incomplete`.
- El partido se cierra igualmente y el sistema funciona con ese voto/devolución menos.
- *(Futuro)* sistema de avisos y advertencias para jugadores con evaluaciones pendientes.

---

## Anonimato — Regla crítica

- **Nunca** se expone el `evaluator_id` ni el `giver_id` en consultas públicas o accesibles desde el cliente.
- El anonimato se garantiza **exclusivamente a nivel de base de datos** mediante RLS (Row Level Security) de Supabase. No confiar en el frontend para esta garantía.
- **Un jugador PUEDE ver:**
  - Su propio puntaje promedio recibido.
  - El contenido de las devoluciones que recibió (virtudes y aspectos a mejorar).
  - Los resultados consolidados del resumen del partido.
- **Un jugador NO PUEDE ver:**
  - Quién le asignó cada nota.
  - Quién escribió cada devolución.
