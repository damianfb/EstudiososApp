import 'package:supabase_flutter/supabase_flutter.dart';

/// Acceso al cliente Supabase singleton.
///
/// Usar `supabaseClient` en repositorios y providers para interactuar
/// con la base de datos, auth, storage y realtime de Supabase.
///
/// Inicializado en `main.dart` mediante `Supabase.initialize(...)`.
SupabaseClient get supabaseClient => Supabase.instance.client;
