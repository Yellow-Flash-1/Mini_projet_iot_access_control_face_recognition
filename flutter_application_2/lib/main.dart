import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _websiteAddress = 'localhost'; // Replace with your website address

  void updateWebsiteAddress(String newAddress) {
    setState(() {
      _websiteAddress = newAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Image Viewer'),
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () async {
                    // Navigate to the settings page and get the updated website address
                    final websiteAddress = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          currentAddress: _websiteAddress,
                        ),
                      ),
                    );

                    // Update the website address if it has changed
                    if (websiteAddress != null) {
                      updateWebsiteAddress(websiteAddress);
                    }
                  },
                ),
              ],
            ),
          ),
          body: ImageListScreen(websiteAddress: _websiteAddress),
        ),
      ),
    );
  }
}

class ImageListScreen extends StatefulWidget {
  final String websiteAddress;

  ImageListScreen({required this.websiteAddress});

  @override
  _ImageListScreenState createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  List<Attempt> _attempts = [];
  int _currentPage = 1;
  int _maxPage = 10; // Change this value to the maximum number of pages
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAttempts();
  }

  Future<void> fetchAttempts() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://${widget.websiteAddress}:5000/attempts?page=$_currentPage');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final attempts = List<Attempt>.from(data['attempts'].map((x) => Attempt.fromJson(x)));

      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch attempts.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> goToPage(int page) async {
    setState(() {
      _currentPage = page;
    });
    await fetchAttempts();
  }

  void viewImageDetails(Attempt attempt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageDetailsScreen(attempt: attempt),
      ),
    );
  }

  Widget buildPageNumber(int page) {
    final bool isCurrentPage = page == _currentPage;
    final bool isClickable = !isCurrentPage;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isClickable ? () => goToPage(page) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrentPage ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.all(8),
          child: Text(
            '$page',
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.black,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> buildPageNumbers() {
    final List<Widget> pageNumbers = [];

    // Add the first page number
    pageNumbers.add(buildPageNumber(1));

    // Add the page numbers with ellipsis in between
    if (_currentPage > 3) {
      pageNumbers.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...'),
      ));
    }
    for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
      if (i > 1 && i < _maxPage) {
        pageNumbers.add(buildPageNumber(i));
      }
    }
    if (_currentPage < _maxPage - 2) {
      pageNumbers.add(Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text('...'),
      ));
    }

    // Add the last page number
    pageNumbers.add(buildPageNumber(_maxPage));

    return pageNumbers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
              ? Center(child: Text('No attempts found.'))
              : ListView.builder(
                  itemCount: _attempts.length,
                  itemBuilder: (ctx, index) {
                    final attempt = _attempts[index];
                    return ListTile(
                      title: Text(attempt.timestamp),
                      subtitle: Text('Button ${attempt.button}, ${attempt.person}, ${attempt.response ? "Allowed" : "Denied"}'),
                      onTap: () {
                        viewImageDetails(attempt);
                      },
                    );
                  },
                ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buildPageNumbers(),
        ),
      ),
    );
  }
}

class ImageDetailsScreen extends StatelessWidget {
  final Attempt attempt;

  ImageDetailsScreen({required this.attempt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Details'),
      ),
      body: Column(
        children: [
          Image.network(
            '${attempt.imageUrl}',
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            headers: {'accept': 'image/jpeg'}
          ),
          SizedBox(height: 16),
          Text('Timestamp: ${attempt.timestamp}'),
          Text('Button: ${attempt.button}'),
          Text('Response: ${attempt.response ? "Allowed" : "Denied"}'),
          Text('Person: ${attempt.person}'),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final String currentAddress;

  SettingsPage({required this.currentAddress});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void saveSettings() {
    final newAddress = _controller.text;
    Navigator.pop(context, newAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Website Address',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: saveSettings,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class Attempt {
  final String timestamp;
  final int button;
  final bool response;
  final String person;
  final String imageUrl;

  Attempt({
    required this.timestamp,
    required this.button,
    required this.response,
    required this.person,
    required this.imageUrl,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      timestamp: json['timestamp'],
      button: json['button'],
      response: json['response'],
      person: json['person'],
      imageUrl: 'http://localhost:5000/image-data?timestamp=${json['timestamp']}',
    );
  }
}
