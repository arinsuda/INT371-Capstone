import 'package:flutter/material.dart';

class BottomBarState with ChangeNotifier {
  int _selectedIndex = 0;
  Widget? _currentSubPage;

  int get selectedIndex => _selectedIndex;
  Widget? get currentSubPage => _currentSubPage;

  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void setSubPage(Widget page) {
    _currentSubPage = page;
    notifyListeners();
  }

  void closeSubPage() {
    _currentSubPage = null;
    notifyListeners();
  }
}
