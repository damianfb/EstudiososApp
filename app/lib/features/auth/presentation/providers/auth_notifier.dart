import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';

/// Notifier para operaciones de autenticación.
///
/// El estado es `AsyncValue<void>`: loading mientras opera,
/// error si falla, data(null) cuando está inactivo o tuvo éxito.
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._repository) : super(const AsyncValue.data(null));

  final AuthRepository _repository;

  /// Inicia sesión. Devuelve true si fue exitoso.
  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.signIn(email, password),
    );
    state = result;
    return result is AsyncData;
  }

  /// Registra un nuevo usuario. Devuelve true si fue exitoso.
  Future<bool> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.signUp(name, email, password),
    );
    state = result;
    return result is AsyncData;
  }

  /// Crea un nuevo equipo. Devuelve true si fue exitoso.
  Future<bool> createTeam(String teamName) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.createTeam(teamName),
    );
    state = result;
    return result is AsyncData;
  }

  /// Une al usuario a un equipo por código de invitación. Devuelve true si fue exitoso.
  Future<bool> joinTeam(String inviteCode) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => _repository.joinTeam(inviteCode),
    );
    state = result;
    return result is AsyncData;
  }

  /// Cierra sesión.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.signOut);
  }

  /// Limpia el estado de error.
  void clearError() {
    if (state is AsyncError) {
      state = const AsyncValue.data(null);
    }
  }
}

/// Proveedor del AuthNotifier.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
