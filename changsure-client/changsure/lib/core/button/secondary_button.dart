import 'package:flutter/material.dart';
import 'package:changsure/core/theme.dart';

class SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;


  // --- ใหม่ ---
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.fontSize = 16, // default
    this.padding = const EdgeInsets.symmetric(vertical: 14), // default
    this.borderRadius = 10, // default
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
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
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
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
                          AppColors.primaryBG.withOpacity(0.8),
                          AppColors.primaryBG,
                        ]
                      : [
                          AppColors.primaryBG.withOpacity(0.8),
                          AppColors.primaryBG,
                        ],
                  stops: const [0.12, 1.0],
                ),
          color: isDisabled
              ? AppColors.primaryBGHover
              : AppColors.primaryBorder,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.secondary, width: 1),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: widget.fontSize + 2,
                    color: isDisabled
                        ? AppColors.primaryBorder
                        : AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: isDisabled
                        ? AppColors.primaryBorder
                        : AppColors.secondary,
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
