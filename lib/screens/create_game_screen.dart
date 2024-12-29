import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/appwrite_service.dart';
import '../widgets/cyberpunk_widgets.dart';
import 'game_lobby_screen.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _roomCode;
  int _playerCount = 3;
  bool _isLoading = false;
  static const int _minPlayers = 3;
  static const int _maxPlayers = 12;

  // Initialize controller immediately
  late final AnimationController _gridController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _generateRoomCode() async {
    setState(() => _isLoading = true);

    try {
      // Generate a 5-character code
      const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final random = Random.secure();
      final code =
          List.generate(5, (index) => chars[random.nextInt(chars.length)])
              .join();

      // Check if code exists
      final exists = await AppwriteService().checkRoomExists(code);
      if (exists) {
        return _generateRoomCode(); // Try again if exists
      }

      setState(() => _roomCode = code);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error generating code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCreateRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roomCode == null || _roomCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate a room code first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if room exists first
      final exists = await AppwriteService().checkRoomExists(_roomCode!);
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Room code already exists. Please generate a new one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create and join room if code is unique
      final room = await AppwriteService().createAndJoinRoom(
        roomCode: _roomCode!,
        maxPlayers: _playerCount,
      );

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GameLobbyScreen(room: room),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error creating room: $e')),
              ],
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: const Color(0xFFFF00FF),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Stack(
          children: [
            // Animated grid background
            AnimatedBuilder(
              animation: _gridController,
              builder: (context, child) {
                return CustomPaint(
                  painter: CyberpunkGridPainter(animation: _gridController),
                  size: Size.infinite,
                );
              },
            ),
            // Rest of your content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          border: Border.all(
                            color: const Color(0xFFFF00FF).withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF00FF).withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.security,
                              size: 48,
                              color: Color(0xFFFF00FF),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'WELCOME, ${user?.nickname ?? 'AGENT'}',
                              style: const TextStyle(
                                color: Color(0xFFFF00FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Room Settings
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          border: Border.all(
                            color: const Color(0xFF00FFFF).withOpacity(0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF).withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OPERATION SETTINGS',
                              style: TextStyle(
                                color: Color(0xFF00FFFF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CyberpunkTextField(
                                    label: 'ROOM CODE',
                                    value: _roomCode,
                                    readOnly: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Generate a room code';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  color: const Color(0xFF00FFFF),
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          _generateRoomCode();
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'AGENTS:',
                                  style: TextStyle(
                                    color: Color(0xFF00FFFF),
                                    letterSpacing: 2,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      color: const Color(0xFF00FFFF),
                                      onPressed: _playerCount > _minPlayers
                                          ? () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _playerCount--);
                                            }
                                          : null,
                                    ),
                                    Text(
                                      '$_playerCount',
                                      style: const TextStyle(
                                        color: Color(0xFF00FFFF),
                                        fontSize: 20,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      color: const Color(0xFF00FFFF),
                                      onPressed: _playerCount < _maxPlayers
                                          ? () {
                                              HapticFeedback.lightImpact();
                                              setState(() => _playerCount++);
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      CyberpunkButton(
                        onPressed:
                            (_roomCode?.isNotEmpty == true && !_isLoading)
                                ? _handleCreateRoom
                                : null,
                        label: 'INITIATE OPERATION',
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CyberpunkGridPainter extends CustomPainter {
  final Animation<double>? animation;

  CyberpunkGridPainter({this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    // Main grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw glowing dots at intersections
    final dotPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 60) {
      for (double y = 0; y < size.height; y += 60) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }

    // Draw some random "data streams"
    final streamPaint = Paint()
      ..color = const Color(0xFFFF00FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final random = Random();
    for (int i = 0; i < 5; i++) {
      final path = Path();
      var x = random.nextDouble() * size.width;
      path.moveTo(x, 0);

      for (double y = 0; y < size.height; y += 20) {
        x += (random.nextDouble() - 0.5) * 40;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, streamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CyberpunkGridPainter oldDelegate) =>
      animation?.value != oldDelegate.animation?.value;
}
