import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  // --- ใหม่ ---
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16, // default
    this.padding = const EdgeInsets.symmetric(vertical: 14), // default
    this.borderRadius = 10, // default
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
        setState(() => _isPressed = false);
        widget.onPressed!();
      },
      onTapCancel:
      isDisabled ? null : () => setState(() => _isPressed = false),
      child: Container(
        padding: widget.padding, // ← ใช้ padding ที่ส่งเข้ามา
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isPressed
                ? [
              AppColors.secondary.withOpacity(0.8),
              AppColors.secondary,
            ]
                : [
              Color(0xFF003EB3).withOpacity(0.8),
              Color(0xFF003EB3),
            ],
            stops: const [0.12, 1.0],
          ),
          color: isDisabled ? AppColors.primaryBGHover : AppColors.primaryBGHover,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // // Stroke
            // Container(
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(widget.borderRadius),
            //     border: Border.all(
            //       color: Colors.white.withOpacity(0.12),
            //       width: 2,
            //     ),
            //   ),
            // ),

            // Text
            Text(
              widget.text,
              style: TextStyle(
                fontSize: widget.fontSize, // ← fontSize จากผู้ใช้
                color:
                isDisabled ? AppColors.primaryBorder : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
