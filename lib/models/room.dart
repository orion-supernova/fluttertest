class Room {
  final String id;
  final String roomCode;
  final String hostId;
  final List<String> playerIds;
  final String status;
  final DateTime createdAt;
  final int maxPlayers;
  final int minPlayers;
  final String? spyId;
  final String? location;

  Room({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.playerIds,
    required this.status,
    required this.createdAt,
    required this.maxPlayers,
    required this.minPlayers,
    this.spyId,
    this.location,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    List<String> convertPlayerIds(dynamic playerIdsData) {
      if (playerIdsData == null) return [];
      if (playerIdsData is List) {
        return List<String>.from(playerIdsData.map((e) => e.toString()));
      }
      return [];
    }

    return Room(
      id: json['\$id'],
      roomCode: json['roomCode'],
      hostId: json['hostId'],
      playerIds: convertPlayerIds(json['playerIds']),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      maxPlayers: json['maxPlayers'],
      minPlayers: json['minPlayers'],
      spyId: json['spyId'],
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'hostId': hostId,
        'playerIds': playerIds,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'maxPlayers': maxPlayers,
        'minPlayers': minPlayers,
        'spyId': spyId,
        'location': location,
      };
}
