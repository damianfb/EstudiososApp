# EstudiososApp — Flutter

App mobile para gestión y progreso de equipos de fútbol amateur. Permite registrar partidos, evaluar jugadores de forma anónima, dar devoluciones entre compañeros y generar resúmenes del partido.

---

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Dart SDK](https://dart.dev/get-dart) `>=3.0.0`
- Una instancia de [Supabase](https://supabase.com/) configurada (ver `supabase/` en la raíz del repositorio)

---

## Cómo correr el proyecto

### 1. Instalar dependencias

```bash
cd app/
flutter pub get
```

### 2. Configurar variables de entorno

Las credenciales de Supabase se inyectan como `dart-define` en tiempo de compilación (no se usan archivos `.env` en el bundle de producción).

Para **desarrollo local**, crear un archivo `.env` en `app/` (ignorado por git):

```
SUPABASE_URL=https://<tu-proyecto>.supabase.co
SUPABASE_ANON_KEY=<tu-anon-key>
```

Y correr la app pasando las variables:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<tu-anon-key>
```

### 3. Generar código de Riverpod

Si se modifican providers anotados con `@riverpod`, regenerar el código:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Para modo watch (durante desarrollo activo):

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 4. Ejecutar tests

```bash
flutter test
```

### 5. Lint

```bash
flutter analyze
```

---

## Agregar dependencias

1. Editar `pubspec.yaml` y agregar el paquete en la sección correspondiente (`dependencies` o `dev_dependencies`), con un comentario que explique para qué se usa.
2. Correr `flutter pub get`.
3. Si la dependencia genera código (ej: anotaciones de Riverpod), correr el paso de `build_runner` mencionado arriba.

---

## Estructura del proyecto

```
app/
├── pubspec.yaml               ← Dependencias y configuración del proyecto
├── lib/
│   ├── main.dart              ← Punto de entrada: inicialización de Supabase y ProviderScope
│   ├── app/
│   │   ├── router.dart        ← Configuración de GoRouter (rutas)
│   │   └── theme.dart         ← Tema global de Material 3
│   ├── core/
│   │   ├── supabase/          ← Cliente Supabase singleton
│   │   ├── providers/         ← Providers globales (auth, equipo activo, etc.)
│   │   └── widgets/           ← Widgets reutilizables en toda la app
│   └── features/
│       ├── auth/              ← Login, registro, crear/unirse a equipo
│       ├── home/              ← Dashboard del equipo
│       ├── matches/           ← Lista, creación y detalle de partidos
│       ├── evaluation/        ← Flujo de evaluación post-partido (5 pasos)
│       ├── summary/           ← Resumen del partido cerrado
│       ├── profile/           ← Estadísticas personales del jugador
│       ├── roster/            ← Plantel con estadísticas (Admin/DT)
│       └── settings/          ← Configuración del equipo (solo Admin)
└── test/                      ← Tests unitarios y de widgets
```

Cada feature sigue la arquitectura **feature-first** con separación en capas:

```
features/<feature_name>/
├── data/
│   ├── repositories/    ← Implementaciones de repositorios (acceso a Supabase)
│   └── models/          ← Modelos de datos con fromJson/toJson
├── domain/
│   └── entities/        ← Entidades del dominio (lógica de negocio pura)
└── presentation/
    ├── screens/         ← Pantallas completas (rutas de GoRouter)
    ├── widgets/         ← Widgets específicos de la feature
    └── providers/       ← Providers de Riverpod para la feature
```

---

## Stack tecnológico

| Capa | Paquete |
|------|---------|
| Backend | `supabase_flutter` |
| Estado | `flutter_riverpod` + `riverpod_annotation` |
| Navegación | `go_router` |
| Lint | `flutter_lints` + `riverpod_lint` |
| Generación de código | `build_runner` + `riverpod_generator` |

---

## Convenciones

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Archivos | `snake_case.dart` | `match_detail_screen.dart` |
| Clases | `PascalCase` | `MatchDetailScreen` |
| Variables y métodos | `camelCase` | `matchId`, `fetchMatches()` |
| Constantes con prefijo `k` | `kCamelCase` | `kPrimaryColor` |
| Constantes globales | `UPPER_SNAKE_CASE` | `MAX_RATING_VALUE` |

Para más detalles sobre arquitectura y convenciones, consultar `.agent/skills/flutter.md` en la raíz del repositorio.
