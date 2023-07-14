import 'dart:math' as math;

extension DurationExtensions on Duration {
  double toSeconds() {
    return inMicroseconds / Duration.microsecondsPerSecond;
  }
}

double radians(double degrees) {
  return degrees * math.pi / 180.0;
}

bool isClose(double a, double b) {
  double tolerance = 1e-6; // Example tolerance
  return (a - b).abs() < tolerance;
}

List eotDecl(DateTime time) {
  DateTime epoch = DateTime.utc(2000, 1, 1, 12);
  double days_since_epoch =
      (time.difference(epoch) + Duration(days: 1)).toSeconds() / 60 / 60 / 24;
  double y100 = days_since_epoch / 36525;
  double e = 1.6709e-2 - 4.193e-5 * y100 - 1.26e-7 * math.pow(y100, 2);
  double lam_p =
      radians(282.93807 + 1.7195 * y100 + 3.025e-4 * math.pow(y100, 2));
  double epsilon = radians(23.4393 -
      0.013 * y100 -
      2e-7 * math.pow(y100, 2) +
      5e-7 * math.pow(y100, 3));
  double MD = 6.24004077;
  double TY = 365.2596358;
  double D = days_since_epoch % TY;
  double M = MD + 2 * math.pi * D / TY;
  M = M % (2 * math.pi);
  double E = keplerSolve(M: M, e: e);
  double nu = math.acos((math.cos(E) - e) / (1 - e * math.cos(E)));
  if (E > math.pi) {
    nu = 2 * math.pi - nu;
  }
  double lam = nu + lam_p;
  lam = lam % (2 * math.pi);
  double alpha;
  if (isClose(math.cos(lam), 0)) {
    alpha = lam;
  } else {
    alpha = math.atan(math.cos(epsilon) * math.tan(lam));
    if (lam < math.pi / 2) {
      assert((0 <= alpha) && (alpha < math.pi / 2));
    } else if (lam < math.pi * 3 / 2) {
      alpha += math.pi;
      assert((math.pi * 3 / 2 <= alpha) && (alpha < 2 * math.pi));
    } else {
      alpha += 2 * math.pi;
      assert((math.pi * 3 / 2 <= alpha) && (alpha < 2 * math.pi));
    }
  }
  double eot_rad = M + lam_p - alpha;
  if (eot_rad > math.pi) {
    eot_rad -= 2 * math.pi;
  }
  double eot_min = eot_rad / (2 * math.pi) * 60 * 24;
  Duration eot = Duration(seconds: (eot_min * 60).round());
  double decl = math.asin(math.sin(epsilon) * math.sin(lam));
  return [eot, decl];
}

double keplerSolve({required double M, required double e}) {
  if (!(e > 0 && e < 1)) {
    throw Exception(
        "Eccentricity of elliptical orbit required in range (0, 1)");
  }
  double E = M;
  while (!isClose(M, E - e * math.sin(E))) {
    E = E - (E - e * math.sin(E) - M) / (1 - e * math.cos(E));
  }
  return E;
}

double calcAltitude(
    {required int shadowFactor,
    required double declination,
    required double latitude}) {
  double phi = radians(latitude);
  double delta = declination;
  double alt = math.atan(1 / (shadowFactor + math.tan(phi - delta)));
  return alt;
}

Duration timedeltaAtAltitude(
    {required double altitude,
    required double declination,
    required double latitude}) {
  double alpha = altitude;
  double phi = radians(latitude);
  double delta = declination;
  double numerator = -math.sin(alpha) - math.sin(phi) * math.sin(delta);
  double denominator = math.cos(phi) * math.cos(delta);
  double cosHourRad = numerator / denominator;
  if (cosHourRad < -1 || cosHourRad > 1) {
    throw Exception("Sun does not reach altitude");
  }
  double hourRad = math.acos(cosHourRad);
  double hours = hourRad / (2 * math.pi) * 24;
  Duration T = Duration(seconds: (hours * 60 * 60).round());

  assert((Duration.zero <= T) && (T <= Duration(hours: 12)));
  return T;
}

