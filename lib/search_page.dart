import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_place/google_place.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SearchPage> {
  late GooglePlace googlePlace;
  final apiKey = '';

  @override
  void initState() {
    super.initState();
    searchPosition();
  }

  Future searchPosition() async {
    final position = await _determinePosition();
    final latitude = position.latitude;
    final longitude = position.longitude;

    googlePlace = GooglePlace(apiKey);

    print('緯度：$latitude / 経度：$longitude');

    var response = await googlePlace.search.getNearBySearch(
      Location(lat: -33.8670522, lng: 151.1957362),
      1500,
      language: 'ja',
      type: "convenience_store",
      keyword: "コンビニ",
      rankby: RankBy.Distance,
    );

    final result = response?.results;
    final firstResult = result?.first;

    if (firstResult != null && mounted) {
      setState(() {});
    }
  }

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

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('位置情報を許可してください！');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('位置情報を許可してください！');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('位置情報を許可してください！');
  }

  return await Geolocator.getCurrentPosition();
}
