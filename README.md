# Prayer Time Dart Package

[![Pub](https://img.shields.io/pub/v/prayer_times.svg)](https://pub.dev/packages/salat)

This Dart package provides functionality for calculating accurate Islamic prayer times. It is a translation of the original [Salat](https://github.com/zainhussaini/salat/) repository, bringing the power and flexibility of prayer time calculations to the Dart ecosystem.

## Features

- Calculation of precise prayer times based on different calculation methods.
- Support for a wide range of time zones and locations.
- Calculation of additional prayer-related timings such as sunrise and sunset.
- Customizable calculation settings to accommodate various calculation conventions and preferences.
- Easy-to-use API for retrieving prayer times for a specific date, location, and time zone.
- Flexible integration options with other Dart projects or frameworks.

## Installation

To install this package :

```bash
dart pub add salat
```

Then, run `dart pub get` to fetch the package.

## Usage
Here's a simple example demonstrating how to calculate prayer times using the prayer_times package:

```dart
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
```
### output
| Name     | Time                       |
|----------|----------------------------|
| fajr     | July 14, 2023 04:20:49 +3  |
| sunrise  | July 14, 2023 05:47:00 +3  |
| dhuhr    | July 14, 2023 12:26:32 +3  |
| asr      | July 14, 2023 15:40:29 +3  |
| maghrib  | July 14, 2023 19:05:54 +3  |
| isha     | July 14, 2023 20:35:54 +3  |
| midnight | July 14, 2023 12:26:27 +3  |

Please refer to the documentation for more details on how to use this package.

## Contributing
Contributions are welcome! If you encounter any issues, have suggestions, or would like to contribute to the package, please feel free to open an issue or submit a pull request on the GitHub repository.
