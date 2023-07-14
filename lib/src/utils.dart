import 'package:intl/intl.dart';
import 'package:tabular/tabular.dart';

void printPrayerTimes(Map<String,DateTime> prayertimes){

  List<List<dynamic>> tableData = [];
  tableData.add(["Name", "Time"]);

  prayertimes.forEach((key, value) {
    String offset = value.timeZoneOffset.inHours > 0
        ? "+${value.timeZoneOffset.inHours}"
        : value.timeZoneOffset.inHours.toString();

    String formattedTime =
        "${DateFormat.yMMMMd().format(value)}  ${DateFormat.Hms().format(value)}  $offset";
    
    tableData.add([key, formattedTime]); // Add prayer name and formatted time to table data
  });

  var string = tabular(tableData); // Generate formatted table string
  print(string);
}