import 'package:google_place/google_place.dart';

class GoogleMap {
  String? name;
  String? photoUrl;
  Location? location;
  double? rating;
  int? userRatingsTotal;
  bool? isOpen;
  int? distance;
  String? walkingTime;

  GoogleMap(this.name, this.photoUrl, this.location, this.rating,
      this.userRatingsTotal, this.isOpen, this.distance, this.walkingTime);
}
