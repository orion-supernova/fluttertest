import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CyberpunkTextField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final IconData? icon;
  final String? initialValue;
  final Widget? suffix;
  final bool readOnly;

  const CyberpunkTextField({
    required this.label,
    required this.onChanged,
    this.validator,
    this.icon,
    this.initialValue,
    this.suffix,
    this.readOnly = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          readOnly: readOnly,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black26,
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: const Color(0xFF00FFFF),
                    size: 20,
                  )
                : null,
            suffixIcon: suffix,
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00FFFF),
                width: 1,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFFF00FF),
                width: 2,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CyberpunkButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  const CyberpunkButton({
    required this.onPressed,
    required this.label,
    this.icon,
    super.key,
  });

  @override
  State<CyberpunkButton> createState() => _CyberpunkButtonState();
}

class _CyberpunkButtonState extends State<CyberpunkButton> {
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
          HapticFeedback.heavyImpact();
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
              color: Colors.black26,
              border: Border.all(
                color: const Color(0xFF00FFFF),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.3),
                  blurRadius: _isHovered ? 20 : 10,
                  spreadRadius: _isHovered ? 2 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: const Color(0xFF00FFFF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Color(0xFF00FFFF),
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
