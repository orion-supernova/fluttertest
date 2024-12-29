import 'package:flutter/material.dart';
import '../models/room.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class GameRoomScreen extends StatelessWidget {
  final Room room;

  const GameRoomScreen({
    required this.room,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user!;
    final isHost = room.hostId == user.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${room.roomCode}'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: ${room.status}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Players (${room.playerIds.length}/${room.maxPlayers}):',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: room.playerIds.length,
                itemBuilder: (context, index) {
                  final playerId = room.playerIds[index];
                  final isCurrentUser = playerId == user.userId;
                  return ListTile(
                    title: Text(
                      isCurrentUser
                          ? '${user.nickname} (You)'
                          : 'Player $playerId',
                    ),
                    trailing: isCurrentUser
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  );
                },
              ),
            ),
            if (isHost)
              ElevatedButton(
                onPressed: room.playerIds.length >= room.minPlayers
                    ? () {
                        // TODO: Start game
                      }
                    : null,
                child: const Text('Start Game'),
              ),
          ],
        ),
      ),
    );
  }
}
