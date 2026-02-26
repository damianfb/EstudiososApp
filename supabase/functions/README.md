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

## `close-match` *(pendiente)*

Cierra el partido cambiando `status` a `closed` y dispara `generate-summary`.

---

## `generate-summary` *(pendiente)*

Calcula y persiste el resumen del partido en `match_summary`.
