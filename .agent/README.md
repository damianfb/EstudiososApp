# .agent/ — Documentación para agentes de IA

Este directorio contiene toda la documentación necesaria para que agentes de IA puedan asistir en el desarrollo de **EstudiososApp** con contexto completo del dominio, reglas de negocio, modelo de datos y convenciones técnicas.

---

## Estructura de archivos

```
.agent/
├── README.md                     ← Este archivo. Índice y guía de uso.
├── context/
│   ├── project-overview.md       ← Visión general del proyecto, stack y roles
│   ├── domain-rules.md           ← Reglas de negocio del sistema
│   ├── data-model.md             ← Modelo de datos completo (tablas y relaciones)
│   └── glossary.md               ← Glosario de términos del dominio
└── skills/
    ├── flutter.md                ← Convenciones y guías para desarrollo Flutter
    ├── supabase.md               ← Convenciones y guías para Supabase
    └── testing.md                ← Estrategia de testing
```

### ¿Qué contiene cada archivo?

| Archivo | Propósito |
|---------|-----------|
| `context/project-overview.md` | Stack tecnológico, roles de usuario, alcance del MVP y roadmap |
| `context/domain-rules.md` | Todas las reglas de negocio: estados de partidos, puntuaciones, devoluciones, anonimato |
| `context/data-model.md` | Esquema completo de tablas, campos, tipos y relaciones |
| `context/glossary.md` | Definiciones precisas de cada término del dominio (en español e inglés) |
| `skills/flutter.md` | Arquitectura, estructura de carpetas, convenciones de nombres y pantallas del MVP |
| `skills/supabase.md` | Auth, RLS, Edge Functions, Storage, Realtime y convenciones SQL |
| `skills/testing.md` | Estrategia de tests, casos críticos y prioridades del MVP |

---

## Cómo estructurar un prompt usando estos docs

Para obtener mejores resultados, incluí en tu prompt:

1. **Contexto del dominio** — referenciá `context/project-overview.md` y `context/domain-rules.md` para dar marco al agente.
2. **Modelo de datos** — referenciá `context/data-model.md` cuando la tarea involucre base de datos.
3. **Skill relevante** — referenciá el archivo de skill correspondiente a la capa que vas a trabajar (`flutter.md`, `supabase.md`, `testing.md`).
4. **Tarea concreta** — describí la tarea específica con el contexto anterior como base.

### Plantilla de prompt recomendada

```
Contexto del proyecto:
[Pegar contenido de context/project-overview.md]

Reglas de negocio relevantes:
[Pegar sección relevante de context/domain-rules.md]

Modelo de datos:
[Pegar tablas relevantes de context/data-model.md]

Convenciones técnicas:
[Pegar contenido de skills/flutter.md o skills/supabase.md]

Tarea:
[Descripción concreta de lo que querés implementar]
```

---

## Ejemplo de prompt para pedir una tarea concreta

### Ejemplo: Implementar la pantalla de evaluación post-partido

```
Contexto del proyecto:
EstudiososApp es una app mobile (Flutter + Supabase) para gestión y progreso de equipos de fútbol amateur.
Stack: Flutter (Dart) + Supabase. Arquitectura feature-first con Riverpod y GoRouter.

Reglas de negocio:
- Cada jugador puntúa a todos los participantes del partido (escala 1-10), incluido a sí mismo.
- Cada jugador tiene asignadas 3 devoluciones (o 6 si es capitán) generadas automáticamente por el sistema.
- Cada jugador vota 1 MVP (puede votarse a sí mismo).
- La jugada del partido es opcional.
- Los aspectos del equipo son opcionales.
- Todo esto ocurre mientras el partido está en estado EVALUATING.

Modelo de datos relevante:
- evaluations: (id, match_id, evaluator_id, status, submitted_at)
- player_ratings: (id, evaluation_id, rated_team_member_id, score)
- feedback_assignments: (id, match_id, giver_id, receiver_id, strengths, improvements, is_completed)
- mvp_votes: (id, match_id, voter_id, voted_for_id)

Convenciones Flutter:
- Arquitectura feature-first: features/evaluation/data|domain|presentation
- Estado con Riverpod
- Navegación con GoRouter
- Archivos en snake_case, clases en PascalCase

Tarea:
Implementar el flujo de evaluación post-partido como una pantalla de 5 pasos (stepper):
1. Puntuar a cada jugador (1-10)
2. Completar devoluciones asignadas (virtudes + aspectos a mejorar)
3. Votar al MVP
4. Jugada del partido (opcional)
5. Aspectos del equipo (opcional)
Al finalizar, actualizar el estado de la evaluación a 'completed' en Supabase.
```
