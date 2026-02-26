# Convenciones Flutter

## Lenguaje
Dart

## Arquitectura
Feature-first con separación en capas (presentation, domain, data).

## Gestión de estado
Riverpod (recomendado para integración con Supabase).

## Navegación
GoRouter.

## Cliente Supabase
Paquete oficial `supabase_flutter`.

---

## Estructura de carpetas

```
lib/
├── main.dart
├── app/
│   ├── router.dart              ← Configuración de GoRouter
│   └── theme.dart               ← Tema global de la app
├── core/
│   ├── supabase/                ← Inicialización y cliente Supabase
│   ├── providers/               ← Providers globales (auth, etc.)
│   └── widgets/                 ← Widgets reutilizables
└── features/
    └── [feature_name]/
        ├── data/
        │   ├── repositories/    ← Implementaciones de repositorios
        │   └── models/          ← Modelos de datos (fromJson/toJson)
        ├── domain/
        │   └── entities/        ← Entidades del dominio
        └── presentation/
            ├── screens/         ← Pantallas (Widgets de página completa)
            ├── widgets/         ← Widgets específicos de la feature
            └── providers/       ← Providers de Riverpod de la feature
```

## Features del MVP
| Feature | Descripción |
|---------|-------------|
| `auth` | Login, registro, crear equipo, unirse con código |
| `home` | Dashboard del equipo |
| `matches` | Lista de partidos, crear partido, detalle del partido |
| `evaluation` | Flujo de 5 pasos post-partido |
| `summary` | Resumen del partido cerrado |
| `profile` | Estadísticas personales del jugador |
| `roster` | Plantel con stats (visible para Admin/DT) |
| `settings` | Configuración del equipo (solo Admin) |

---

## Convenciones de nombres

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Archivos | `snake_case.dart` | `match_detail_screen.dart` |
| Clases | `PascalCase` | `MatchDetailScreen` |
| Variables y métodos | `camelCase` | `matchId`, `fetchMatches()` |
| Constantes con `k` | `kCamelCase` | `kPrimaryColor` |
| Constantes globales | `UPPER_SNAKE_CASE` | `MAX_RATING_VALUE` |

---

## Pantallas del MVP

### Auth
- `LoginScreen` — Formulario de login con email/password
- `RegisterScreen` — Formulario de registro
- `CreateTeamScreen` — Crear un nuevo equipo
- `JoinTeamScreen` — Unirse a un equipo con código de invitación

### Home
- `HomeScreen` — Dashboard: resumen del equipo, próximos partidos, acciones rápidas

### Matches
- `MatchListScreen` — Lista de partidos del equipo con estados
- `CreateMatchScreen` — Formulario para crear nuevo partido (Admin)
- `MatchDetailScreen` — Detalle del partido: resultado, estado, participantes

### Evaluation
- `EvaluationFlowScreen` — Stepper de 5 pasos:
  1. Puntuar a cada jugador (1-10)
  2. Completar devoluciones asignadas (virtudes + aspectos a mejorar)
  3. Votar al MVP
  4. Jugada del partido (opcional)
  5. Aspectos del equipo (opcional)

### Summary
- `MatchSummaryScreen` — Resumen consolidado del partido cerrado

### Profile
- `ProfileScreen` — Estadísticas personales: promedio de puntuación, devoluciones recibidas, historial

### Roster
- `RosterScreen` — Plantel del equipo con estadísticas (Admin/DT)

### Settings
- `TeamSettingsScreen` — Configuración del equipo: nombre, escudo, tiempo límite de evaluación (solo Admin)

---

## Ejemplo de prompt

### Tarea: Implementar la pantalla de lista de partidos

```
Contexto:
EstudiososApp usa Flutter con arquitectura feature-first, Riverpod para estado y GoRouter para navegación.

Feature: matches
Pantalla: MatchListScreen (features/matches/presentation/screens/match_list_screen.dart)

Requisitos:
- Mostrar lista de partidos del equipo actual ordenados por fecha descendente.
- Cada item debe mostrar: rival, fecha, resultado (si está disponible), estado del partido.
- Los estados posibles son: pending, played, evaluating, closed.
- Mostrar un chip de color diferente por estado.
- Al tocar un partido, navegar a MatchDetailScreen con el ID del partido.
- Mostrar FAB para crear partido (solo si el usuario es admin).
- Usar Riverpod para manejar el estado (loading, data, error).
- El repositorio obtiene los datos de Supabase filtrando por team_id del equipo actual.

Estructura esperada:
- features/matches/data/repositories/match_repository.dart
- features/matches/data/models/match_model.dart
- features/matches/presentation/screens/match_list_screen.dart
- features/matches/presentation/providers/matches_provider.dart
```
