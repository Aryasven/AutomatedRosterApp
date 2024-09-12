import 'package:flutter/material.dart';
import 'create_roster_page.dart'; 
import 'edit_roster_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Roster Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateRosterPage()),
                );
              },
              child: Text('Create New Roster'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditRosterPage()),
                );
              },
              child: Text('Edit Existing Roster'),
            ),
          ],
        ),
      ),
    );
  }
}