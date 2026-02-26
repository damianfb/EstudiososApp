import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/team_provider.dart';
import '../../data/models/team_member_model.dart';
import '../../data/repositories/roster_repository.dart';

/// Lista de miembros del equipo actual.
final rosterProvider = FutureProvider<List<TeamMemberModel>>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) return [];
  return ref.read(rosterRepositoryProvider).fetchMembers(membership.teamId);
});

/// Detalle de un miembro específico por su ID (team_members.id).
/// Se obtiene de la lista ya cargada en [rosterProvider].
final memberDetailProvider =
    FutureProvider.family<TeamMemberModel?, String>((ref, memberId) async {
  final members = await ref.watch(rosterProvider.future);
  try {
    return members.firstWhere((m) => m.id == memberId);
  } catch (_) {
    return null;
  }
});
