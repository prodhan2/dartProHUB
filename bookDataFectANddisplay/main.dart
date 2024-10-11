import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'book/api_controller.dart'; // Importing the API controller
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart'; // Importing package to open files

void main() {
  runApp(CSEBooksApp());
}

class CSEBooksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE Book List',
      
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BookListPage(),
      
    );
  }
}

class BookListPage extends StatefulWidget {
  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  List books = [];
  List favoriteBooks = [];
  List filteredBooks = [];
  final ApiController apiController = ApiController();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    searchController.addListener(() => filterBooks());
  }

  // Fetch books using the ApiController
  Future<void> fetchBooks() async {
    try {
      List fetchedBooks = await apiController.fetchBooks();
      setState(() {
        books = fetchedBooks;
        filteredBooks = books; // Initialize the filtered list
      });
    } catch (error) {
      print('Error fetching books: $error');
    }
  }

  // Filter books based on the search query
  void filterBooks() {
    setState(() {
      filteredBooks = books
          .where((book) => book['book_name']
              .toLowerCase()
              .contains(searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text('CSE Book List'),
  actions: [
    IconButton(
      icon: Icon(Icons.favorite),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FavoriteBooksPage(favoriteBooks: favoriteBooks),
          ),
        );
      },
    ),
  ],
  bottom: PreferredSize(
    preferredSize: Size.fromHeight(50),
    child: Padding(
      padding: EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search for books...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(Icons.search),
        ),
      ),
    ),
  ),
),

      body: filteredBooks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredBooks.length,
              itemBuilder: (context, index) {
                return BookItem(
                  book: filteredBooks[index],
                  isFavorite: favoriteBooks.contains(filteredBooks[index]),
                  onFavoriteToggle: () {
                    setState(() {
                      if (favoriteBooks.contains(filteredBooks[index])) {
                        favoriteBooks.remove(filteredBooks[index]);
                      } else {
                        favoriteBooks.add(filteredBooks[index]);
                      }
                    });
                  },
                );
              },
            ),
    );
  }
}

class BookItem extends StatefulWidget {
  final Map book;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const BookItem({
    Key? key,
    required this.book,
    required this.isFavorite,
    required this.onFavoriteToggle,
  }) : super(key: key);

  @override
  _BookItemState createState() => _BookItemState();
}

class _BookItemState extends State<BookItem> {
  double downloadProgress = 0;
  bool isDownloading = false;
  bool isDownloaded = false;
  String? localFilePath;

  @override
  void initState() {
    super.initState();
    _checkIfDownloaded();
  }

  // Check if the file is already downloaded
  Future<void> _checkIfDownloaded() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${widget.book['download_link'].split('/').last}');

    if (await file.exists()) {
      setState(() {
        localFilePath = file.path;
        isDownloaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            leading: Image.network(
              widget.book['image'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(widget.book['book_name']),
            subtitle: Text('Author: ${widget.book['author']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(widget.isFavorite ? Icons.favorite : Icons.favorite_border),
                  color: widget.isFavorite ? Colors.red : Colors.grey,
                  onPressed: widget.onFavoriteToggle,
                ),
                IconButton(
                  icon: Icon(isDownloaded ? Icons.open_in_new : Icons.download),
                  onPressed: () {
                    if (!isDownloading) {
                      if (isDownloaded) {
                        _openFile(localFilePath!);
                      } else {
                        _downloadBook(widget.book['download_link']);
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          ExpansionTile(
            title: Text('More Details'),
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("Details: ${widget.book['details']}"),
              ),
              if (isDownloaded)
                ElevatedButton(
                  onPressed: () {
                    _openFile(localFilePath!);
                  },
                  child: Text("Open File"),
                ),
            ],
          ),
        ],
      ),
    );
  }

void _showDownloadProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal while downloading
      builder: (context) {
        return AlertDialog(
          title: Text("Downloading..."),
          content: Row(
            children: [
              CircularProgressIndicator(
                value: downloadProgress, // Show the current download progress
              ),
              SizedBox(width: 20),
              Text('${(downloadProgress * 100).toStringAsFixed(0)}%'), // Percentage display
            ],
          ),
        );
      },
    );
  }

  // Method to show the download finished dialog with an "Open" button
  void _showDownloadFinishedDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal until the user acknowledges
      builder: (context) {
        return AlertDialog(
          title: Text("Download Finished!"),
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 40), // Finished icon
              SizedBox(width: 20),
              Text('Download complete!'), // Download complete message
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _openFile(filePath); // Open the downloaded file
              },
              child: Text('Open'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Method to download the book
  Future<void> _downloadBook(String url) async {
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    _showDownloadProgressDialog(); // Show the download progress dialog

    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode == 200) {
        final contentLength = response.contentLength; // Get the file size
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${url.split('/').last}');
        localFilePath = file.path;

        List<int> bytes = [];
        int downloadedBytes = 0;

        // Listen for the file's data chunks
        response.stream.listen(
          (chunk) {
            bytes.addAll(chunk);
            downloadedBytes += chunk.length;

            // Update download progress
            setState(() {
              downloadProgress = downloadedBytes / contentLength!;
            });
          },
          onDone: () async {
            // Write the complete file
            await file.writeAsBytes(bytes);

            setState(() {
              downloadProgress = 1.0; // 100% completed
              isDownloading = false;
            });

            // Close the progress dialog
            Navigator.of(context).pop();

            // Show the download finished alert with the file path
            _showDownloadFinishedDialog(localFilePath!);
          },
          onError: (error) {
            setState(() {
              isDownloading = false;
            });
            Navigator.of(context).pop(); // Close the progress dialog
            print('Error downloading file: $error');
          },
          cancelOnError: true,
        );
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
      Navigator.of(context).pop(); // Close the progress dialog
      print('Error downloading file: $e');
    }
  }

  // Method to open the downloaded file
  void _openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    print('File opened with result: $result');
  }

  // You can create your ListView here to display downloaded books
}



class FavoriteBooksPage extends StatelessWidget {
  final List favoriteBooks;

  const FavoriteBooksPage({Key? key, required this.favoriteBooks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorite Books'),
      ),
      body: favoriteBooks.isEmpty
          ? Center(child: Text('No favorite books added yet.'))
          : ListView.builder(
              itemCount: favoriteBooks.length,
              itemBuilder: (context, index) {
                return BookItem(
                  book: favoriteBooks[index],
                  isFavorite: true,
                  onFavoriteToggle: () {
                    // Handle removing from favorites
                  },
                );
              },
            ),
    );
  }
}
