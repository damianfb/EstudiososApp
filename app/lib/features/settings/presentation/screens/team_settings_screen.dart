import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/team_provider.dart';
import '../../data/repositories/settings_repository.dart';
import '../providers/settings_provider.dart';

/// Pantalla de configuración del equipo (solo para administradores).
/// Permite editar nombre, URL del escudo, y datos de la liga.
/// También muestra el código de invitación para compartir.
class TeamSettingsScreen extends ConsumerStatefulWidget {
  const TeamSettingsScreen({super.key});

  @override
  ConsumerState<TeamSettingsScreen> createState() =>
      _TeamSettingsScreenState();
}

class _TeamSettingsScreenState extends ConsumerState<TeamSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shieldUrlController;
  late final TextEditingController _leagueNameController;
  late final TextEditingController _leagueSeasonController;
  bool _initialized = false;
  bool _isSaving = false;
  String? _currentLeagueId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _shieldUrlController = TextEditingController();
    _leagueNameController = TextEditingController();
    _leagueSeasonController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shieldUrlController.dispose();
    _leagueNameController.dispose();
    _leagueSeasonController.dispose();
    super.dispose();
  }

  void _initControllers(TeamSettingsState settings) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = settings.team.name;
    _shieldUrlController.text = settings.team.shieldUrl ?? '';
    _leagueNameController.text = settings.league?['name'] as String? ?? '';
    _leagueSeasonController.text =
        settings.league?['season'] as String? ?? '';
    _currentLeagueId = settings.league?['id'] as String?;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final membership =
          await ref.read(currentMembershipProvider.future);
      if (membership == null) throw Exception('No hay equipo activo.');

      final repo = ref.read(settingsRepositoryProvider);
      final shieldText = _shieldUrlController.text.trim();

      await repo.updateTeam(
        membership.teamId,
        name: _nameController.text,
        shieldUrl: shieldText.isEmpty ? null : shieldText,
      );

      final leagueName = _leagueNameController.text.trim();
      if (leagueName.isNotEmpty) {
        final seasonText = _leagueSeasonController.text.trim();
        await repo.upsertLeague(
          membership.teamId,
          name: leagueName,
          season: seasonText.isEmpty ? null : seasonText,
          leagueId: _currentLeagueId,
        );
      }

      // Reinvalidate so the app reflects the new team name/data.
      ref.invalidate(teamSettingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados correctamente.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(teamSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del equipo')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          _initControllers(settings);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Invite code card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Código de invitación',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  settings.team.inviteCode,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        letterSpacing: 4,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copiar código',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: settings.team.inviteCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Código de invitación copiado.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Compartí este código con tus compañeros para que se unan al equipo.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Datos del equipo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del equipo',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Ingresá el nombre del equipo';
                      }
                      if (v.trim().length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _shieldUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL del escudo (opcional)',
                      hintText: 'https://...',
                    ),
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Liga (opcional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _leagueNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la liga',
                      hintText: 'Ej: Liga Municipal',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _leagueSeasonController,
                    decoration: const InputDecoration(
                      labelText: 'Temporada',
                      hintText: 'Ej: Apertura 2025',
                    ),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
