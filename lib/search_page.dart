import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('検索')),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: height * 0.01),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://lh5.googleusercontent.com/p/AF1QipOWtxNfoxL1rAuAsALYMRPJQEYWJ5JEn1sUxpkP=w408-h544-k-no',
                width: width,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              '検索名',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: height * 0.03),
            ElevatedButton(
              onPressed: () {},
              child: Text('ボタン'),
            ),
          ],
        ),
      ),
    );
  }
}
