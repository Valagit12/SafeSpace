import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class APIService {

  final String url = "valarezaarezehgar.pythonanywhere.com/";

  Future<bool> subscribe(String token) async {
    final body = jsonEncode({
      'token': token
    });
    final response = await http.post(
      Uri.parse("http://valarezaarezehgar.pythonanywhere.com/subscribe"), 
      body: body, 
      headers: { 'Content-Type': 'application/json' }
    );

    return response.statusCode == 200;
  }

  Future<bool> requestHelp(LatLng currLoc, String token) async {
    final body = jsonEncode({
      "sender_token": token,
      "notification": {
          "body": "SOMEONE NEAR YOU REQUESTED HELP",
          "title": "SOS"
      },
      "data": {
          "lat": currLoc.latitude.toString(),
          "long": currLoc.longitude.toString()
      }
    });
    final response = await http.post(
      Uri.parse("http://valarezaarezehgar.pythonanywhere.com/receive_signal"), 
      body: body,
      headers: { 'Content-Type': 'application/json' }
    );

    return response.statusCode == 200;
  }
}