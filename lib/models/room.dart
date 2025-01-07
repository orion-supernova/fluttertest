import 'dart:convert';

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
  final Map<String, String>? playerRoles;
  final int? roundTimeInMinutes;
  final DateTime? roundStartTime;
  final bool? voteInProgress;
  final Map<String, String>? votes;
  final String? gameResult;

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
    this.playerRoles,
    this.roundTimeInMinutes = 8,
    this.roundStartTime,
    this.voteInProgress = false,
    this.votes,
    this.gameResult,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    print('Parsing room data: $json');

    try {
      // Parse playerRoles from string to Map
      Map<String, String>? playerRoles;
      if (json['playerRoles'] != null) {
        try {
          final rolesMap = jsonDecode(json['playerRoles']);
          playerRoles = Map<String, String>.from(rolesMap);
        } catch (e) {
          print('Error parsing playerRoles: $e');
          playerRoles = null;
        }
      }

      // Parse votes from string to Map
      Map<String, String>? votes;
      if (json['votes'] != null) {
        try {
          final votesMap = jsonDecode(json['votes']);
          votes = Map<String, String>.from(votesMap);
        } catch (e) {
          print('Error parsing votes: $e');
          votes = null;
        }
      }

      return Room(
        id: json['\$id'] ?? json['id'],
        roomCode: json['roomCode'],
        hostId: json['hostId'],
        playerIds: List<String>.from(json['playerIds'] ?? []),
        status: json['status'] ?? 'waiting',
        createdAt: DateTime.parse(json['createdAt']),
        maxPlayers: json['maxPlayers'],
        minPlayers: json['minPlayers'],
        spyId: json['spyId'],
        location: json['location'],
        playerRoles: playerRoles,
        roundTimeInMinutes: json['roundTimeInMinutes'],
        roundStartTime: json['roundStartTime'] != null
            ? DateTime.parse(json['roundStartTime'])
            : null,
        voteInProgress: json['voteInProgress'] ?? false,
        votes: votes,
        gameResult: json['gameResult'] as String?,
      );
    } catch (e) {
      print('Error parsing room data: $e');
      rethrow;
    }
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
        'playerRoles': playerRoles != null ? jsonEncode(playerRoles) : null,
        'roundTimeInMinutes': roundTimeInMinutes,
        'roundStartTime': roundStartTime?.toIso8601String(),
        'voteInProgress': voteInProgress,
        'votes': votes != null ? jsonEncode(votes) : null,
        'gameResult': gameResult,
      };
}
