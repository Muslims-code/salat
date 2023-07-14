import 'package:salat/salat.dart';
import 'package:timezone/standalone.dart' as tz;

void main(List<String> args) async {
  await tz.initializeTimeZone();

  String timezone = "Asia/Riyadh"; // Time zone of Mecca (Riyadh)
  final pt = prayerTimes(
      method: CalculationMethod.MAKKAH); // Create prayer times object

  double longitude = 39.857910; // Longitude of the location
  double latitude = 21.389082; // Latitude of the location

  // Calculate prayer times for the given location
  final prayertimes = pt.calcTime(
    date: DateTime.now(),
    timezone: timezone,
    longitude: longitude,
    latitude: latitude,
  );
  printPrayerTimes(prayertimes);
}
