import 'package:flutter/material.dart';

class AppLang extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;
  bool get isTamil => _locale.languageCode == 'ta';

  void toggle() {
    _locale = isTamil ? const Locale('en') : const Locale('ta');
    notifyListeners();
  }

  void setTamil() {
    _locale = const Locale('ta');
    notifyListeners();
  }

  void setEnglish() {
    _locale = const Locale('en');
    notifyListeners();
  }
}