import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/google_map.dart';
import 'package:google_place/google_place.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SearchPage> {
  late GooglePlace googlePlace;
  final apiKey = '';
  GoogleMap? googleMap;
  Uri? openGoogleMapUrl;

  @override
  void initState() {
    super.initState();
    searchPosition();
  }

  Future searchPosition() async {
    final currentPosition = await _determinePosition();
    final currentLatitude = currentPosition.latitude;
    final currentLongitude = currentPosition.longitude;

    googlePlace = GooglePlace(apiKey);

    print('緯度：$currentLatitude / 経度：$currentLongitude');

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
      final photoReference = firstResult.photos?.first.photoReference;
      setState(() {
        googleMap = GoogleMap(
          firstResult.name,
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$apiKey',
          firstResult.geometry?.location,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    if (googleMap == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
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
              // googleMapのデータがnullの場合は何かしらの画像を表示
              child: Image.network(
                googleMap!.photoUrl ?? '',
                width: width,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: height * 0.03),
            Text(
              googleMap!.name ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(height: height * 0.03),
            ElevatedButton(
              onPressed: () async{
                await launchUrl(openGoogleMapUrl!);
              },
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
