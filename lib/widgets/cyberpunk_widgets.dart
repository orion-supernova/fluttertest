import 'package:flutter/material.dart';

class CyberpunkTextField extends StatefulWidget {
  final String label;
  final String? value;
  final bool readOnly;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextEditingController? controller;

  const CyberpunkTextField({
    super.key,
    required this.label,
    this.value,
    this.readOnly = false,
    this.onChanged,
    this.validator,
    this.icon,
    this.controller,
  });

  @override
  State<CyberpunkTextField> createState() => _CyberpunkTextFieldState();
}

class _CyberpunkTextFieldState extends State<CyberpunkTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      // Only dispose if we created the controller
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only update text if we're not using a provided controller
    if (widget.controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.text != widget.value) {
          _controller.text = widget.value ?? '';
        }
      });
    }

    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: const TextStyle(
        color: Color(0xFF00FFFF),
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: const Color(0xFF00FFFF).withOpacity(0.7),
          letterSpacing: 2,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFF00FFFF).withOpacity(0.3),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF00FFFF),
          ),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF00FF),
          ),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFFFF00FF),
          ),
        ),
        prefixIcon: widget.icon != null
            ? Icon(
                widget.icon,
                color: const Color(0xFF00FFFF),
              )
            : null,
      ),
    );
  }
}

class CyberpunkButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? color;

  const CyberpunkButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? const Color(0xFFFF00FF);

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 20),
        side: BorderSide(
          color: buttonColor,
          width: 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: buttonColor,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: buttonColor,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: buttonColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
    );
  }
}
