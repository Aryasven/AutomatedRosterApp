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
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart'; // Add this for permissions

// const apiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?';
const apikey = 'AIzaSyCk3FI25_MTfUzrbvgYHKauG-y_Dacobt4';
final apiKey = apikey; //Platform.environment['API_KEY'];


final model = GenerativeModel(
  model: 'gemini-1.5-flash',
  apiKey: apiKey,
);

class CreateRosterPage extends StatefulWidget {
  @override
  _CreateRosterPageState createState() => _CreateRosterPageState();
}

class _CreateRosterPageState extends State<CreateRosterPage> {
  // final TextEditingController _controller = TextEditingController();
  final TextEditingController _eventFrequencyController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _volunteerNamesController = TextEditingController();
  final TextEditingController _assignNoOfVolunteers = TextEditingController();
  String _response = '';
  String _response_save = '';
  bool _loading = false;

  Future<void> _callGeminiApi(String eventFrequency, String startDate, String endDate, List<String> volunteerNames, String numVolunteers) async {
    setState(() {
      _loading = true;
    });

    try {
        // Construct the prompt using user inputs
        String prompt = '''
          Can you create a roster for the following volunteering event? 

          Event Details: $eventFrequency
          Start Date: $startDate
          End Date: $endDate
          Volunteer Names: ${volunteerNames.join(', ')}
          No of volunteers needed per event: $numVolunteers

          Try to do equal distributions. 
          Respond with list of dictionaries, one for each row. The keys should be all required headers of the table.
          Dont give any other explanation.
        ''';
        final response = await model.generateContent([Content.text(prompt)]);
        String responseBody = response.text!;
        // Display the response on the webpage
        setState(() {
          _response = responseBody.replaceAll("```json", "").replaceAll("```","");
        });

        // Save the response to a JSON file
        // await _writeJsonToExcel(_response);
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
                labelText: 'Event details such as timings, venues etc.',
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
                        TextField(
              controller: _assignNoOfVolunteers,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'No. of volunteers needed per event',
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
                  volunteerNames,
                  _assignNoOfVolunteers.text
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
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : () {
                _writeJsonToExcel(_response);
              },
              child: _loading ? CircularProgressIndicator() : Text('Roster generated. Save roster to file'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ResponseDisplayBox(response: _response_save),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _writeJsonToExcel(response) async {
    try {
      // Step 1: Extract the JSON part from the response
      String jsonString = response;
// 
      // Step 2: Parse the JSON string
      //var parsedJson = json.decode(jsonString);
      List tableData = json.decode(jsonString); //parsedJson['table'];

      // if (tableData is! Map) {
      //   throw Exception('Expected JSON data to be a map.');
      // }

      // Step 3: Create a new Excel document using Syncfusion XlsIO
      final xlsio.Workbook workbook = xlsio.Workbook();
      final xlsio.Worksheet sheet = workbook.worksheets[0];

      int row=1;
          // Recursive function to traverse the nested map
      traverseAndWrite(List jsonData, xlsio.Worksheet sheet) {
        if (jsonData is List && jsonData.isNotEmpty && jsonData.first is Map) {
          // Step 4: Write headers based on the first item in the list (dynamic keys)
          Map<String, dynamic> firstItem = jsonData.first;
          int column = 1;

          // Write headers (keys)
          firstItem.keys.forEach((key) {
            sheet.getRangeByIndex(1, column).setText(key);
            column++;
          });

          // Step 5: Write data rows
          for (int row = 0; row < jsonData.length; row++) {
            Map<String, dynamic> currentItem = jsonData[row];
            column = 1;

            currentItem.forEach((key, value) {
              sheet.getRangeByIndex(row + 2, column).setText(value.toString());
              column++;
            });
          }
        }
        return sheet;
      }

      // Start traversing the nested map
      traverseAndWrite(tableData, sheet);

      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/gemini_output_v3.xlsx';
      final List<int> bytes = workbook.saveAsStream();
      File(filePath).writeAsBytesSync(bytes);
      

      String filePath2 = '/storage/emulated/0/Download/gemini_output_v3.xlsx'; //'${directory.path}/gemini_output_v3.xlsx';
      final List<int> bytes2 = workbook.saveAsStream();
      File(filePath2).writeAsBytesSync(bytes2);
      _response_save = 'Excel file created successfully at: $filePath2';
      // Show success message

    } catch (e) {
      setState(() {
        print('Error: $e');
        _response_save = 'Error: $e';
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