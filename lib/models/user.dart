class User {
  final String id;
  final String userId;
  final String nickname;
  final String? currentRoomId;
  final bool isReady;
  final DateTime lastActive;
  final int score;

  User({
    required this.id,
    required this.userId,
    required this.nickname,
    this.currentRoomId,
    required this.isReady,
    required this.lastActive,
    required this.score,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['\$id'] as String,
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      currentRoomId: json['currentRoomId'] as String?,
      isReady: json['isReady'] as bool? ?? false,
      lastActive: DateTime.parse(json['lastActive'] as String),
      score: json['score'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'nickname': nickname,
        'currentRoomId': currentRoomId,
        'isReady': isReady,
        'lastActive': lastActive.toIso8601String(),
        'score': score,
      };

  User copyWith({
    String? nickname,
    String? currentRoomId,
    bool? isReady,
    DateTime? lastActive,
    int? score,
  }) {
    return User(
      id: id,
      userId: userId,
      nickname: nickname ?? this.nickname,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isReady: isReady ?? this.isReady,
      lastActive: lastActive ?? this.lastActive,
      score: score ?? this.score,
    );
  }
}
