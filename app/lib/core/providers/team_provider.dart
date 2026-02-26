import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_client.dart';

/// Información de membresía del usuario actual en su equipo activo.
class CurrentMembership {
  final String teamId;
  final String memberId; // team_members.id
  final bool isAdmin;
  final bool isCoach;

  const CurrentMembership({
    required this.teamId,
    required this.memberId,
    required this.isAdmin,
    required this.isCoach,
  });
}

/// Obtiene la membresía activa del usuario actual (primer equipo activo).
final currentMembershipProvider =
    FutureProvider<CurrentMembership?>((ref) async {
  final userId = supabaseClient.auth.currentUser?.id;
  if (userId == null) return null;

  final result = await supabaseClient
      .from('team_members')
      .select('id, team_id, is_admin, is_coach')
      .eq('user_id', userId)
      .eq('is_active', true)
      .limit(1)
      .maybeSingle();

  if (result == null) return null;

  return CurrentMembership(
    teamId: result['team_id'] as String,
    memberId: result['id'] as String,
    isAdmin: result['is_admin'] as bool? ?? false,
    isCoach: result['is_coach'] as bool? ?? false,
  );
});
