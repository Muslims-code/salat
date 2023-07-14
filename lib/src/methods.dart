// ignore_for_file: constant_identifier_names

import 'calculations.dart';
import 'package:timezone/timezone.dart';
import 'package:hijri/hijri_calendar.dart';

enum CalculationMethod {
  ISNA,
  MWL,
  EGYPT,
  TEHRAN,
  JAFARI,
  MAKKAH,
  KARACHI,
}

enum AsrMethod {
  STANDARD,
  HANAFI,
}

class GeneralMethod {
  double fajrAltitude;
  double ishaAltitude;
  double sunsetAltitude;
  AsrMethod asrMethod;
  late int shadowFactor;

  GeneralMethod(
      {required double fajrAltitudeDeg,
      required double ishaAltitudeDeg,
      this.asrMethod = AsrMethod.STANDARD})
      : shadowFactor = asrMethod == AsrMethod.STANDARD ? 1 : 2,
        fajrAltitude = radians(fajrAltitudeDeg),
        sunsetAltitude = radians(0.833),
        ishaAltitude = radians(ishaAltitudeDeg);
  Map<String, DateTime> calcTime(
      {required DateTime date,
      required String timezone,
      required double longitude,
      required double latitude}) {
    DateTime localNoon =
        TZDateTime(getLocation(timezone), date.year, date.month, date.day, 12);
    DateTime fajr = timeAltitude(
        localNoon: localNoon,
        altitude: fajrAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: true);
    DateTime sunrise = timeAltitude(
        localNoon: localNoon,
        altitude: sunsetAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: true);
    DateTime dhuhr = timeZenith(
      localNoon: localNoon,
      longitude: longitude,
    );
    DateTime asr = timeShadowFactor(
        localNoon: localNoon,
        shadowFactor: shadowFactor,
        longitude: longitude,
        latitude: latitude,
        rising: false);
    DateTime maghrib = timeAltitude(
        localNoon: localNoon,
        altitude: sunsetAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: false);
    DateTime isha = timeAltitude(
        localNoon: localNoon,
        altitude: ishaAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: false);
    DateTime sunset = maghrib;
    DateTime nextLocalNoon = localNoon.add(Duration(days: 1));
    DateTime nextSunrise = timeAltitude(
      localNoon: nextLocalNoon,
      altitude: sunsetAltitude,
      longitude: longitude,
      latitude: latitude,
      rising: true,
    );
    DateTime midnight = sunset.add((Duration(
        milliseconds:
            (nextSunrise.difference(sunset).inMilliseconds / 2).round())));

    Map<String, DateTime> times = {
      "fajr": fajr,
      "sunrise": sunrise,
      "dhuhr": dhuhr,
      "asr": asr,
      "maghrib": maghrib,
      "isha": isha,
      "midnight": midnight,
    };
    times.forEach((key, value) {
      times[key] = TZDateTime.from(value, getLocation(timezone));
    });
    return times;
  }
}

class TehranMethod extends GeneralMethod {
  final AsrMethod asrMethod = AsrMethod.STANDARD;
  TehranMethod()
      : super(
            fajrAltitudeDeg: 17.7,
            ishaAltitudeDeg: 14,
            asrMethod: AsrMethod.STANDARD);
  @override
  Map<String, DateTime> calcTime(
      {required DateTime date,
      required String timezone,
      required double longitude,
      required double latitude}) {
    DateTime localNoon =
        TZDateTime(getLocation(timezone), date.year, date.month, date.day, 12);
    double magribAltitude = radians(4.5);
    Map<String, DateTime> times = super.calcTime(
        date: date,
        timezone: timezone,
        longitude: longitude,
        latitude: latitude);
    DateTime sunset = times["maghrib"]!;
    DateTime maghrib = timeAltitude(
        localNoon: localNoon,
        altitude: magribAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: false);
    times["maghrib"] = maghrib;
    DateTime nextLocalNoon = localNoon.add(Duration(days: 1));
    DateTime nextFajr = timeAltitude(
        localNoon: nextLocalNoon,
        altitude: fajrAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: true);
    DateTime midnight = sunset.add((Duration(
        milliseconds:
            (nextFajr.difference(sunset).inMilliseconds / 2).round())));
    times["midnight"] = midnight;
    return times;
  }
}

