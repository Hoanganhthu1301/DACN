// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

Future<void> sendComment(String foodId, String text) async {
  final token = await FirebaseAuth.instance.currentUser!.getIdToken();

  final res = await http.post(
    Uri.parse(
      'https://asia-southeast1-goiymonan-e8fba.cloudfunctions.net/api/comments',
    ),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: json.encode({"foodId": foodId, "text": text}),
  );

  debugPrint(res.body);
}
