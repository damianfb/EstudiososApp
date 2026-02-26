import 'package:equatable/equatable.dart';

/// Modelo de datos del equipo.
class TeamModel extends Equatable {
  final String id;
  final String name;
  final String? shieldUrl;
  final String inviteCode;
  final int evaluationTimeLimitHours;

  const TeamModel({
    required this.id,
    required this.name,
    this.shieldUrl,
    required this.inviteCode,
    required this.evaluationTimeLimitHours,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      shieldUrl: json['shield_url'] as String?,
      inviteCode: json['invite_code'] as String,
      evaluationTimeLimitHours:
          json['evaluation_time_limit_hours'] as int? ?? 48,
    );
  }

  TeamModel copyWith({
    String? name,
    String? shieldUrl,
    int? evaluationTimeLimitHours,
  }) {
    return TeamModel(
      id: id,
      name: name ?? this.name,
      shieldUrl: shieldUrl ?? this.shieldUrl,
      inviteCode: inviteCode,
      evaluationTimeLimitHours:
          evaluationTimeLimitHours ?? this.evaluationTimeLimitHours,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, shieldUrl, inviteCode, evaluationTimeLimitHours];
}
