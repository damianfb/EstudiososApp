import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/supabase/supabase_client.dart';
import '../models/team_model.dart';

/// Repositorio para la configuración del equipo.
class SettingsRepository {
  const SettingsRepository();

  /// Obtiene los datos del equipo.
  Future<TeamModel> fetchTeam(String teamId) async {
    final result = await supabaseClient
        .from('teams')
        .select()
        .eq('id', teamId)
        .single();
    return TeamModel.fromJson(result);
  }

  /// Actualiza los datos básicos del equipo.
  Future<void> updateTeam(
    String teamId, {
    required String name,
    String? shieldUrl,
  }) async {
    final updates = <String, dynamic>{'name': name.trim()};
    if (shieldUrl != null) updates['shield_url'] = shieldUrl;

    await supabaseClient.from('teams').update(updates).eq('id', teamId);
  }

  /// Obtiene la liga más reciente asociada al equipo, o null si no existe.
  Future<Map<String, dynamic>?> fetchLeague(String teamId) async {
    return await supabaseClient
        .from('leagues')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Crea o actualiza la liga del equipo.
  Future<void> upsertLeague(
    String teamId, {
    required String name,
    String? season,
    String? leagueId,
  }) async {
    if (leagueId != null) {
      await supabaseClient.from('leagues').update({
        'name': name.trim(),
        'season': season?.trim(),
      }).eq('id', leagueId);
    } else {
      await supabaseClient.from('leagues').insert({
        'team_id': teamId,
        'name': name.trim(),
        'season': season?.trim(),
      });
    }
  }
}

/// Proveedor del repositorio de configuración.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return const SettingsRepository();
});
