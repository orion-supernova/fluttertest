import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite/src/enums.dart';
import '../models/room.dart';
import '../models/user.dart';

class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late final Client _client;
  late final Databases _databases;
  late final Account _account;
  String? _userId;

  static const String _databaseId = '673cd295001cdac21eea';
  static const String _roomsCollectionId = '676f1e9e001d71f7896b';
  static const String _usersCollectionId = '676f1fd70021b0527f11';
  static const String _endpoint = 'https://cloud.appwrite.io/v1';
  static const String _projectId = '673ccac6002a8a5135e6';

  Future<void> initialize() async {
    _client =
        Client().setEndpoint(_endpoint).setProject(_projectId).setSelfSigned();

    _databases = Databases(_client);
    _account = Account(_client);

    // Try to get existing session
    try {
      final user = await _account.get();
      _userId = user.$id;
      print('Existing user found: $_userId');
    } catch (e) {
      print('No existing user found');
    }
  }

  bool get isInitialized {
    try {
      return _databases != null;
    } catch (e) {
      return false;
    }
  }

  // Room Operations
  Future<Room> createRoom({
    required String roomCode,
    required int maxPlayers,
  }) async {
    if (_userId == null) {
      await anonymousLogin();
    }

    final data = {
      'roomCode': roomCode,
      'hostId': _userId!,
      'playerIds': [],
      'status': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
      'maxPlayers': maxPlayers,
      'minPlayers': 3,
      'spyId': null,
      'location': null,
    };

    final doc = await _databases.createDocument(
      databaseId: _databaseId,
      collectionId: _roomsCollectionId,
      documentId: ID.unique(),
      data: data,
    );

    await _databases.updateDocument(
      databaseId: _databaseId,
      collectionId: _roomsCollectionId,
      documentId: doc.$id,
      data: {
        'playerIds': [_userId!],
      },
    );

    return Room.fromJson(doc.data);
  }

  Future<Room?> getRoom(String roomCode) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        queries: [
          Query.equal('roomCode', roomCode),
        ],
      );

      if (response.documents.isEmpty) return null;

      // Return the first room with matching code
      return Room.fromJson(response.documents.first.data);
    } catch (e) {
      print('Error getting room: $e');
      rethrow;
    }
  }

  // User Operations
  Future<User> createOrUpdateUser({
    required String nickname,
  }) async {
    if (_userId == null) {
      await anonymousLogin();
    }

    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [Query.equal('userId', _userId!)],
      );

      if (response.documents.isEmpty) {
        // Create new user
        final doc = await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': _userId!,
            'nickname': nickname,
            'isReady': false,
            'lastActive': DateTime.now().toIso8601String(),
            'score': 0,
            'currentRoomId': null,
          },
        );
        return User.fromJson(doc.data);
      } else {
        // Update existing user
        final user = response.documents.first;
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: user.$id,
          data: {
            'lastActive': DateTime.now().toIso8601String(),
            'nickname': nickname,
          },
        );
        return User.fromJson(user.data);
      }
    } catch (e) {
      print('Error in createOrUpdateUser: $e');
      rethrow;
    }
  }

  Future<void> anonymousLogin() async {
    if (!isInitialized) {
      await initialize();
    }
    print("Starting anonymous login...");

    try {
      // Check if we already have a valid session
      try {
        final user = await _account.get();
        _userId = user.$id;
        print('Using existing session. User ID: $_userId');
        return;
      } catch (e) {
        print('No valid session found, creating new one...');

        // Clean up any existing sessions
        try {
          await _account.deleteSessions();
          print('Cleaned up existing sessions');
        } catch (e) {
          print('No sessions to clean up');
        }
      }

      // Create new anonymous session
      final result = await _client.call(
        HttpMethod.post,
        path: '/account/sessions/anonymous',
        headers: {
          'content-type': 'application/json',
        },
      );

      if (result.data != null) {
        _userId = result.data['userId'] as String;
        print('Successfully created anonymous session. User ID: $_userId');
      } else {
        throw Exception('Failed to create anonymous session');
      }
    } catch (e) {
      print('Fatal error in anonymous login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_userId == null) return; // Skip if not logged in

    try {
      await _account.deleteSessions();
      _userId = null;
      print('Successfully logged out and cleared all sessions');
    } catch (e) {
      print('Error logging out: $e');
      // Don't rethrow - just log the error
    }
  }

  Future<bool> checkRoomExists(String roomCode) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        queries: [
          Query.equal('roomCode', roomCode),
          Query.equal('status', 'waiting'), // Only check active rooms
        ],
      );

      return response.documents.isNotEmpty;
    } catch (e) {
      print('Error checking room existence: $e');
      return false; // Assume doesn't exist on error
    }
  }

  Future<Room> createAndJoinRoom({
    required String roomCode,
    required int maxPlayers,
  }) async {
    if (_userId == null) {
      await anonymousLogin();
    }

    try {
      // First create the room
      final room = await createRoom(
        roomCode: roomCode,
        maxPlayers: maxPlayers,
      );

      // Check if user exists and create if not
      final userResponse = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [Query.equal('userId', _userId!)],
      );

      if (userResponse.documents.isEmpty) {
        // Create new user document
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': _userId!,
            'nickname':
                'Agent${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
            'currentRoomId': room.id,
            'isReady': false,
            'score': 0,
            'lastActive': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Update existing user
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: userResponse.documents.first.$id,
          data: {
            'currentRoomId': room.id,
            'isReady': false,
            'lastActive': DateTime.now().toIso8601String(),
          },
        );
      }

      return room;
    } catch (e) {
      print('Error creating and joining room: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String roomId, {bool isHost = false}) async {
    if (_userId == null) {
      await anonymousLogin();
    }

    try {
      // First find the user document
      final userResponse = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [Query.equal('userId', _userId!)],
      );

      if (userResponse.documents.isEmpty) {
        // Create new user if doesn't exist
        await _databases.createDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: ID.unique(),
          data: {
            'userId': _userId!,
            'nickname':
                'Agent${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
            'currentRoomId': roomId,
            'isReady': false,
            'score': 0,
            'lastActive': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Update existing user
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: userResponse.documents.first.$id,
          data: {
            'currentRoomId': roomId,
            'isReady': false,
            'lastActive': DateTime.now().toIso8601String(),
          },
        );
      }

      // Add user to room's player list
      final room = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        documentId: roomId,
      );

      final List<String> currentPlayers =
          List<String>.from(room.data['playerIds'] ?? []);
      if (!currentPlayers.contains(_userId)) {
        currentPlayers.add(_userId!);

        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _roomsCollectionId,
          documentId: roomId,
          data: {
            'playerIds': currentPlayers,
          },
        );
      }
    } catch (e) {
      print('Error joining room: $e');
      rethrow;
    }
  }

  Stream<Room> subscribeToRoom(String roomId) {
    final realtime = Realtime(_client);
    print('Subscribing to room: $roomId');
    return realtime
        .subscribe([
          'databases.$_databaseId.collections.$_roomsCollectionId.documents.$roomId'
        ])
        .stream
        .map((event) {
          if (event.events
              .contains('databases.*.collections.*.documents.*.update')) {
            print('Room update event received');
            final room = Room.fromJson(event.payload);
            print(
                'Room status: ${room.status}, Players: ${room.playerIds.length}');
            return room;
          }
          return Room.fromJson(event.payload);
        });
  }

  Stream<List<User>> subscribeToRoomPlayers(String roomId) {
    final realtime = Realtime(_client);

    // Subscribe to all user document changes
    return realtime
        .subscribe([
          'databases.$_databaseId.collections.$_usersCollectionId.documents'
        ])
        .stream
        .asyncMap((_) async {
          // Get all players in room whenever there's any change
          try {
            final response = await _databases.listDocuments(
              databaseId: _databaseId,
              collectionId: _usersCollectionId,
              queries: [Query.equal('currentRoomId', roomId)],
            );

            return response.documents
                .map((doc) => User.fromJson(doc.data))
                .toList();
          } catch (e) {
            print('Error getting room players: $e');
            return <User>[];
          }
        });
  }

  Future<List<User>> getRoomPlayers(String roomId) async {
    final response = await _databases.listDocuments(
      databaseId: _databaseId,
      collectionId: _usersCollectionId,
      queries: [Query.equal('currentRoomId', roomId)],
    );

    return response.documents.map((doc) => User.fromJson(doc.data)).toList();
  }

  Future<void> setPlayerReady(bool ready) async {
    if (_userId == null) {
      print('Cannot set ready state: No user ID');
      return;
    }

    try {
      final userDoc = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [Query.equal('userId', _userId!)],
      );

      if (userDoc.documents.isEmpty) {
        print('Cannot set ready state: User document not found');
        return;
      }

      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        documentId: userDoc.documents.first.$id,
        data: {
          'isReady': ready,
          'lastActive':
              DateTime.now().toIso8601String(), // Update last active timestamp
        },
      );
      print('Successfully set ready state to: $ready');
    } catch (e) {
      print('Error setting ready state: $e');
      rethrow;
    }
  }

  Future<void> kickPlayerFromRoom(String roomId, String userId) async {
    try {
      // Simply call leaveRoom with the userId to kick
      await leaveRoom(roomId, userId: userId);
      print('Successfully kicked player: $userId from room: $roomId');
    } catch (e) {
      print('Error kicking player: $e');
      rethrow;
    }
  }

  Future<void> leaveRoom(String roomId, {String? userId}) async {
    // Use provided userId or current user's id
    final targetUserId = userId ?? _userId;
    if (targetUserId == null) return;

    try {
      // Update user document
      final userDoc = await _databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _usersCollectionId,
        queries: [Query.equal('userId', targetUserId)],
      );

      if (userDoc.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: _databaseId,
          collectionId: _usersCollectionId,
          documentId: userDoc.documents.first.$id,
          data: {
            'currentRoomId': null,
            'isReady': false,
          },
        );
      }

      // Remove user from room's player list
      final room = await _databases.getDocument(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        documentId: roomId,
      );

      final List<String> players =
          List<String>.from(room.data['playerIds'] ?? []);
      players.remove(targetUserId);

      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        documentId: roomId,
        data: {'playerIds': players},
      );

      print('Successfully removed user: $targetUserId from room: $roomId');
    } catch (e) {
      print('Error removing user from room: $e');
      rethrow;
    }
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    try {
      await _databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _roomsCollectionId,
        documentId: roomId,
        data: {'status': status},
      );
      print('Room status updated to: $status');
    } catch (e) {
      print('Error updating room status: $e');
      rethrow;
    }
  }

  // ... rest of your existing authentication code ...
}
