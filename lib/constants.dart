import 'package:location/location.dart';

final double defaultZoom = 10.8746;
final double newZoom = 15.8746;

final LocationData defaultLocation = new LocationData.fromMap({
  'latitude': -1.10313,
  'longitude': 37.01142
});

final String defaultMarkerId = "1";

final String serverUri = "test.mosquitto.org";
final int port = 1883;
final String topicName = "Dart/Mqtt_client/location";