# Supabase Edge Functions

Edge Functions del proyecto EstudiososApp, escritas en TypeScript y ejecutadas en el runtime de Deno de Supabase.

---

## `assign-feedback`

Genera las filas en `feedback_assignments` al pasar un partido a estado `evaluating`.

### Algoritmo de asignación

| Rol | Devoluciones asignadas |
|-----|------------------------|
| Jugador normal | 3 al azar |
| Capitán del partido | 6 al azar |
| DT | No asignado por el sistema (puede dar devolución a todos opcionalmente) |

- Ningún jugador se asigna a sí mismo.
- No se generan pares duplicados `(match_id, giver_id, receiver_id)`.
- Se garantiza que **cada jugador recibe mínimo 2 devoluciones**; si no se cumple con las asignaciones iniciales, el algoritmo redistribuye automáticamente.
- El mapeo giver→receiver nunca se expone fuera de la función (anonimato garantizado por RLS).

### Invocación desde Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> assignFeedback(String matchId) async {
  final response = await supabase.functions.invoke(
    'assign-feedback',
    body: {'match_id': matchId},
  );

  if (response.status != 200) {
    throw Exception('Error al asignar devoluciones: ${response.data}');
  }
}
```

> El JWT del usuario autenticado se adjunta automáticamente por el cliente de Supabase Flutter.
> La función verifica que el partido esté en estado `played` antes de proceder.

### Invocación directa (HTTP)

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/assign-feedback \
  -H "Authorization: Bearer <jwt>" \
  -H "Content-Type: application/json" \
  -d '{"match_id": "<uuid>"}'
```

### Respuesta exitosa

```json
{
  "success": true,
  "assignments_count": 36
}
```

---

## `close-match`

Cierra un partido cambiando su `status` a `closed` y dispara internamente `generate-summary`.

### Condiciones de cierre

El partido debe estar en estado `evaluating`. Se requiere que **al menos una** de las siguientes condiciones se cumpla:

| Condición | Descripción |
|-----------|-------------|
| (a) Todos completaron | Todos los `match_players` tienen `evaluation_status = 'completed'` |
| (b) Deadline vencido | `evaluation_deadline` es anterior a la fecha/hora actual |
| (c) Cierre manual | El Admin envía `"force": true` en el body |

- Si el cierre ocurre por (b) o (c) con evaluaciones pendientes, los jugadores con `evaluation_status = 'pending'` pasan automáticamente a `incomplete`.
- El partido se cierra igualmente y el sistema genera el resumen con los datos disponibles.

### Parámetros (body JSON)

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `match_id` | `string` (UUID) | ✅ | ID del partido a cerrar |
| `force` | `boolean` | ❌ | Si `true`, fuerza el cierre manual (condición c) aunque no se cumpla (a) ni (b) |

### Autorización

- **Admin del equipo:** invocación con JWT de un usuario que tenga `is_admin = true` en `team_members` para el equipo del partido.
- **Sistema:** invocación con `SUPABASE_SERVICE_ROLE_KEY` (scheduler, evento automático u otra Edge Function).

### Invocación desde Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Cierre manual por Admin
Future<void> closeMatch(String matchId, {bool force = false}) async {
  final response = await supabase.functions.invoke(
    'close-match',
    body: {'match_id': matchId, if (force) 'force': true},
  );

  if (response.status != 200) {
    throw Exception('Error al cerrar el partido: ${response.data}');
  }
}
```

> El JWT del usuario autenticado se adjunta automáticamente por el cliente de Supabase Flutter.

### Invocación directa (HTTP)

```bash
# Cierre automático (vence deadline o todos completaron)
curl -X POST https://<project-ref>.supabase.co/functions/v1/close-match \
  -H "Authorization: Bearer <admin-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"match_id": "<uuid>"}'

# Cierre manual forzado por Admin
curl -X POST https://<project-ref>.supabase.co/functions/v1/close-match \
  -H "Authorization: Bearer <admin-jwt>" \
  -H "Content-Type: application/json" \
  -d '{"match_id": "<uuid>", "force": true}'

# Invocación por sistema (scheduler)
curl -X POST https://<project-ref>.supabase.co/functions/v1/close-match \
  -H "Authorization: Bearer <service-role-key>" \
  -H "apikey: <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{"match_id": "<uuid>"}'
```

### Respuesta exitosa

```json
{
  "success": true,
  "close_reason": "all_completed"
}
```

El campo `close_reason` puede tomar los valores:

| Valor | Descripción |
|-------|-------------|
| `"all_completed"` | Todos los jugadores completaron su evaluación |
| `"deadline_expired"` | Venció el tiempo límite de evaluación |
| `"manual"` | Cierre forzado por Admin (`force: true`) |

### Respuesta con advertencia

Si el partido se cerró correctamente pero `generate-summary` falló, la respuesta incluye el campo `warning`:

```json
{
  "success": true,
  "close_reason": "deadline_expired",
  "warning": "Match closed but generate-summary failed: ..."
}
```

> En este caso el partido quedó cerrado. El resumen puede regenerarse manualmente invocando `generate-summary` por separado.

### Errores

| Status | Descripción |
|--------|-------------|
| 400 | `match_id` faltante o partido no está en estado `evaluating` |
| 401 | JWT inválido o ausente |
| 403 | El usuario no es Admin del equipo |
| 404 | Partido no encontrado |
| 422 | Ninguna condición de cierre se cumple y `force` no es `true` |
| 500 | Error interno |

---

## `generate-summary`

Calcula y persiste el resumen del partido en `match_summary`.

### Lógica

1. Calcula el/los MVP(s): jugador(es) con más votos en `mvp_votes` (incluye empates).
2. Calcula el protagonista de la jugada: jugador con más votos en `play_of_match_votes`.
3. Selecciona 2-3 descripciones al azar **sólo** de los votos al protagonista ganador.
4. Inserta o actualiza el registro en `match_summary`.

> **Anonimato:** `voter_id` y el autor de cada descripción **nunca** se consultan ni se exponen. Solo se leen `voted_for_id`, `protagonist_id` y `description`.

### Parámetros (body JSON)

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `match_id` | `string` (UUID) | ✅ | ID del partido cuyo resumen se genera |

### Autorización

- **Sistema:** invocación con `SUPABASE_SERVICE_ROLE_KEY` (llamada interna desde `close-match`).
- El partido debe estar en estado `closed`.

### Invocación desde Flutter

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> generateSummary(String matchId) async {
  final response = await supabase.functions.invoke(
    'generate-summary',
    body: {'match_id': matchId},
  );

  if (response.status != 200) {
    throw Exception('Error al generar el resumen: ${response.data}');
  }
}
```

### Invocación directa (HTTP)

```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/generate-summary \
  -H "Authorization: Bearer <service-role-key>" \
  -H "apikey: <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{"match_id": "<uuid>"}'
```

### Respuesta exitosa

```json
{
  "success": true
}
```

### Errores

| Status | Descripción |
|--------|-------------|
| 400 | `match_id` faltante o partido no está en estado `closed` |
| 404 | Partido no encontrado |
| 500 | Error interno |
