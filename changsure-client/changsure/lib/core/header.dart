import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/bottom_bar_state.dart'; 

class Header extends StatelessWidget {
  final String header;
  final VoidCallback? onPressed;

  const Header({super.key, required this.header, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed:
                onPressed ??
                () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.read<BottomBarState>().closeSubPage();
                  }
                },
          ),

          // 🏷 ชื่อ Header ตรงกลาง
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

          // เพื่อให้ปุ่มซ้าย-ขวาสมดุลกัน
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
