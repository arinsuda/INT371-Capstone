import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Stack(
          children: [
            // Gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _isPressed
                      ? [
                    AppColors.secondary.withOpacity(0.8),
                    AppColors.secondary,
                  ]
                      : [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                  ],
                  stops: [0.12, 1.0],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Stroke ขาวจาง 12%
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 2,
                ),
              ),
            ),
            // Text
            Center(
              child: Text(
                widget.text,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
