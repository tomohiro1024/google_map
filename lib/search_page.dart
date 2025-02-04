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
  String? photoUrl;
  double? doubleDistance;
  int? distance;
  String? walkingTime;

  @override
  void initState() {
    super.initState();
    searchPosition();
  }

  Future searchPosition() async {
    // 現在地の取得
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

    // if (result != null && result.isNotEmpty) {
    //   print('検索結果（一覧）:');
    //   for (var item in result) {
    //     print('店名: ${item.name}, 評価: ${item.rating}');
    //   }
    // } else {
    //   print('検索結果は見つかりませんでした。');
    // }

    setState(() {
      isGoogleSearchResult = result?.isNotEmpty ?? false;
    });

    // GoogleMapのデータが取得できなかった場合は処理を終了
    if (!isGoogleSearchResult) {
      return;
    }

    final firstResult = result?.first;
    // コンビニの目的地の取得
    final goalLocation = firstResult?.geometry?.location;
    final goalLatitude = goalLocation?.lat;
    final goalLongitude = goalLocation?.lng;

    // GoogleMapアプリを開くURLを生成
    String rootUrl =
        'https://www.google.com/maps/dir/$currentLatitude,$currentLongitude/$goalLatitude,$goalLongitude';

    openGoogleMapUrl = Uri.parse(rootUrl);

    if (firstResult != null && mounted) {
      final photoReference = firstResult.photos?.first.photoReference;
      final rating = firstResult.rating;
      final userRatingsTotal = firstResult.userRatingsTotal;
      final isOpen = firstResult.openingHours?.openNow ?? false;

      print('レビュー評価：$rating');
      print('レビュー数：$userRatingsTotal');
      print('営業中：$isOpen');

      doubleDistance = Geolocator.distanceBetween(
        currentLatitude,
        currentLongitude,
        goalLatitude!,
        goalLongitude!,
      );

      // 小数点切り捨て
      distance = doubleDistance!.floor();

      walkingTime = calculateWalkingTime(distance!);

      print('距離：$distance m');

      print('徒歩時間：$walkingTime');

      if (photoReference != null) {
        photoUrl =
            'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=$photoReference&key=$apiKey';
      }

      setState(() {
        googleMap = GoogleMap(firstResult.name, photoUrl, goalLocation, rating,
            userRatingsTotal, isOpen, distance, walkingTime);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, 2),
              child: Icon(
                Icons.store,
                color: Colors.pink,
              ),
            ),
            Text(
              'コンビニ検索',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: googleMap != null
          ? Column(
              children: [
                SizedBox(height: height * 0.03),
                Transform.translate(
                  offset: Offset(width * -0.09, 0),
                  child: Text('ここから一番近いコンビニは...'),
                ),
                SizedBox(height: height * 0.01),
                Text(
                  googleMap!.name ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: height * 0.02),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: googleMap!.photoUrl != null
                          ? Image.network(
                              googleMap!.photoUrl!,
                              width: width * 0.95,
                              height: 240,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/images/cat.png',
                              width: width * 0.95,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.03),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: width * 0.35,
                      height: 90,
                      child: Column(
                        children: [
                          Text('レビュー評価'),
                          SizedBox(height: 10),
                          Text(
                            googleMap!.rating.toString(),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      width: width * 0.35,
                      height: 100,
                      child: Column(
                        children: [
                          Text('レビュー評価'),
                          Text(
                            googleMap!.rating.toString(),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

String calculateWalkingTime(int distance) {
  const walkingSpeed = 1.4; // 徒歩速度 (メートル/秒)
  final timeInSeconds = distance / walkingSpeed; // 徒歩時間 (秒)
  final timeInMinutes = timeInSeconds ~/ 60; // 分単位に変換 (切り捨て)
  final remainingSeconds = timeInSeconds % 60; // 秒の残り
  return '約$timeInMinutes分${remainingSeconds.toInt()}秒';
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
