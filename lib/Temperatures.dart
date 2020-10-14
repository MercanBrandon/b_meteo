
class Temperature {

  String main;
  String description;
  String icon;
  var temp;
  var temp_min;
  var temp_max;
  var pressure;
  var humidity;
  var windSpeed;
  var windDirection;
  var timestamp;



  Temperature(Map map) {
    List weather = map['weather'];
    Map weatherMap = weather.first;
    this.main = weatherMap["main"];
    this.description = weatherMap["description"];
    this.icon = weatherMap["icon"];
    Map mainMap = map["main"];
    this.temp = mainMap["temp"].toInt();
    this.temp_min = mainMap["temp_min"].toInt();
    this.temp_max = mainMap["temp_max"].toInt();
    this.pressure = mainMap["pressure"];
    this.humidity = mainMap["humidity"];
    Map windMap = map["wind"];
    this.windSpeed = windMap["speed"];
    this.windDirection = windMap["deg"];
    this.timestamp = weatherMap["dt"];


  }
}