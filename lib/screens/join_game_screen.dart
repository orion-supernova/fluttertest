import 'package:flutter/material.dart';
import '../widgets/cyberpunk_widgets.dart';
import 'package:flutter/services.dart';
import '../services/appwrite_service.dart';
import 'game_lobby_screen.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _roomCode = '';
  late AnimationController _scanlineController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _scanlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: const Color(0xFF00FFFF),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Scanline effect
            AnimatedBuilder(
              animation: _scanlineController,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height *
                      _scanlineController.value,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF00FFFF).withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top section with icon and title
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          border: Border.all(
                              color: const Color(0xFF00FFFF)
                                  .withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FFFF)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  const Color(0xFF00FFFF),
                                  const Color(0xFF00FFFF)
                                      .withValues(alpha: 0.5),
                                ],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.vpn_key_outlined,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ACCESS TERMINAL',
                              style: TextStyle(
                                color: Color(0xFF00FFFF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter operation code to join',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Operation code input
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          border: Border.all(
                            color:
                                const Color(0xFFFF00FF).withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF00FF)
                                  .withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CyberpunkTextField(
                              label: 'OPERATION CODE',
                              onChanged: (value) =>
                                  _roomCode = value.toUpperCase(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Operation code required';
                                }
                                if (value.length != 5) {
                                  return 'Code must be 5 characters';
                                }
                                return null;
                              },
                              icon: Icons.code,
                            ),
                            const SizedBox(height: 24),
                            CyberpunkButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() => _isLoading = true);
                                        HapticFeedback.lightImpact();

                                        try {
                                          // Check if room exists
                                          final room = await AppwriteService()
                                              .getRoom(_roomCode);

                                          if (room == null) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Operation not found'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                            return;
                                          }

                                          // Join the room
                                          await AppwriteService()
                                              .joinRoom(room.id);

                                          if (mounted) {
                                            await Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    GameLobbyScreen(room: room),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error joining operation: $e'),
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
                                    },
                              label: 'ACCESS OPERATION',
                              icon: Icons.login,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
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
