// class UserModel {
//   final String id;
//   final String name;
//   final String avatar;
//   final DateTime createdAt;
//   final int totalStars;
//   final int sessionsCompleted;
//   final List<String> weakAreas;
//   final String currentLevel;

//   const UserModel({
//     required this.id,
//     required this.name,
//     required this.avatar,
//     required this.createdAt,
//     this.totalStars = 0,
//     this.sessionsCompleted = 0,
//     this.weakAreas = const [],
//     this.currentLevel = 'beginner',
//   });

//   UserModel copyWith({
//     String? id,
//     String? name,
//     String? avatar,
//     DateTime? createdAt,
//     int? totalStars,
//     int? sessionsCompleted,
//     List<String>? weakAreas,
//     String? currentLevel,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       avatar: avatar ?? this.avatar,
//       createdAt: createdAt ?? this.createdAt,
//       totalStars: totalStars ?? this.totalStars,
//       sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
//       weakAreas: weakAreas ?? this.weakAreas,
//       currentLevel: currentLevel ?? this.currentLevel,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       'avatar': avatar,
//       'createdAt': createdAt.toIso8601String(),
//       'totalStars': totalStars,
//       'sessionsCompleted': sessionsCompleted,
//       'weakAreas': weakAreas,
//       'currentLevel': currentLevel,
//     };
//   }

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       avatar: json['avatar'] as String,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       totalStars: (json['totalStars'] as int?) ?? 0,
//       sessionsCompleted: (json['sessionsCompleted'] as int?) ?? 0,
//       weakAreas: List<String>.from((json['weakAreas'] as List?) ?? []),
//       currentLevel: (json['currentLevel'] as String?) ?? 'beginner',
//     );
//   }
// }

// class ProgressModel {
//   final String userId;
//   final String module;
//   final int score;
//   final int stars;
//   final int durationSeconds;
//   final DateTime completedAt;

//   const ProgressModel({
//     required this.userId,
//     required this.module,
//     required this.score,
//     required this.stars,
//     required this.durationSeconds,
//     required this.completedAt,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'userId': userId,
//       'module': module,
//       'score': score,
//       'stars': stars,
//       'durationSeconds': durationSeconds,
//       'completedAt': completedAt.toIso8601String(),
//     };
//   }

//   factory ProgressModel.fromJson(Map<String, dynamic> json) {
//     return ProgressModel(
//       userId: json['userId'] as String,
//       module: json['module'] as String,
//       score: (json['score'] as int?) ?? 0,
//       stars: (json['stars'] as int?) ?? 1,
//       durationSeconds: (json['durationSeconds'] as int?) ?? 0,
//       completedAt: DateTime.parse(json['completedAt'] as String),
//     );
//   }
// }


class UserModel {
  final String id;
  final String name;
  final String avatar;
  final DateTime createdAt;
  final int totalStars;
  final int sessionsCompleted;
  final List<String> weakAreas;
  final String currentLevel;

  const UserModel({
    required this.id,
    required this.name,
    required this.avatar,
    required this.createdAt,
    this.totalStars = 0,
    this.sessionsCompleted = 0,
    this.weakAreas = const [],
    this.currentLevel = 'beginner',
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? avatar,
    DateTime? createdAt,
    int? totalStars,
    int? sessionsCompleted,
    List<String>? weakAreas,
    String? currentLevel,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      totalStars: totalStars ?? this.totalStars,
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      weakAreas: weakAreas ?? this.weakAreas,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'totalStars': totalStars,
      'sessionsCompleted': sessionsCompleted,
      'weakAreas': weakAreas,
      'currentLevel': currentLevel,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '🧑‍🎓',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),

      totalStars: (json['totalStars'] is int)
          ? json['totalStars']
          : int.tryParse(json['totalStars']?.toString() ?? '0') ?? 0,

      sessionsCompleted: (json['sessionsCompleted'] is int)
          ? json['sessionsCompleted']
          : int.tryParse(json['sessionsCompleted']?.toString() ?? '0') ?? 0,

      weakAreas: (json['weakAreas'] is List)
          ? (json['weakAreas'] as List)
              .map((e) => e.toString())
              .toList()
          : [],

      currentLevel: json['currentLevel']?.toString() ?? 'beginner',
    );
  }
}

class ProgressModel {
  final String userId;
  final String module;
  final int score;
  final int stars;
  final int durationSeconds;
  final DateTime completedAt;

  const ProgressModel({
    required this.userId,
    required this.module,
    required this.score,
    required this.stars,
    required this.durationSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'module': module,
      'score': score,
      'stars': stars,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      userId: json['userId']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      score: int.tryParse(json['score']?.toString() ?? '0') ?? 0,
      stars: int.tryParse(json['stars']?.toString() ?? '1') ?? 1,
      durationSeconds:
          int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      completedAt:
          DateTime.tryParse(json['completedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}
