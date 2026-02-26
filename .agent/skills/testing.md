# Estrategia de Testing

## Tipos de tests

### Unit tests
Lógica de negocio pura, sin dependencias externas.
- Algoritmo de asignación de devoluciones (`assign-feedback`).
- Cálculo de promedios de puntuación.
- Lógica de transición de estados del partido.

### Widget tests
Componentes críticos del flujo de evaluación.
- Stepper de evaluación (`EvaluationFlowScreen`).
- Pantalla de resumen del partido (`MatchSummaryScreen`).

### Integration tests
Flujo completo de evaluación post-partido.
- Desde que el partido pasa a `EVALUATING` hasta el `CLOSED`.
- Verificación de que los resultados son correctos en `match_summary`.

---

## Prioridades del MVP

**Alta prioridad — testear exhaustivamente:**

1. **Algoritmo `assign-feedback`** — Es la lógica más compleja y crítica del sistema.
2. **Anonimato (RLS)** — Verificar que las políticas de RLS impiden acceso no autorizado.
3. **Transiciones de estado del partido** — Garantizar que el ciclo de vida es correcto.

---

## Casos críticos a testear

### Algoritmo `assign-feedback`
- [ ] Equipo de 11 jugadores: verificar distribución correcta (3 asignaciones por jugador normal).
- [ ] Equipo con capitán: verificar que el capitán recibe 6 asignaciones.
- [ ] Garantía de mínimo 2 devoluciones recibidas por jugador en todos los casos.
- [ ] No se generan asignaciones duplicadas `(match_id, giver_id, receiver_id)`.
- [ ] Ningún jugador se asigna devolución a sí mismo.
- [ ] Equipo mínimo (ej: 5 jugadores): verificar que el algoritmo sigue siendo válido.

### Estados del partido
- [ ] Cierre automático por tiempo límite (`evaluation_deadline` vencido).
- [ ] Cierre automático cuando todos los jugadores completan su evaluación.
- [ ] Cierre manual por el Admin.
- [ ] El `match_summary` se genera correctamente en todos los casos de cierre.

### Anonimato (RLS)
- [ ] Un jugador no puede acceder a `evaluator_id` de `evaluations` que no le pertenecen.
- [ ] Un jugador no puede acceder a `giver_id` de `feedback_assignments` recibidas.
- [ ] Un jugador puede ver el contenido de sus devoluciones recibidas (virtudes y mejoras).
- [ ] Un jugador puede ver su propio puntaje promedio.

### Evaluación incompleta
- [ ] El partido se cierra aunque haya jugadores con `evaluation_status = incomplete`.
- [ ] El `match_summary` se genera correctamente con votos/devoluciones faltantes.

### MVP y jugada del partido
- [ ] Empate en MVP: se muestran todos los más votados.
- [ ] Selección aleatoria de 2-3 descripciones de jugada del partido.
- [ ] Partido sin votos de jugada: `play_protagonist_id` es NULL en `match_summary`.

---

## Edge Functions — Tests unitarios (TypeScript)

Cada Edge Function debe tener su suite de tests:

```
supabase/functions/
├── assign-feedback/
│   ├── index.ts
│   └── index.test.ts
├── close-match/
│   ├── index.ts
│   └── index.test.ts
└── generate-summary/
    ├── index.ts
    └── index.test.ts
```

---

## Ejemplo de prompt

### Tarea: Escribir tests unitarios para el algoritmo `assign-feedback`

```
Contexto:
EstudiososApp usa TypeScript para Edge Functions en Supabase.
El algoritmo assign-feedback genera feedback_assignments al pasar un partido a EVALUATING.

Reglas del algoritmo:
- Jugador normal: 3 asignaciones al azar.
- Capitán: 6 asignaciones al azar.
- Cada jugador debe recibir mínimo 2 devoluciones.
- Ningún jugador se asigna a sí mismo.
- No hay duplicados (match_id, giver_id, receiver_id).

Tarea:
Escribir tests unitarios en TypeScript (usando Deno test runner) para el algoritmo de asignación.

Casos a cubrir:
1. Equipo de 11 jugadores sin capitán especial → 3 asignaciones por jugador.
2. Equipo de 11 jugadores con capitán → capitán con 6, resto con 3.
3. Verificar que cada jugador recibe mínimo 2 devoluciones.
4. Verificar que no hay autoasignaciones.
5. Verificar que no hay duplicados.
6. Equipo pequeño (5 jugadores) → algoritmo sigue siendo válido.

Archivo: supabase/functions/assign-feedback/index.test.ts
```
