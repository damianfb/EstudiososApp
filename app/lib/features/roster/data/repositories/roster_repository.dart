import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/team_member_model.dart';

/// Repositorio para operaciones del plantel del equipo.
class RosterRepository {
  const RosterRepository();

  /// Obtiene todos los miembros del equipo ordenados: activos primero,
  /// luego admins primero dentro de cada grupo.
  Future<List<TeamMemberModel>> fetchMembers(String teamId) async {
    final result = await supabaseClient
        .from('team_members')
        .select(
          'id, user_id, is_admin, is_coach, jersey_number, position, is_active, users(name, avatar_url)',
        )
        .eq('team_id', teamId)
        .order('is_active', ascending: false)
        .order('is_admin', ascending: false);

    return (result as List)
        .map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Actualiza los campos de un miembro del equipo.
  Future<void> updateMember(
    String memberId, {
    bool? isAdmin,
    bool? isCoach,
    String? position,
    int? jerseyNumber,
  }) async {
    final updates = <String, dynamic>{};
    if (isAdmin != null) updates['is_admin'] = isAdmin;
    if (isCoach != null) updates['is_coach'] = isCoach;
    if (position != null) updates['position'] = position;
    if (jerseyNumber != null) updates['jersey_number'] = jerseyNumber;
    if (updates.isEmpty) return;

    await supabaseClient
        .from('team_members')
        .update(updates)
        .eq('id', memberId);
  }

  /// Da de baja (baja lógica) a un miembro del equipo.
  Future<void> deactivateMember(String memberId) async {
    await supabaseClient
        .from('team_members')
        .update({'is_active': false}).eq('id', memberId);
  }

  /// Reactiva a un miembro del equipo.
  Future<void> reactivateMember(String memberId) async {
    await supabaseClient
        .from('team_members')
        .update({'is_active': true}).eq('id', memberId);
  }
}

/// Proveedor del repositorio del plantel.
final rosterRepositoryProvider = Provider<RosterRepository>((ref) {
  return const RosterRepository();
});
