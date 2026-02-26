import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/team_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/roster_provider.dart';
import '../widgets/player_list_tile.dart';

/// Pantalla principal del plantel del equipo.
/// Muestra nombre, escudo, integrantes y roles.
class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(currentMembershipProvider);
    final rosterAsync = ref.watch(rosterProvider);
    final settingsAsync = ref.watch(teamSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: settingsAsync.when(
          data: (s) => Text(s.team.name),
          loading: () => const Text('Plantel'),
          error: (_, __) => const Text('Plantel'),
        ),
        actions: [
          membershipAsync.when(
            data: (m) => m?.isAdmin == true
                ? IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: 'Configuración del equipo',
                    onPressed: () => context.push('/settings'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error al cargar el plantel:\n$e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(rosterProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (members) {
          final activeMembers = members.where((m) => m.isActive).toList();
          final inactiveMembers = members.where((m) => !m.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(rosterProvider);
              ref.invalidate(teamSettingsProvider);
            },
            child: CustomScrollView(
              slivers: [
                // Team header
                SliverToBoxAdapter(
                  child: settingsAsync.when(
                    data: (s) => _TeamHeader(
                      teamName: s.team.name,
                      shieldUrl: s.team.shieldUrl,
                      memberCount: activeMembers.length,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                // Active members header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Plantel activo (${activeMembers.length})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
                if (activeMembers.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('No hay jugadores activos.'),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = activeMembers[index];
                        return PlayerListTile(
                          member: member,
                          onTap: () => context.push('/roster/${member.id}'),
                        );
                      },
                      childCount: activeMembers.length,
                    ),
                  ),

                // Inactive members
                if (inactiveMembers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                      child: Text(
                        'Inactivos (${inactiveMembers.length})',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final member = inactiveMembers[index];
                        return PlayerListTile(
                          member: member,
                          onTap: () => context.push('/roster/${member.id}'),
                        );
                      },
                      childCount: inactiveMembers.length,
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TeamHeader extends StatelessWidget {
  final String teamName;
  final String? shieldUrl;
  final int memberCount;

  const _TeamHeader({
    required this.teamName,
    this.shieldUrl,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          shieldUrl != null
              ? ClipOval(
                  child: Image.network(
                    shieldUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _DefaultShield(size: 80),
                  ),
                )
              : const _DefaultShield(size: 80),
          const SizedBox(height: 12),
          Text(
            teamName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$memberCount integrante${memberCount == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

class _DefaultShield extends StatelessWidget {
  final double size;

  const _DefaultShield({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Icon(
        Icons.sports_soccer,
        size: size * 0.55,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
