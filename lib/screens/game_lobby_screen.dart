import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/appwrite_service.dart';
import '../widgets/cyberpunk_widgets.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'dart:async';

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
    WidgetsBinding.instance.removeObserver(this);
    if (_isReady) {
      await _setNotReady();
      print('SetNotReady completed in dispose');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.paused && !_isSettingReady) {
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
    } catch (e) {
      print('Error toggling ready state: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().user;
    final isHost = currentUser?.userId == widget.room.hostId;

    return WillPopScope(
      onWillPop: () async {
        print('WillPopScope triggered');
        await _setNotReady();
        return true;
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
                onPressed: () async {
                  print('Back button pressed');
                  await _setNotReady();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
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
          child: StreamBuilder<List<User>>(
            stream: _playersStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
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

              return SafeArea(
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
                            color:
                                const Color(0xFF00FFFF).withValues(alpha: 0.5),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            if (widget.room.minPlayers > players.length) ...[
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
                                          decoration: const BoxDecoration(
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
                              label: _isReady ? 'STAND DOWN' : 'READY UP',
                              icon: _isReady ? Icons.cancel : Icons.check,
                              color: _isReady
                                  ? const Color(0xFFFF0000)
                                  : const Color(0xFF00FF00),
                            ),
                          ),
                          if (isHost) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: CyberpunkButton(
                                onPressed: _allPlayersReady(players) &&
                                        players.length >= widget.room.minPlayers
                                    ? () {
                                        // Start game logic
                                        HapticFeedback.heavyImpact();
                                      }
                                    : null,
                                label: 'START MISSION',
                                icon: Icons.play_arrow,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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

  bool _allPlayersReady(List<User> players) {
    return players.every((p) => p.isReady) &&
        players.length >= widget.room.minPlayers;
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
