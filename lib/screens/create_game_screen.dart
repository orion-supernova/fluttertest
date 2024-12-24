import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/cyberpunk_widgets.dart';
import 'dart:math';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  String _roomName = '';
  int _playerCount = 3;
  static const int _minPlayers = 3;
  static const int _maxPlayers = 12;

  String _generateOperationCode() {
    const chars =
        '123456789ABCDEFGHIJKLMNPQRSTUVWXYZ'; // Excluding O and 0 to avoid confusion
    final random = Random();
    final codeLength = 5;

    return List.generate(codeLength, (index) {
      return chars[random.nextInt(chars.length)];
    }).join();
  }

  @override
  void initState() {
    super.initState();
    _roomName = _generateOperationCode();
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.security,
              color: Color(0xFF00FFFF),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'MISSION SETUP',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission briefing section
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MISSION BRIEFING',
                          style: TextStyle(
                            color: Color(0xFFFF00FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CyberpunkTextField(
                          label: 'OPERATION CODE',
                          onChanged: (_) {}, // No-op since it's read-only
                          initialValue: _roomName,
                          icon: Icons.code,
                          readOnly: true, // Make it read-only
                          suffix: IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF00FFFF),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _roomName = _generateOperationCode();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Parameters section
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          'OPERATION PARAMETERS',
                          style: TextStyle(
                            color: Color(0xFF00FFFF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Player count selector
                        Row(
                          children: [
                            const Icon(
                              Icons.group_outlined,
                              color: Color(0xFF00FFFF),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'AGENT COUNT',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      border: Border.all(
                                        color: const Color(0xFF00FFFF),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildCounterButton(
                                          icon: Icons.remove,
                                          onPressed: () {
                                            if (_playerCount > _minPlayers) {
                                              setState(() => _playerCount--);
                                            }
                                          },
                                          disabled: _playerCount <= _minPlayers,
                                        ),
                                        Text(
                                          '$_playerCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        _buildCounterButton(
                                          icon: Icons.add,
                                          onPressed: () {
                                            if (_playerCount < _maxPlayers) {
                                              setState(() => _playerCount++);
                                            }
                                          },
                                          disabled: _playerCount >= _maxPlayers,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CyberpunkButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                              SizedBox(width: 16),
                              Text('Initializing operation...'),
                            ],
                          ),
                          backgroundColor: Color(0xFF00FFFF),
                        ),
                      );
                    },
                    label: 'INITIATE OPERATION',
                    icon: Icons.launch,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool disabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            color: disabled
                ? const Color(0xFF00FFFF).withOpacity(0.3)
                : const Color(0xFF00FFFF),
            size: 20,
          ),
        ),
      ),
    );
  }
}
