import 'package:flutter/material.dart';

import '../../data/models/team_member_model.dart';

/// Tile para mostrar un jugador en la lista del plantel.
class PlayerListTile extends StatelessWidget {
  final TeamMemberModel member;
  final VoidCallback? onTap;

  const PlayerListTile({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.outlineVariant,
        backgroundImage:
            member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
        child: member.avatarUrl == null
            ? Text(
                member.name.isNotEmpty
                    ? member.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: member.isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        member.jerseyNumber != null
            ? '#${member.jerseyNumber} ${member.name}'
            : member.name,
        style: TextStyle(
          color: member.isActive ? null : theme.colorScheme.outline,
        ),
      ),
      subtitle: _buildSubtitle(context),
      trailing: _buildRoleChips(context),
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    if (!member.isActive) {
      return Text(
        'Inactivo',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
        ),
      );
    }
    if (member.position != null) return Text(member.position!);
    return null;
  }

  Widget? _buildRoleChips(BuildContext context) {
    final chips = <Widget>[];
    if (member.isAdmin) {
      chips.add(
        _RoleChip(
          label: 'Admin',
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (member.isCoach) {
      chips.add(
        _RoleChip(
          label: 'DT',
          color: Colors.green.shade700,
        ),
      );
    }
    if (chips.isEmpty) return null;
    return Wrap(spacing: 4, children: chips);
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: color),
      backgroundColor: color.withAlpha(26),
      visualDensity: VisualDensity.compact,
    );
  }
}
