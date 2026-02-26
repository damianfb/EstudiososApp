import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

/// Emite eventos de cambio de estado de autenticación de Supabase.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return supabaseClient.auth.onAuthStateChange;
});

/// Usuario autenticado actualmente. Null si no hay sesión activa.
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateChangesProvider);
  return supabaseClient.auth.currentUser;
});
