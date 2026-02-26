import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/team_provider.dart';
import '../../data/models/team_model.dart';
import '../../data/repositories/settings_repository.dart';

/// Estado combinado del equipo: datos del equipo + liga asociada.
class TeamSettingsState {
  final TeamModel team;
  final Map<String, dynamic>? league;

  const TeamSettingsState({required this.team, this.league});
}

/// Proveedor de configuración del equipo activo del usuario actual.
final teamSettingsProvider =
    FutureProvider<TeamSettingsState>((ref) async {
  final membership = await ref.watch(currentMembershipProvider.future);
  if (membership == null) throw Exception('No hay equipo activo.');

  final repo = ref.read(settingsRepositoryProvider);
  final team = await repo.fetchTeam(membership.teamId);
  final league = await repo.fetchLeague(membership.teamId);

  return TeamSettingsState(team: team, league: league);
});
