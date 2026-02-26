import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/team_provider.dart';
import '../../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

/// Pantalla principal (Dashboard) del equipo.
/// Muestra el nombre del equipo, liga y accesos rápidos a las secciones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(currentMembershipProvider);
    final settingsAsync = ref.watch(teamSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EstudiososApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error al cargar el equipo:\n$e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(teamSettingsProvider);
                    ref.invalidate(currentMembershipProvider);
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (settings) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teamSettingsProvider);
              ref.invalidate(currentMembershipProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          _TeamShield(shieldUrl: settings.team.shieldUrl),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  settings.team.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (settings.league != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      settings.league!['name'] as String?,
                                      settings.league!['season'] as String?,
                                    ]
                                        .whereType<String>()
                                        .where((s) => s.isNotEmpty)
                                        .join(' • '),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Acciones rápidas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  _QuickActionCard(
                    icon: Icons.group,
                    title: 'Plantel',
                    subtitle: 'Ver jugadores y roles del equipo',
                    onTap: () => context.push('/roster'),
                  ),
                  const SizedBox(height: 8),

                  _QuickActionCard(
                    icon: Icons.sports_soccer,
                    title: 'Partidos',
                    subtitle: 'Próximamente',
                    onTap: null,
                  ),
                  const SizedBox(height: 8),

                  // Settings only for admins
                  membershipAsync.when(
                    data: (m) => m?.isAdmin == true
                        ? _QuickActionCard(
                            icon: Icons.settings,
                            title: 'Configuración del equipo',
                            subtitle:
                                'Nombre, escudo, liga e invitaciones',
                            onTap: () => context.push('/settings'),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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

class _TeamShield extends StatelessWidget {
  final String? shieldUrl;

  const _TeamShield({this.shieldUrl});

  @override
  Widget build(BuildContext context) {
    if (shieldUrl != null) {
      return ClipOval(
        child: Image.network(
          shieldUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const _DefaultShield(),
        ),
      );
    }
    return const _DefaultShield();
  }
}

class _DefaultShield extends StatelessWidget {
  const _DefaultShield();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Icon(
        Icons.sports_soccer,
        size: 30,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: onTap != null
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }
}
