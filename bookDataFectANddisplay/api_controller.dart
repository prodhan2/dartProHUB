import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiController {
  final String apiUrl = 'https://api.npoint.io/0e4650a66b6c8041b351';

  // Method to fetch the list of books
  Future<List> fetchBooks() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      // If the server returns a valid response, parse the JSON.
      Map<String, dynamic> data = json.decode(response.body);
      return data['books'];
    } else {
      // If the server did not return a 200 OK response, throw an exception.
      throw Exception('Failed to load books');
    }
  }
}
