import 'package:flutter/material.dart';

class RouteProvider extends ChangeNotifier {
  static final RouteProvider _instance = RouteProvider._();
  static RouteProvider get instance => _instance;

  String _currentRoute = '/home';
  String get currentRoute => _currentRoute;

  RouteProvider._();

  void setCurrentRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }
}
