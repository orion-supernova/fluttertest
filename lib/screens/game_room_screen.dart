import 'package:flutter/material.dart';
import '../models/room.dart';
import '../services/appwrite_service.dart';
import 'game_lobby_screen.dart';

class GameRoomScreen extends StatefulWidget {
  final Room room;

  const GameRoomScreen({super.key, required this.room});

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen> {
  late final Stream<Room> _roomStream;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    _roomStream = AppwriteService().subscribeToRoom(widget.room.id);
  }

  Future<void> _endGame() async {
    try {
      await AppwriteService().updateRoomStatus(widget.room.id, 'waiting');
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: StreamBuilder<Room>(
        stream: _roomStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final room = snapshot.data!;

            // Navigate back to lobby if status changes to waiting
            if (room.status == 'waiting') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameLobbyScreen(room: room),
                  ),
                );
              });
            }
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('Game Room: ${widget.room.roomCode}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.stop_circle),
                  color: Colors.red,
                  tooltip: 'End Game',
                  onPressed: _endGame,
                ),
              ],
            ),
            body: const Center(
              child: Text('Game Room Screen - Coming Soon!'),
            ),
          );
        },
      ),
    );
  }
}
