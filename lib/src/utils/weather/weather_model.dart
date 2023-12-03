class Weather {
  final String cityName;
  final double temperature;
  final String condition;
  final String icon;

  Weather({
    required this.cityName,
    required this.temperature,
    required this.condition,
    required this.icon,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    //weather api
    return Weather(
      cityName: json['location']['name'],
      temperature: json['current']['temp_c'],
      condition: json['current']['condition']['text'],
      icon: json['current']['condition']['icon'],
    );
  }
}

class WeatherForecast {
  final String time;
  final double temperature;
  final String condition;
  final String icon;

  WeatherForecast({
    required this.time,
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}
