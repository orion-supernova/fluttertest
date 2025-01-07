import 'dart:async';
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/appwrite_service.dart';
import 'game_lobby_screen.dart';
import '../data/locations.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/cyberpunk_widgets.dart';
import '../models/user.dart';
import '../models/location.dart';

class GameRoomScreen extends StatefulWidget {
  final Room room;

  const GameRoomScreen({super.key, required this.room});

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  late final Stream<Room> _roomStream;
  Timer? _gameTimer;
  Duration _timeLeft = const Duration(minutes: 8);
  bool _isVoting = false;
  String? _selectedVote;
  Room? _currentRoom;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  @override
  void dispose() {
    print('Disposing game room screen...');
    _gameTimer?.cancel();
    super.dispose();
  }

  void _setupStreams() {
    _currentRoom = widget.room;
    _roomStream = AppwriteService().subscribeToRoom(widget.room.id);
  }

  void _startGameTimer() {
    if (_gameTimer != null) return;
    print('Starting game timer...');

    // Initialize time left from room settings
    _timeLeft = Duration(minutes: widget.room.roundTimeInMinutes ?? 8);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
        _startVoting();
      }
    });
    print('Game timer started');
  }

  void _startVoting() async {
    try {
      print('Starting voting phase...');
      await AppwriteService().startVoting(widget.room.id);
      setState(() => _isVoting = true);
    } catch (e) {
      print('Error starting voting: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting voting: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _castVote(String votedPlayerId) async {
    final currentUser = context.read<UserProvider>().user;
    if (currentUser == null) return;

    try {
      print('Casting vote: ${currentUser.userId} voting for $votedPlayerId');
      await AppwriteService()
          .castVote(widget.room.id, currentUser.userId, votedPlayerId);

      // Reset vote selection
      setState(() {
        _selectedVote = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote cast successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Error casting vote: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error casting vote: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _endGame() async {
    try {
      print('Ending game...');

      // First update status to waiting
      await AppwriteService()
          .updateRoomStatus(widget.room.id, AppwriteService.STATUS_WAIT);

      if (!mounted) return;

      // Then navigate back to home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      print('Error ending game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending game: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Map<String, int> _getVoteCounts(Map<String, String>? votes) {
    final voteCounts = <String, int>{};
    if (votes != null) {
      for (var votedForId in votes.values) {
        voteCounts[votedForId] = (voteCounts[votedForId] ?? 0) + 1;
      }
    }
    return voteCounts;
  }

  Widget _buildGameContent(Room room, String? currentUserId) {
    print('Building game content');
    print('Room status: ${room.status}');
    print('Game result: ${room.gameResult}');

    // Show game end UI if game has a result
    if (room.gameResult != null) {
      final isSpy = room.spyId == currentUserId;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              room.gameResult == 'crew_won' ? 'CREW WINS!' : 'SPY WINS!',
              style: const TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You were ${isSpy ? 'the SPY' : 'a CREW member'}',
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 18,
              ),
            ),
            if (!isSpy) ...[
              const SizedBox(height: 8),
              Text(
                'Location was: ${room.location}',
                style: const TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 18,
                ),
              ),
            ],
            const SizedBox(height: 32),
            CyberpunkButton(
              onPressed: _playAnotherRound,
              label: 'PLAY ANOTHER ROUND',
              color: const Color(0xFF00FFFF),
            ),
          ],
        ),
      );
    }

    final isSpy = room.spyId == currentUserId;
    final userRole = room.playerRoles?[currentUserId];

    // Show loading while waiting for game data
    if (room.spyId == null ||
        room.location == null ||
        room.playerRoles == null) {
      print('Game data not ready yet, showing loading screen');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF00FF),
            ),
            SizedBox(height: 16),
            Text(
              'INITIALIZING MISSION...',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    print('Game data ready, showing game UI');
    return Column(
      children: [
        // Timer
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFFFF00FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Role Information
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFF00FFFF)),
          ),
          child: Column(
            children: [
              Text(
                isSpy ? 'You are the Spy!' : 'Location: ${room.location}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF00FFFF),
                ),
              ),
              if (!isSpy) ...[
                const SizedBox(height: 8),
                Text(
                  'Your Role: $userRole',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFFFF00FF),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Location List for Spy
        if (isSpy)
          Expanded(
            child: FutureBuilder<List<Location>>(
              future: AppwriteService().getLocations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading locations: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF00FF),
                    ),
                  );
                }

                final locations = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: const Color(0xFF00FFFF)),
                      ),
                      child: Center(
                        child: Text(
                          location.name,
                          style: const TextStyle(
                            color: Color(0xFF00FFFF),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        // Voting UI
        if (_isVoting)
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Vote for the Spy',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFFFF00FF),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<User>>(
                    future: AppwriteService().getRoomPlayers(room.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading players: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF00FF),
                          ),
                        );
                      }

                      final players = snapshot.data!;
                      final votes = room.votes != null
                          ? Map<String, String>.from(room.votes!)
                          : null;
                      final voteCounts = _getVoteCounts(votes);

                      return ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final voteCount = voteCounts[player.userId] ?? 0;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(
                                color: (votes?.containsKey(currentUserId) ??
                                            false) &&
                                        votes?[currentUserId] == player.userId
                                    ? const Color(0xFFFF00FF)
                                    : const Color(0xFF00FFFF).withOpacity(0.3),
                                width: (votes?.containsKey(currentUserId) ??
                                            false) &&
                                        votes?[currentUserId] == player.userId
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    '${player.nickname}${player.userId == currentUserId ? ' (YOU)' : ''}',
                                    style: TextStyle(
                                      color: player.userId == currentUserId
                                          ? const Color(0xFF00FFFF)
                                              .withOpacity(0.5)
                                          : const Color(0xFF00FFFF),
                                    ),
                                  ),
                                  if ((votes?.containsKey(currentUserId) ??
                                          false) &&
                                      votes?[currentUserId] == player.userId)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Text(
                                        '(Your Vote)',
                                        style: TextStyle(
                                          color: Color(0xFFFF00FF),
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                'Votes: $voteCount',
                                style: const TextStyle(
                                  color: Color(0xFFFF00FF),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: player.userId != currentUserId
                                  ? IconButton(
                                      icon: Icon(
                                        (votes?.containsKey(currentUserId) ??
                                                    false) &&
                                                votes?[currentUserId] ==
                                                    player.userId
                                            ? Icons.how_to_vote
                                            : Icons.how_to_vote_outlined,
                                      ),
                                      color:
                                          (votes?.containsKey(currentUserId) ??
                                                      false) &&
                                                  votes?[currentUserId] ==
                                                      player.userId
                                              ? const Color(0xFFFF00FF)
                                              : const Color(0xFF00FFFF),
                                      onPressed: () => _castVote(player.userId),
                                    )
                                  : const Text(
                                      'Cannot vote for yourself',
                                      style: TextStyle(
                                        color: Color(0xFFFF0000),
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _playAnotherRound() async {
    try {
      print('Starting new round...');

      // First update status to initializing
      await AppwriteService()
          .updateRoomStatus(widget.room.id, AppwriteService.STATUS_INIT);

      // Initialize new game with different location
      await AppwriteService().initializeGame(widget.room.id,
          excludeLocation: _currentRoom?.location);

      // Update status to playing
      await AppwriteService()
          .updateRoomStatus(widget.room.id, AppwriteService.STATUS_PLAY);

      // Reset local state
      setState(() {
        _isVoting = false;
        _selectedVote = null;
        _timeLeft = const Duration(minutes: 8);
        _gameTimer?.cancel();
        _gameTimer = null;
      });
    } catch (e) {
      print('Error starting new round: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting new round: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().user;

    return WillPopScope(
      onWillPop: () async => false,
      child: StreamBuilder<Room>(
        stream: _roomStream,
        initialData: widget.room,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Stream error: ${snapshot.error}');
            return const Scaffold(
              body: Center(
                child: Text('Error loading game data'),
              ),
            );
          }

          final room = snapshot.data ?? widget.room;
          print(
              'Room status: ${room.status}, Game data: ${room.spyId}, ${room.location}, ${room.playerRoles}');

          // Start timer only when game is properly initialized
          if (room.status == AppwriteService.STATUS_PLAY &&
              room.spyId != null &&
              room.location != null &&
              room.playerRoles != null &&
              _gameTimer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startGameTimer();
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Game Room: ${room.roomCode}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  color: const Color(0xFFFF00FF),
                  tooltip: 'End Mission',
                  onPressed: _endGame,
                ),
              ],
            ),
            body: currentUser != null
                ? _buildGameContent(room, currentUser.userId)
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
