import 'package:equatable/equatable.dart';

/// Modelo de un miembro del equipo (join de team_members + users).
class TeamMemberModel extends Equatable {
  final String id; // team_members.id
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? position;
  final int? jerseyNumber;
  final bool isAdmin;
  final bool isCoach;
  final bool isActive;

  const TeamMemberModel({
    required this.id,
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.position,
    this.jerseyNumber,
    required this.isAdmin,
    required this.isCoach,
    required this.isActive,
  });

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['users'] as Map<String, dynamic>? ?? {};
    return TeamMemberModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: user['name'] as String? ?? 'Sin nombre',
      avatarUrl: user['avatar_url'] as String?,
      position: json['position'] as String?,
      jerseyNumber: json['jersey_number'] as int?,
      isAdmin: json['is_admin'] as bool? ?? false,
      isCoach: json['is_coach'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  TeamMemberModel copyWith({
    String? position,
    int? jerseyNumber,
    bool? isAdmin,
    bool? isCoach,
    bool? isActive,
  }) {
    return TeamMemberModel(
      id: id,
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      isAdmin: isAdmin ?? this.isAdmin,
      isCoach: isCoach ?? this.isCoach,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        avatarUrl,
        position,
        jerseyNumber,
        isAdmin,
        isCoach,
        isActive,
      ];
}
