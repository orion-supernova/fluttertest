import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/services.dart';
import 'screens/create_game_screen.dart';
import 'screens/join_game_screen.dart';
import 'services/appwrite_service.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appwrite = AppwriteService();
  await appwrite.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(appwrite),
      child: const UndercoverApp(),
    ),
  );
}

class UndercoverApp extends StatelessWidget {
  const UndercoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnderCover: A Spy\'s Tale',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF00FF),
          secondary: Color(0xFF00FFFF),
        ),
      ),
      home: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.error != null) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error initializing app'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => userProvider.retryInitialization(),
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (userProvider.isLoading || !userProvider.isLoggedIn) {
            return const LoadingScreen();
          }

          return const HomeScreen();
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final Random _random = Random();
  final List<GlitchOffset> _glitchOffsets = [];
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Faster, more visible glitch effect
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      setState(() {
        if (_glitchOffsets.isEmpty && _random.nextDouble() > 0.7) {
          _glitchOffsets.add(GlitchOffset(
            dx: 0,
            dy: 0,
            opacity: 0.7,
          ));
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() => _glitchOffsets.clear());
            }
          });
        }
      });
    });

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Cyberpunk grid background
          CustomPaint(
            painter: CyberpunkGridPainter(),
            size: Size.infinite,
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with glitch effect - adjusted size and spacing
                  _GlitchText(
                    'UNDER\nCOVER',
                    style: const TextStyle(
                      fontSize: 52, // Increased size
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      height: 0.85,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFFF).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF00FFFF).withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'A SPY\'S TALE or FALL',
                      style: TextStyle(
                        fontSize: 14, // Reduced from 16
                        letterSpacing: 4,
                        color: Color(0xFF00FFFF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Cyberpunk buttons
                  _CyberpunkButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateGameScreen(),
                        ),
                      );
                    },
                    icon: Icons.add_circle_outline,
                    label: 'INITIATE MISSION',
                    color: const Color(0xFFFF00FF),
                  ),
                  const SizedBox(height: 16),
                  _CyberpunkButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const JoinGameScreen(),
                        ),
                      );
                    },
                    icon: Icons.group_outlined,
                    label: 'JOIN OPERATION',
                    color: const Color(0xFF00FFFF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberpunkButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _CyberpunkButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  State<_CyberpunkButton> createState() => _CyberpunkButtonState();
}

class _CyberpunkButtonState extends State<_CyberpunkButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..scale(_isPressed
                ? 0.95
                : _isHovered
                    ? 1.02
                    : 1.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: widget.color,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: _isHovered ? 20 : 10,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.color,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlitchText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _GlitchText(this.text, {required this.style});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeScreenState>()!;

    return Stack(
      children: [
        // Base text
        Text(
          text,
          style: style.copyWith(
            color: Colors.white,
            shadows: [
              Shadow(
                color: const Color(0xFF00FFFF),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        // Glitch layers
        if (state._glitchOffsets.isNotEmpty) ...[
          // Cyan glitch
          Transform.translate(
            offset: Offset(3, -3),
            child: Text(
              text,
              style: style.copyWith(
                color: const Color(0xFF00FFFF).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Pink glitch
          Transform.translate(
            offset: Offset(-3, 3),
            child: Text(
              text,
              style: style.copyWith(
                color: const Color(0xFFFF00FF).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}

class CyberpunkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CyberpunkGridPainter oldDelegate) => false;
}

class GlitchPainter extends CustomPainter {
  final Animation<double> animation;
  final Random random;

  GlitchPainter({required this.animation, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    if (random.nextDouble() > 0.9) {
      final paint = Paint()
        ..color = const Color(0xFFFF00FF).withOpacity(0.1)
        ..style = PaintingStyle.fill;

      final height = size.height * 0.1;
      final top = random.nextDouble() * size.height;

      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width, height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GlitchPainter oldDelegate) => true;
}

class GlitchOffset {
  final double dx;
  final double dy;
  final double opacity;

  GlitchOffset({
    required this.dx,
    required this.dy,
    required this.opacity,
  });
}
