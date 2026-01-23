import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class ErrorButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;

  // --- ใหม่ ---
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const ErrorButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16, // default
    this.padding = const EdgeInsets.symmetric(vertical: 14), // default
    this.borderRadius = 10, // default
  });

  @override
  State<ErrorButton> createState() => _ErrorButtonState();
}

class _ErrorButtonState extends State<ErrorButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    return
      GestureDetector(
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
                Color(0xFF5F222D),
                Color(0xFF5F222D),
              ]
                  : [
                Color(0xFF5F222D),
                Color(0xFF5F222D),
              ],
              stops: const [0.12, 1.0],
            ),
            color: isDisabled ? AppColors.primaryBorder : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Color(0xFF5F222D),
              width: 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Text
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.fontSize,
                  color:
                  isDisabled ? AppColors.primaryBorder : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      );
  }
}
