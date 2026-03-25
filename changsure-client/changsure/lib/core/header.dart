import 'package:changsure/state/bottom_subpage_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/bottom_nav_provider.dart';

class Header extends ConsumerWidget {
  final String header;
  final VoidCallback? onPressed;
  final double? fontSize;
  final Color? color;
  final Color? iconColor;

  const Header({super.key, required this.header, this.onPressed,  this.fontSize, this.color, this.iconColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor ?? Colors.black, size: 30,),
            onPressed:
                onPressed ??
                () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                    return;
                  }

                  final prev = ref
                      .read(bottomSubPageHistoryProvider.notifier)
                      .pop();

                  ref.read(bottomSubPageProvider.notifier).state = prev;
                },
          ),
          Expanded(
            child: Center(
              child: Text(
                header,
                style: TextStyle(
                  fontSize: fontSize ?? 16,
                  fontWeight: FontWeight.bold,
                  color: color ?? Color(0xFF004AAD),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
