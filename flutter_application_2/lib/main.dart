import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageListScreen(),
    );
  }
}

class ImageListScreen extends StatefulWidget {
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

    final url = Uri.parse('http://localhost:5000/attempts?page=$_currentPage');
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
            'http://localhost:5000/image-data?timestamp=${attempt.timestamp}',
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
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

class Attempt {
  final String timestamp;
  final int button;
  final bool response;
  final String person;

  Attempt({
    required this.timestamp,
    required this.button,
    required this.response,
    required this.person,
  });

  factory Attempt.fromJson(Map<String, dynamic> json) {
    return Attempt(
      timestamp: json['timestamp'],
      button: json['button'],
      response: json['response'],
      person: json['person'],
    );
  }
}
