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
//   exit(1);a
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
  // final TextEditingController _controller = TextEditingController();
  final TextEditingController _eventFrequencyController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _volunteerNamesController = TextEditingController();
  String _response = '';
  bool _loading = false;

  Future<void> _callGeminiApi(String eventFrequency, String startDate, String endDate, List<String> volunteerNames) async {
    setState(() {
      _loading = true;
    });

    try {
        // Construct the prompt using user inputs
        String prompt = '''
          Can you create a roster for the following volunteering event? 

          Event Frequency: $eventFrequency
          Start Date: $startDate
          End Date: $endDate
          Volunteer Names: ${volunteerNames.join(', ')}

          Try to do equal distributions. Respond with ONLY a JSON as output and no other explanation.
        ''';
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Automated roster creation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _eventFrequencyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Event Frequency',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _startDateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Start Date',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _endDateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'End Date',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _volunteerNamesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Volunteer Names (comma separated)',
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : () {
                // Convert comma-separated names into a list
                List<String> volunteerNames = _volunteerNamesController.text.split(',').map((name) => name.trim()).toList();

                _callGeminiApi(
                  _eventFrequencyController.text,
                  _startDateController.text,
                  _endDateController.text,
                  volunteerNames
                );
              },
              child: _loading ? CircularProgressIndicator() : Text('Send'),
            ),
            SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseDisplayBox(response: _response),
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
            sheet.getRangeByIndex(row, keysList.length + 1).setText('$key');
            sheet.getRangeByIndex(row, keysList.length + 2).setText(value.toString());

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