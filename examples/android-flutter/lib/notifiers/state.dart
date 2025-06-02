import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  Map<String, dynamic>? token;
  String? oauthVerifier;
  String? oauthState;
}
