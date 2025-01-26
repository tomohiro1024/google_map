import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/google_map.dart';
import 'package:google_map/secret.dart';
import 'package:google_place/google_place.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SearchPage> {
  late GooglePlace googlePlace;
  final apiKey = Secret.apiKey;
  GoogleMap? googleMap;
  Uri? openGoogleMapUrl;
  bool isGoogleSearchResult = false;

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
      Location(lat: currentLatitude, lng: currentLongitude),
      1500,
      language: 'ja',
      type: "convenience_store",
      keyword: "コンビニ",
      rankby: RankBy.Distance,
    );

    final result = response?.results;

    setState(() {
      isGoogleSearchResult = result?.isNotEmpty ?? false;
    });

    // GoogleMapのデータが取得できなかった場合は処理を終了
    if (!isGoogleSearchResult) {
      return;
    }

    final firstResult = result?.first;
    final goalLocation = firstResult?.geometry?.location;
    final goalLatitude = goalLocation?.lat;
    final goalLongitude = goalLocation?.lng;

    // GoogleMapアプリを開くURLを生成
    String rootUrl =
        'https://www.google.com/maps/dir/$currentLatitude,$currentLongitude/$goalLatitude,$goalLongitude';

    openGoogleMapUrl = Uri.parse(rootUrl);

    if (firstResult != null && mounted) {
      final photoReference = firstResult.photos?.first.photoReference;
      String? photoUrl;

      if (photoReference != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$apiKey';
      }

      // photoReferenceがnullの場合、空の画像を表示する処理を追加
      setState(() {
        googleMap = GoogleMap(
          firstResult.name,
          photoUrl,
          goalLocation,
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

    // if (isGoogleSearchResult == false) {
    //   // ダイアログ表示に変更
    //   return Scaffold(
    //     body: Center(
    //       child: Text('検索結果が見つかりませんでした。'),
    //     ),
    //   );
    // }
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
              child: googleMap!.photoUrl != null
                  ? Image.network(
                      // googleMapのデータがnullの場合は何かしらの画像を表示
                      googleMap!.photoUrl!,
                      width: width,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/cat.png',
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
              onPressed: () async {
                // GoogleMapアプリを開く
                await launchUrl(openGoogleMapUrl!);
              },
              child: Text('GoogleMapアプリで開く'),
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
