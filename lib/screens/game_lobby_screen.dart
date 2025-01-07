import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/appwrite_service.dart';
import '../widgets/cyberpunk_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:async';
import 'game_room_screen.dart';

class GameLobbyScreen extends StatefulWidget {
  final Room room;

  const GameLobbyScreen({super.key, required this.room});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen>
    with WidgetsBindingObserver {
  bool _isReady = false;
  List<User> _players = [];
  bool _isLoading = false;
  late final Stream<Room> _roomStream;
  late final Stream<List<User>> _playersStream;
  bool _isSettingReady = false;
  Timer? _countdownTimer;
  int _countdown = 5;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    print('GameLobbyScreen initState');
    WidgetsBinding.instance.addObserver(this);
    _setupStreams();
    _loadPlayers();
  }

  @override
  Future<void> dispose() async {
    print('GameLobbyScreen disposing...');
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.inactive && !_isSettingReady) {
      _setNotReady();
    }
  }

  Future<void> _setNotReady() async {
    if (!_isReady || _isSettingReady) return;

    print(
        'Attempting to set player not ready... Current ready state: $_isReady');
    _isSettingReady = true;

    try {
      await AppwriteService().setPlayerReady(false);
      if (mounted) {
        setState(() {
          _isReady = false;
          _isSettingReady = false;
        });
        print('Successfully set player not ready');
      } else {
        _isSettingReady = false;
        print('Widget not mounted, skipping setState');
      }
    } catch (e) {
      _isSettingReady = false;
      print('Error setting player not ready: $e');
    }
  }

  void _setupStreams() {
    // Subscribe to room updates
    _roomStream = AppwriteService().subscribeToRoom(widget.room.id);
    _playersStream = AppwriteService().subscribeToRoomPlayers(widget.room.id);
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    try {
      _players = await AppwriteService().getRoomPlayers(widget.room.id);
      setState(() {});
    } catch (e) {
      print('Error loading players: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReady() async {
    try {
      await AppwriteService().setPlayerReady(!_isReady);
      setState(() => _isReady = !_isReady);

      // Only check for countdown if setting to ready
      if (_isReady) {
        // Get fresh list of players
        final players = await AppwriteService().getRoomPlayers(widget.room.id);
        print(
            'Current players: ${players.map((p) => '${p.nickname}: ${p.isReady}')}');

        // Check if all players are ready and meet minimum requirement
        final allReady = players.every((p) => p.isReady);
        final enoughPlayers = players.length >= widget.room.minPlayers;

        print('All players ready: $allReady, Enough players: $enoughPlayers');

        if (allReady && enoughPlayers) {
          print('Starting countdown...');
          await AppwriteService().updateRoomStatus(widget.room.id, 'countdown');
        }
      } else {
        // If player is unready, cancel countdown
        await AppwriteService().updateRoomStatus(widget.room.id, 'waiting');
      }
    } catch (e) {
      print('Error toggling ready state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _kickPlayer(String userId) async {
    try {
      await AppwriteService().kickPlayerFromRoom(widget.room.id, userId);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error kicking player: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      print('Error kicking player: $e');
    }
  }

  Future<void> _showChangeNicknameDialog() async {
    String? currentNickname = context.read<UserProvider>().user?.nickname;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: currentNickname);
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              color: const Color(0xFF00FFFF).withOpacity(0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.edit,
                color: Color(0xFF00FFFF),
              ),
              SizedBox(width: 8),
              Text(
                'CHANGE CODENAME',
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  letterSpacing: 2,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: CyberpunkTextField(
              label: 'NEW CODENAME',
              controller: controller,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Codename required';
                }
                if (value.length < 3) {
                  return 'Minimum 3 characters';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'CANCEL',
                style: TextStyle(
                  color: const Color(0xFF00FFFF).withOpacity(0.7),
                  letterSpacing: 2,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await context
                        .read<UserProvider>()
                        .updateNickname(controller.text);
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Codename updated successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating codename: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'CONFIRM',
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLeaveRoom() async {
    try {
      print('Handling leave room...');

      // First set not ready
      if (_isReady) {
        print('Setting player not ready before leaving...');
        await AppwriteService().setPlayerReady(false);
      }

      // Then leave the room
      print('Leaving room: ${widget.room.id}');
      await AppwriteService().leaveRoom(widget.room.id);

      print('Successfully left room, navigating back...');

      // Make sure we're mounted and pop the navigation
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error leaving room: $e');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error leaving room: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startCountdown() {
    if (_isCountingDown || !mounted) return;

    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      print('Countdown: $_countdown');

      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _countdown = 5;
        });

        try {
          print('Starting game initialization sequence...');

          // First update status to initializing
          await AppwriteService()
              .updateRoomStatus(widget.room.id, AppwriteService.STATUS_INIT);
          print('Room status set to initializing');

          // Initialize game data
          await AppwriteService().initializeGame(widget.room.id);
          print('Game initialization completed');

          // Update status to playing
          await AppwriteService()
              .updateRoomStatus(widget.room.id, AppwriteService.STATUS_PLAY);
          print('Room status set to playing');

          if (!mounted) return;

          // Get the updated room data with all game information
          final updatedRoom =
              await AppwriteService().getRoom(widget.room.roomCode);
          print(
              'Got updated room data: ${updatedRoom?.spyId}, ${updatedRoom?.location}, ${updatedRoom?.playerRoles}');

          if (updatedRoom == null) {
            throw 'Failed to get updated room data';
          }

          // Navigate to game room with the updated room data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => GameRoomScreen(room: updatedRoom),
            ),
          );
        } catch (e) {
          print('Error in game start sequence: $e');
          print('Stack trace: ${StackTrace.current}');

          // Reset room on error
          await AppwriteService()
              .updateRoomStatus(widget.room.id, AppwriteService.STATUS_WAIT);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error starting game: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    });
  }

  void _cancelCountdown() {
    if (!_isCountingDown || !mounted) return;

    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _isCountingDown = false;
        _countdown = 5;
      });
    }
  }

  bool _allPlayersReady(List<User> players) {
    return players.every((p) => p.isReady) &&
        players.length >= widget.room.minPlayers;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().user;
    final isHost = currentUser?.userId == widget.room.hostId;

    return WillPopScope(
      onWillPop: () async {
        print('WillPopScope triggered');
        await _handleLeaveRoom();
        return false; // Let _handleLeaveRoom handle the navigation
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: const Color(0xFFFF00FF),
                onPressed: _handleLeaveRoom,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPERATION: ${widget.room.roomCode}',
                    style: const TextStyle(
                      color: Color(0xFFFF00FF),
                      letterSpacing: 2,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    isHost ? 'COMMANDER' : 'AGENT',
                    style: TextStyle(
                      color: const Color(0xFFFF00FF).withValues(alpha: 0.7),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy),
              color: const Color(0xFFFF00FF),
              tooltip: 'Copy Room Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.room.roomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Room code copied to clipboard!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: StreamBuilder<Room>(
            stream: _roomStream,
            builder: (context, roomSnapshot) {
              if (roomSnapshot.hasData) {
                final room = roomSnapshot.data!;

                // Handle countdown state
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (room.status == 'countdown' && !_isCountingDown) {
                    _startCountdown();
                  } else if (room.status != 'countdown' && _isCountingDown) {
                    _cancelCountdown();
                  }
                  // Remove the navigation on 'playing' status
                });
              }

              final room = roomSnapshot.data ?? widget.room;
              print('Room snapshot: ${room.status}');

              return StreamBuilder<List<User>>(
                stream: _playersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Player stream error: ${snapshot.error}');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFFF0000),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading agents: ${snapshot.error}',
                            style: const TextStyle(color: Color(0xFFFF0000)),
                          ),
                        ],
                      ),
                    );
                  }

                  final players = snapshot.data ?? _players;
                  print(
                      'Players ready status: ${players.map((p) => p.isReady)}');

                  return Stack(
                    children: [
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Status Panel
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(
                                    color: const Color(0xFF00FFFF)
                                        .withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFFF)
                                          .withValues(alpha: 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _StatusItem(
                                          label: 'AGENTS',
                                          value:
                                              '${players.length}/${widget.room.maxPlayers}',
                                          icon: Icons.group,
                                        ),
                                        _StatusItem(
                                          label: 'READY',
                                          value:
                                              '${_getReadyCount(players)}/${players.length}',
                                          icon: Icons.check_circle,
                                          color: _allPlayersReady(players)
                                              ? const Color(0xFF00FF00)
                                              : const Color(0xFFFF0000),
                                        ),
                                      ],
                                    ),
                                    if (widget.room.minPlayers >
                                        players.length) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Need ${widget.room.minPlayers - players.length} more agent(s)',
                                        style: const TextStyle(
                                          color: Color(0xFFFF0000),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Player List
                              Expanded(
                                child: ListView.builder(
                                  itemCount: players.length,
                                  itemBuilder: (context, index) {
                                    final player = players[index];
                                    final isCurrentUser =
                                        player.userId == currentUser?.userId;
                                    final isPlayerHost =
                                        player.userId == widget.room.hostId;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        border: Border.all(
                                          color: isPlayerHost
                                              ? const Color(0xFFFF00FF)
                                                  .withValues(alpha: 0.5)
                                              : const Color(0xFF00FFFF)
                                                  .withValues(alpha: 0.3),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isPlayerHost
                                                    ? const Color(0xFFFF00FF)
                                                    : const Color(0xFF00FFFF))
                                                .withValues(alpha: 0.1),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: Stack(
                                          children: [
                                            Icon(
                                              isPlayerHost
                                                  ? Icons.security
                                                  : Icons.person,
                                              color: isPlayerHost
                                                  ? const Color(0xFFFF00FF)
                                                  : const Color(0xFF00FFFF),
                                              size: 28,
                                            ),
                                            if (player.isReady)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.black,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFF00FF00),
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        title: Text(
                                          player.nickname +
                                              (isCurrentUser ? ' (YOU)' : ''),
                                          style: TextStyle(
                                            color: isPlayerHost
                                                ? const Color(0xFFFF00FF)
                                                : const Color(0xFF00FFFF),
                                            letterSpacing: 1.5,
                                            fontWeight: isCurrentUser
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isCurrentUser)
                                              IconButton(
                                                icon: const Icon(Icons.edit),
                                                color: const Color(0xFF00FFFF),
                                                tooltip: 'Change Codename',
                                                onPressed:
                                                    _showChangeNicknameDialog,
                                              ),
                                            if (!isCurrentUser)
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                color: Colors.red,
                                                tooltip: 'Kick Agent',
                                                onPressed: () =>
                                                    _kickPlayer(player.userId),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Bottom Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: CyberpunkButton(
                                      onPressed: _toggleReady,
                                      label:
                                          _isReady ? 'STAND DOWN' : 'READY UP',
                                      icon:
                                          _isReady ? Icons.cancel : Icons.check,
                                      color: _isReady
                                          ? const Color(0xFFFF0000)
                                          : const Color(0xFF00FF00),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (room.status == 'countdown')
                        Stack(
                          children: [
                            _CountdownOverlay(seconds: _countdown),
                            Positioned(
                              bottom: 100,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: CyberpunkButton(
                                  onPressed: () async {
                                    try {
                                      await AppwriteService()
                                          .updateRoomStatus(room.id, 'waiting');
                                    } catch (e) {
                                      print('Error canceling countdown: $e');
                                    }
                                  },
                                  label: 'CANCEL COUNTDOWN',
                                  icon: Icons.cancel,
                                  color: const Color(0xFFFF0000),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  int _getReadyCount(List<User> players) {
    return players.where((p) => p.isReady).length;
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? const Color(0xFF00FFFF),
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    (color ?? const Color(0xFF00FFFF)).withValues(alpha: 0.7),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color ?? const Color(0xFF00FFFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  final int seconds;

  const _CountdownOverlay({required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MISSION STARTING IN',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 20,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$seconds',
              style: const TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
