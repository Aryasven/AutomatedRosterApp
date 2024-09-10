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
// import 'package:excel/excel.dart';

// const apiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?';
const apikey = 'AIzaSyCk3FI25_MTfUzrbvgYHKauG-y_Dacobt4';

// Access your API key as an environment variable (see "Set up your API key" above)
final apiKey = apikey; //Platform.environment['API_KEY'];
// if (apiKey == null) {
//   print('No \$API_KEY environment variable');
//   exit(1);
// }

final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: apiKey,
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini API Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _loading = false;

  Future<void> _callGeminiApi(String prompt) async {
    setState(() {
      _loading = true;
    });

    try {
        prompt = "Can you create a roster for me from a list of 10 names for every sunday, starting september 8th, to december end.  There are 3 roles every sunday (09:00 am, 11:00am and 05:00pm). Try to do equal distributions. Make up your names for now. Respond with ONLY a json as output and no other explanation.";
        final response = await model.generateContent([Content.text(prompt)]);
        String responseBody = response.text!;
        // Display the response on the webpage
        setState(() {
          _response = responseBody.replaceAll("```json", "").replaceAll("```","");
        });

        // Save the response to a JSON file
        await _writeJsonToExcel();
      // } else {
      //   setState(() {
      //     _response = 'Failed to get a response from Gemini API. Status code: ${response.statusCode}\nResponse body: ${response.body}';
      //   });
      // }
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveResponseToFile(dynamic responseBody) async {
    // DartPluginRegistrant.ensureInitialized();
    // WidgetsFlutterBinding.ensureInitialized();
    var path = "/assets";
    if (!kIsWeb) {
      var directory = await getApplicationDocumentsDirectory();
      path = directory.path;
    }
    // final directory = await getApplicationDocumentsDirectory();
    final filePath = '${path}/response.json';
    final file = File(filePath);

    try {
      await file.writeAsString(jsonEncode(responseBody));
      setState(() {
        _response += '\n\nResponse saved to: $filePath';
      });
    } catch (e) {
      setState(() {
        _response += '\n\nError saving response: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini API Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter your prompt',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : () {
                _callGeminiApi(_controller.text);
              },
              child: _loading ? CircularProgressIndicator() : Text('Send'),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _writeJsonToExcel() async {
    try {
      // Step 1: Extract the JSON part from the response
      String jsonString = _response;
// 
      // Step 2: Parse the JSON string
      //var parsedJson = json.decode(jsonString);
      var tableData = json.decode(jsonString); //parsedJson['table'];

      // Step 3: Create a new Excel document using Syncfusion XlsIO
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      int row=1;
          // Recursive function to traverse the nested map
      void traverseAndWrite(Map<dynamic, dynamic> map, String currentPath) {
        map.forEach((key, value) {
          if (value is Map) {
            // If the value is a map, go deeper recursively
            traverseAndWrite(value, currentPath.isEmpty ? '$key' : '$currentPath | $key');
          } else {
            // Otherwise, write the current path and value to Excel
            // Split the fullPath into a list of keys
            List<String> keysList = currentPath.split('|');
            // Iterate over the list of keys and set the corresponding Excel columns
            for (int i = 0; i < keysList.length; i++) {
              sheet.getRangeByIndex(row, i + 1).setText(keysList[i].trim());
            }
            // Set the last column to the value
            sheet.getRangeByIndex(row, keysList.length + 1).setText(value.toString());

            row++;
          }
        });
      }

      // Start traversing the nested map
      traverseAndWrite(tableData, '');

      // Step 6: Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/gemini_output_v2.xlsx';
      final List<int> bytes = workbook.saveAsStream();
      File(filePath).writeAsBytesSync(bytes);

      // Step 7: Dispose of the workbook
      workbook.dispose();

      // Show success message
      setState(() {
        _response = 'Excel file created successfully at: $filePath';
      });
    } catch (e) {
      setState(() {
        _response = 'Error: $e';
      });
    }
  }
}

class ResponseDisplayBox extends StatelessWidget {
  final String response;

  ResponseDisplayBox({required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
        // border: Border.all(color: Colors.grey[400]!),
      ),
      child: Text(
        response.isEmpty ? 'No response yet' : response,
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}

/// Function to find the depth (layers) of a nested map.
int findMapDepth(Map<dynamic, dynamic> map) {
  int maxDepth = 1;

  for (var value in map.values) {
    if (value is Map) {
      // Recursively find the depth of the nested map and compare it to maxDepth
      int currentDepth = 1 + findMapDepth(value);
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }
    }
  }
  return maxDepth;
}

/// Function to flatten a nested map
Map<dynamic, dynamic> flattenMap(Map<dynamic, dynamic> map, [String prefix = '']) {
  Map<dynamic, dynamic> flatMap = {};

  map.forEach((key, value) {
    if (value is Map) {
      // Recursively flatten the map and append keys
      flatMap.addAll(flattenMap(value, '$prefix$key.'));
    } else {
      // Add non-map values to flatMap with the full key path
      flatMap['$prefix$key'] = value;
    }
  });

  return flatMap;
}

