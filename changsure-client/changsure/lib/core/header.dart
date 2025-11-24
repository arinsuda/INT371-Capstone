import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/bottomBarState.dart';

class Header extends StatelessWidget {
  final String header;

  const Header({super.key, required this.header});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Provider.of<BottomBarState>(
                context,
                listen: false,
              ).closeSubPage();
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
