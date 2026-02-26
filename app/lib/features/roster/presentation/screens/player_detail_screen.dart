import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/team_provider.dart';
import '../../data/models/team_member_model.dart';
import '../../data/repositories/roster_repository.dart';
import '../providers/roster_provider.dart';

/// Pantalla de detalle de un jugador del plantel.
/// Muestra nombre, avatar, posición, número y roles.
/// Los administradores pueden editar datos, asignar roles y dar de baja.
class PlayerDetailScreen extends ConsumerStatefulWidget {
  final String memberId;

  const PlayerDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<PlayerDetailScreen> createState() =>
      _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends ConsumerState<PlayerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _positionController;
  late TextEditingController _jerseyController;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _positionController = TextEditingController();
    _jerseyController = TextEditingController();
  }

  @override
  void dispose() {
    _positionController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  void _loadControllers(TeamMemberModel member) {
    if (!_isEditing) {
      _positionController.text = member.position ?? '';
      _jerseyController.text = member.jerseyNumber?.toString() ?? '';
    }
  }

  Future<void> _saveEdits(TeamMemberModel member) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final jerseyText = _jerseyController.text.trim();
      final positionText = _positionController.text.trim();
      await ref.read(rosterRepositoryProvider).updateMember(
            member.id,
            position: positionText.isEmpty ? null : positionText,
            jerseyNumber:
                jerseyText.isEmpty ? null : int.tryParse(jerseyText),
          );

      ref.invalidate(rosterProvider);
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente.')),
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

  Future<void> _toggleRole(
      TeamMemberModel member, String role, bool value) async {
    try {
      await ref.read(rosterRepositoryProvider).updateMember(
            member.id,
            isAdmin: role == 'admin' ? value : null,
            isCoach: role == 'coach' ? value : null,
          );
      ref.invalidate(rosterProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _toggleActive(TeamMemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          member.isActive
              ? 'Dar de baja a ${member.name}'
              : 'Reactivar a ${member.name}',
        ),
        content: Text(
          member.isActive
              ? '¿Confirmás que querés dar de baja a ${member.name}? Podrás reactivarlo más tarde.'
              : '¿Querés reactivar a ${member.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              member.isActive ? 'Dar de baja' : 'Reactivar',
              style: TextStyle(
                color: member.isActive
                    ? Theme.of(context).colorScheme.error
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repo = ref.read(rosterRepositoryProvider);
      if (member.isActive) {
        await repo.deactivateMember(member.id);
      } else {
        await repo.reactivateMember(member.id);
      }
      ref.invalidate(rosterProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(memberDetailProvider(widget.memberId));
    final membershipAsync = ref.watch(currentMembershipProvider);
    final isAdmin = membershipAsync.valueOrNull?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: memberAsync.when(
          data: (m) => Text(m?.name ?? 'Jugador'),
          loading: () => const Text('Jugador'),
          error: (_, __) => const Text('Jugador'),
        ),
        actions: [
          if (isAdmin)
            memberAsync.when(
              data: (member) {
                if (member == null) return const SizedBox.shrink();
                if (_isEditing) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: _isSaving ? null : () => _saveEdits(member),
                        child: const Text('Guardar'),
                      ),
                    ],
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar jugador',
                  onPressed: () => setState(() => _isEditing = true),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Jugador no encontrado.'));
          }
          _loadControllers(member);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar + name
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: member.avatarUrl != null
                              ? NetworkImage(member.avatarUrl!)
                              : null,
                          child: member.avatarUrl == null
                              ? Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          member.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Status & roles
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            if (!member.isActive)
                              Chip(
                                label: const Text('Inactivo'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.errorContainer,
                                labelStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                              ),
                            if (member.isAdmin)
                              Chip(
                                label: const Text('Administrador'),
                                avatar: const Icon(
                                    Icons.admin_panel_settings,
                                    size: 16),
                              ),
                            if (member.isCoach)
                              Chip(
                                label: const Text('DT'),
                                avatar:
                                    const Icon(Icons.sports, size: 16),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Player data fields
                  if (_isEditing) ...[
                    TextFormField(
                      controller: _positionController,
                      decoration: const InputDecoration(
                        labelText: 'Posición',
                        hintText: 'Ej: Arquero, Defensa, Mediocampista...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jerseyController,
                      decoration: const InputDecoration(
                        labelText: 'Número de camiseta',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            int.tryParse(v.trim()) == null) {
                          return 'Ingresá un número válido';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    _InfoRow(
                      label: 'Posición',
                      value: member.position ?? '—',
                    ),
                    _InfoRow(
                      label: 'Número',
                      value: member.jerseyNumber?.toString() ?? '—',
                    ),
                  ],

                  // Admin-only sections
                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Roles y permisos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Administrador'),
                      subtitle: const Text(
                          'Puede gestionar el equipo y los partidos'),
                      value: member.isAdmin,
                      onChanged: (v) => _toggleRole(member, 'admin', v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      title: const Text('Director Técnico (DT)'),
                      subtitle: const Text(
                          'Evalúa a todos los jugadores del partido'),
                      value: member.isCoach,
                      onChanged: (v) => _toggleRole(member, 'coach', v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _toggleActive(member),
                      icon: Icon(
                        member.isActive
                            ? Icons.person_off
                            : Icons.person_add,
                        color: member.isActive
                            ? Theme.of(context).colorScheme.error
                            : Colors.green.shade700,
                      ),
                      label: Text(
                        member.isActive
                            ? 'Dar de baja'
                            : 'Reactivar jugador',
                        style: TextStyle(
                          color: member.isActive
                              ? Theme.of(context).colorScheme.error
                              : Colors.green.shade700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: member.isActive
                              ? Theme.of(context).colorScheme.error
                              : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Fila de información de solo lectura (etiqueta: valor).
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