class JafariMethod extends GeneralMethod {
  final AsrMethod asrMethod = AsrMethod.STANDARD;
  JafariMethod()
      : super(
            fajrAltitudeDeg: 16,
            ishaAltitudeDeg: 14,
            asrMethod: AsrMethod.STANDARD);
  Map<String, DateTime> calcTime(
      {required DateTime date,
      required String timezone,
      required double longitude,
      required double latitude}) {
    DateTime localNoon =
        TZDateTime(getLocation(timezone), date.year, date.month, date.day, 12);
    double magribAltitude = radians(4);
    Map<String, DateTime> times = super.calcTime(
        date: date,
        timezone: timezone,
        longitude: longitude,
        latitude: latitude);
    DateTime sunset = times["maghrib"]!;
    DateTime maghrib = timeAltitude(
        localNoon: localNoon,
        altitude: magribAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: false);
    times["maghrib"] = maghrib;
    DateTime nextLocalNoon = localNoon.add(Duration(days: 1));
    DateTime nextFajr = timeAltitude(
        localNoon: nextLocalNoon,
        altitude: fajrAltitude,
        longitude: longitude,
        latitude: latitude,
        rising: true);
    DateTime midnight = sunset.add((Duration(
        milliseconds:
            (nextFajr.difference(sunset).inMilliseconds / 2).round())));
    times["midnight"] = midnight;
    return times;
  }
}

class MakkahMethod extends GeneralMethod {
  final AsrMethod asrMethod = AsrMethod.STANDARD;
  MakkahMethod()
      : super(
            fajrAltitudeDeg: 18.5,
            ishaAltitudeDeg: 18.5,
            asrMethod: AsrMethod.STANDARD);
  @override
  Map<String, DateTime> calcTime(
      {required DateTime date,
      required String timezone,
      required double longitude,
      required double latitude}) {
    Map<String, DateTime> times = super.calcTime(
        date: date,
        timezone: timezone,
        longitude: longitude,
        latitude: latitude);
    HijriCalendar hijriDate =
        HijriCalendar.fromDate(DateTime(date.year, date.month, date.day));
    if (hijriDate.hMonth == 9) {
      times["isha"] = times["maghrib"]!.add(Duration(minutes: 120));
    } else {
      times["isha"] = times["maghrib"]!.add(Duration(minutes: 90));
    }
    return times;
  }
}

GeneralMethod prayerTimes(
    {CalculationMethod method = CalculationMethod.MWL,
    AsrMethod asr = AsrMethod.STANDARD}) {
  if (method == CalculationMethod.ISNA) {
    return GeneralMethod(fajrAltitudeDeg: 15, ishaAltitudeDeg: 15);
  } else if (method == CalculationMethod.MWL) {
    return GeneralMethod(fajrAltitudeDeg: 18, ishaAltitudeDeg: 17);
  } else if (method == CalculationMethod.EGYPT) {
    return GeneralMethod(fajrAltitudeDeg: 19.5, ishaAltitudeDeg: 17.5);
  } else if (method == CalculationMethod.KARACHI) {
    return GeneralMethod(fajrAltitudeDeg: 18, ishaAltitudeDeg: 18);
  } else if (method == CalculationMethod.TEHRAN) {
    return TehranMethod();
  } else if (method == CalculationMethod.JAFARI) {
    return JafariMethod();
  } else if (method == CalculationMethod.MAKKAH) {
    return MakkahMethod();
  } else {
    throw Exception("Unknown CalculationMethod ${method.toString()}");
  }
}
