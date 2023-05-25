import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  String websiteAddress = 'http://localhost:5000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Website Address:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: websiteAddress,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                websiteAddress = value;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Save the website address and navigate back to the previous screen
                Navigator.pop(context, websiteAddress);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
