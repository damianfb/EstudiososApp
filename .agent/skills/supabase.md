# Convenciones Supabase

## Base de datos
PostgreSQL con todas las tablas definidas en `context/data-model.md`.

## Autenticación
Supabase Auth con email/password. El `auth.uid()` mapea directamente a `users.id`.

## Storage
Para avatares de usuarios (`avatar_url` en `users`) y escudos de equipos (`shield_url` en `teams`).

## RLS (Row Level Security)
- **Obligatorio** en todas las tablas.
- El anonimato de evaluaciones y devoluciones se garantiza **solo mediante RLS**, nunca confiar en el frontend.
- `evaluator_id` y `giver_id` **nunca** deben ser accesibles desde consultas del cliente.

## Realtime
Para notificar a jugadores cuando un partido pasa a `evaluating` o `closed`.

---

## Edge Functions

Las tres funciones críticas del MVP (TypeScript, en `/supabase/functions/`):

### `assign-feedback`
Genera `feedback_assignments` al pasar el partido a `evaluating`.

**Algoritmo:**
1. Obtener todos los jugadores participantes del partido (`match_players`).
2. Identificar al capitán (campo `captain_id` en `matches`).
3. Asignar aleatoriamente:
   - Jugador normal → 3 receptores asignados.
   - Capitán → 6 receptores asignados.
4. Garantizar que **cada jugador recibe mínimo 2 devoluciones**.
5. Insertar las filas en `feedback_assignments`.

### `close-match`
Cierra el partido cambiando `status` a `closed` y dispara `generate-summary`.

**Disparadores:**
- Llamada manual por el Admin.
- Trigger automático cuando vence `evaluation_deadline`.
- Trigger automático cuando todos los jugadores tienen `evaluation_status = completed`.

### `generate-summary`
Calcula y persiste el resumen del partido en `match_summary`.

**Lógica:**
1. Calcular el MVP: jugador(es) con más votos en `mvp_votes` (puede haber empate).
2. Calcular el protagonista de la jugada: jugador con más votos en `play_of_match_votes`.
3. Seleccionar 2-3 descripciones al azar de `play_of_match_votes`.
4. Insertar registro en `match_summary`.

---

## Migraciones
- Ubicación: `/supabase/migrations/`
- Formato de nombre: `YYYYMMDDHHMMSS_description.sql`
- Ejemplo: `20250101120000_create_teams_table.sql`

---

## Convenciones SQL

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Nombres de tablas | `snake_case` plural | `team_members`, `match_players` |
| Primary keys | UUID con `gen_random_uuid()` | `id UUID DEFAULT gen_random_uuid() PRIMARY KEY` |
| Timestamps | Con timezone (`TIMESTAMPTZ`) | `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` |
| Enums | Tipo ENUM de PostgreSQL o `TEXT` con CHECK constraint | `status TEXT CHECK (status IN ('pending', 'played', 'evaluating', 'closed'))` |
| Foreign keys | `tabla_id` | `team_id UUID REFERENCES teams(id)` |

---

## Ejemplo de políticas RLS

```sql
-- Los jugadores solo pueden ver sus propias devoluciones recibidas
-- (sin exponer giver_id)
CREATE POLICY "Players can view received feedback"
ON feedback_assignments
FOR SELECT
USING (
  receiver_id IN (
    SELECT id FROM team_members WHERE user_id = auth.uid()
  )
);

-- Solo el giver puede ver sus propias asignaciones completas
CREATE POLICY "Givers can view and update their assignments"
ON feedback_assignments
FOR ALL
USING (
  giver_id IN (
    SELECT id FROM team_members WHERE user_id = auth.uid()
  )
);
```

---

## Ejemplo de prompt

### Tarea: Crear la Edge Function `assign-feedback`

```
Contexto:
EstudiososApp usa Supabase Edge Functions (TypeScript) para lógica de negocio compleja.

Tarea: Implementar la Edge Function `assign-feedback` en /supabase/functions/assign-feedback/index.ts

Recibe: { match_id: string }

Lógica requerida:
1. Obtener los participantes del partido desde match_players (con su team_member_id).
2. Obtener el captain_id del partido desde matches.
3. Para cada jugador:
   - Si es capitán: asignar 6 receptores al azar (sin repetir, sin asignarse a sí mismo).
   - Si es jugador normal: asignar 3 receptores al azar.
4. Verificar que cada jugador recibe mínimo 2 devoluciones. Si alguno recibe menos, redistribuir.
5. Insertar las filas en feedback_assignments (match_id, giver_id, receiver_id).
6. Actualizar el status del partido a 'evaluating'.

Modelo de datos relevante:
- matches: (id, captain_id, status, evaluation_time_limit_hours)
- match_players: (id, match_id, team_member_id, evaluation_status)
- feedback_assignments: (id, match_id, giver_id, receiver_id, strengths, improvements, is_completed)

Restricciones:
- Un jugador no puede ser asignado a darse devolución a sí mismo.
- No puede haber duplicados (match_id, giver_id, receiver_id) únicos.
- El algoritmo debe garantizar el mínimo de 2 devoluciones recibidas por jugador.
```