DateTime linearInterpolation(
    {required Duration Function(DateTime) diffFunction,
    required DateTime guess1,
    required DateTime guess2}) {
  if (isClose((guess1.difference(guess2).inSeconds.toDouble()), 0)) {
    throw Exception("guess1 and guess2 need to be different");
  }
  if (guess2.isBefore(guess1)) {
    DateTime temp = guess1;
    guess1 = guess2;
    guess2 = temp;
  }
  Duration diff1 = diffFunction(guess1);
  Duration diff2 = diffFunction(guess2);
  while (!isClose((guess1.difference(guess2).inSeconds.toDouble()), 0)) {
    Duration diff = guess2.difference(guess1);
    double ratio = diff.inMilliseconds / (diff2 - diff1).inMilliseconds;
    DateTime guess3 = guess1.subtract(diff1 * ratio);
    Duration diff3 = diffFunction(guess3);

    guess1 = guess2;
    diff1 = diff2;
    guess2 = guess3;
    diff2 = diff3;
  }
  return guess1;
}

DateTime timeZenith({required DateTime localNoon, required double longitude}) {
  DateTime utcNoonApprox =
      localNoon.add(Duration(seconds: (longitude / 15 * 3600).round()));
  utcNoonApprox = utcNoonApprox.toUtc();
  DateTime utcna = utcNoonApprox;
  DateTime utcNoon = DateTime.utc(utcna.year, utcna.month, utcna.day, 12);
  Duration calcDifference(DateTime guess) {
    Duration eot = eotDecl(guess)[0];

    DateTime actual = utcNoon
        .subtract(Duration(seconds: (longitude / 15 * 3600).round()))
        .subtract(eot);
    return actual.difference(guess);
  }

  DateTime guess =
      utcNoon.subtract(Duration(seconds: (longitude / 15 * 3600).round()));
  DateTime guess1 = guess.subtract(Duration(minutes: 20));
  DateTime guess2 = guess.add(Duration(minutes: 20));
  return linearInterpolation(
      diffFunction: calcDifference, guess1: guess1, guess2: guess2);
}

DateTime timeAltitude(
    {required DateTime localNoon,
    required double altitude,
    required double longitude,
    required double latitude,
    required bool rising}) {
  DateTime zenith = timeZenith(localNoon: localNoon, longitude: longitude);

  Duration calcDifference(DateTime guess) {
    double declination = eotDecl(guess)[1];
    Duration T = timedeltaAtAltitude(
        altitude: altitude, declination: declination, latitude: latitude);
    DateTime actual;
    if (rising) {
      actual = zenith.subtract(T);
    } else {
      actual = zenith.add(T);
    }
    return actual.difference(guess);
  }

  DateTime guess1;
  DateTime guess2;
  if (rising) {
    guess1 = zenith.subtract(Duration(hours: 12));
    guess2 = zenith;
  } else {
    guess1 = zenith;
    guess2 = zenith.add(Duration(hours: 12));
  }

  return linearInterpolation(
      diffFunction: calcDifference, guess1: guess1, guess2: guess2);
}

DateTime timeShadowFactor(
    {required DateTime localNoon,
    required int shadowFactor,
    required double longitude,
    required double latitude,
    required bool rising}) {
  DateTime zenith = timeZenith(localNoon: localNoon, longitude: longitude);

  Duration calcDifference(DateTime guess) {
    double declination = eotDecl(guess)[1];
    double altitude = calcAltitude(
        shadowFactor: shadowFactor,
        declination: declination,
        latitude: latitude);
    Duration T = timedeltaAtAltitude(
        altitude: -altitude, declination: declination, latitude: latitude);
    DateTime actual;
    if (rising) {
      actual = zenith.subtract(T);
    } else {
      actual = zenith.add(T);
    }
    return actual.difference(guess);
  }

  DateTime guess1;
  DateTime guess2;
  if (rising) {
    guess1 = zenith.subtract(Duration(hours: 12));
    guess2 = zenith;
  } else {
    guess1 = zenith;
    guess2 = zenith.add(Duration(hours: 12));
  }
  return linearInterpolation(
      diffFunction: calcDifference, guess1: guess1, guess2: guess2);
}

void main(List<String> args) {
  eotDecl(DateTime.now());
}
