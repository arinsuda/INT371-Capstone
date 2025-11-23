import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/bottomBarState.dart';

class HistoryServicePage extends StatelessWidget {
  const HistoryServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            // ---------- Header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).closeSubPage(),
                  },
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "ประวัติการรับบริการ",
                      style: TextStyle(
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
