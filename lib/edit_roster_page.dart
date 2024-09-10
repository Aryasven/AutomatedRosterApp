import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

// import 'package:permission_handler/permission_handler.dart'; // Add this for permissions

// const apiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?';
const apikey = 'AIzaSyCk3FI25_MTfUzrbvgYHKauG-y_Dacobt4';
final apiKey = apikey; //Platform.environment['API_KEY'];


final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: apiKey,
);


class EditRosterPage extends StatefulWidget {
  @override
  _EditRosterPageState createState() => _EditRosterPageState();
}

class _EditRosterPageState extends State<EditRosterPage> {
  // Add controllers and other necessary variables here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Existing Roster'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add your widgets here for editing a roster
          ],
        ),
      ),
    );
  }
}
