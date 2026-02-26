import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Repositorio para operaciones de autenticación y gestión de equipos.
class AuthRepository {
  const AuthRepository();

  /// Inicia sesión con email y contraseña.
  Future<void> signIn(String email, String password) async {
    await supabaseClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registra un nuevo usuario y crea su perfil en la tabla `users`.
  Future<void> signUp(String name, String email, String password) async {
    final response = await supabaseClient.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('No se pudo crear el usuario.');
    }

    // Crear perfil en la tabla pública de usuarios (upsert por si hay trigger)
    await supabaseClient.from('users').upsert({
      'id': user.id,
      'name': name.trim(),
      'email': email.trim(),
    });
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  /// Crea un nuevo equipo con el usuario actual como administrador.
  Future<void> createTeam(String teamName) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    final inviteCode = _generateInviteCode();

    final teamResult = await supabaseClient
        .from('teams')
        .insert({
          'name': teamName.trim(),
          'invite_code': inviteCode,
        })
        .select()
        .single();

    await supabaseClient.from('team_members').insert({
      'team_id': teamResult['id'] as String,
      'user_id': userId,
      'is_admin': true,
    });
  }

  /// Une al usuario actual a un equipo mediante el código de invitación.
  Future<void> joinTeam(String inviteCode) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    final teamResult = await supabaseClient
        .from('teams')
        .select('id')
        .eq('invite_code', inviteCode.trim().toUpperCase())
        .maybeSingle();

    if (teamResult == null) {
      throw Exception('Código de invitación inválido.');
    }

    await supabaseClient.from('team_members').insert({
      'team_id': teamResult['id'] as String,
      'user_id': userId,
    });
  }

  /// Devuelve true si el usuario actual pertenece a al menos un equipo activo.
  Future<bool> hasTeam() async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await supabaseClient
        .from('team_members')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);

    return result.isNotEmpty;
  }

  /// Genera un código de invitación aleatorio de 8 caracteres (letras y números).
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}

/// Proveedor del repositorio de autenticación.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});
