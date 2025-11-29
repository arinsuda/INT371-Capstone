import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/bottom_bar_state.dart';

class Header extends StatelessWidget {
  final String header;
  final VoidCallback? onPressed; // 👈 เพิ่ม callback

  const Header({
    super.key,
    required this.header,
    this.onPressed, // 👈 optional
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: onPressed ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // กลับด้วย Navigator
                      } else {
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).closeSubPage(); // กลับด้วย BottomBarState
                      }
                },
          ),
          Expanded(
            child: Center(
              child: Text(
                header,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004AAD),
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
