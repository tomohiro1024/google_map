import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map/google_map.dart';
import 'package:google_map/secret.dart';
import 'package:google_place/google_place.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spring_button/spring_button.dart';

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
          ? SingleChildScrollView(
              child: Column(
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
                                height: 220,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/images/cat.png',
                                width: width * 0.95,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  SizedBox(
                    height: 60,
                    width: width * 0.7,
                    child: SpringButton(
                      SpringButtonType.OnlyScale,
                      Padding(
                        padding: const EdgeInsets.all(10.5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.cyan,
                            borderRadius: BorderRadius.all(
                              Radius.circular(20.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map,
                                color: Colors.black,
                              ),
                              SizedBox(width: width * 0.02),
                              const Center(
                                child: Text(
                                  'GoogleMapアプリで確認',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      onTapDown: (_) async {
                        await launchUrl(openGoogleMapUrl!);
                      },
                      onLongPress: null,
                      onLongPressEnd: null,
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  Column(
                    children: [
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
                                SizedBox(height: 5),
                                Text('ここからの距離'),
                                SizedBox(height: 9),
                                Text(
                                  googleMap!.distance.toString() + 'm',
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
                            height: 90,
                            child: Column(
                              children: [
                                SizedBox(height: 5),
                                Text('徒歩時間'),
                                SizedBox(height: 15),
                                Text(
                                  googleMap!.walkingTime!,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.02),
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
                                SizedBox(height: 5),
                                Text('レビュー評価'),
                                SizedBox(height: 9),
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
                            height: 90,
                            child: Column(
                              children: [
                                SizedBox(height: 5),
                                Text('レビュー数'),
                                SizedBox(height: 9),
                                Text(
                                  googleMap!.userRatingsTotal.toString(),
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.02),
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
                            SizedBox(height: 5),
                            Text('営業状況'),
                            SizedBox(height: 13),
                            Text(
                              googleMap!.isOpen! ? '営業中' : '営業時間外',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.03),
                ],
              ),
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
