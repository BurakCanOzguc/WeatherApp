import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weatherapp/models/weather_model.dart';

class WeatherService {
  Future<String> _getLocation() async {
    //Kullanıcının konumu açık mı kontrol ettik.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    //isLocationServiceEnabled konum'un açık olup olmadığını kontrol eder.

    if (!serviceEnabled) {
      Future.error("Konum Servisi Kapalı");
    }
    //konum izni verilmiş mi kontrol ettik
    LocationPermission permission = await Geolocator.checkPermission();
    //checkPermission kulanıcının konum izni verip vermediğini kontrol eder.
    // izin verilmiyorsa denied kullanılır.
    if (permission == LocationPermission.denied) {
      //Konum ini verilmemişse izin istedik.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        //Yine izin verilmemişse hata döndürür.
        Future.error("Konum izni vermelisiniz");
      }
    }
    // Kullanıcının pozisyonunu aldık.
    final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // Kullanıcının kordinatlarını aldık, yerleşim noktasanı bulduk.
    final List<Placemark> placemark =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    // Şehrimizi yerleşim noktasından kaydettik.
    final String? city = placemark[0].administrativeArea;
    if (city == null) Future.error("Bir sorun oluştu");
    return city!;
  }

  Future<List<WeatherModel>> getWeatherData() async {
    final String city = await _getLocation();

    final String url =
        "https://api.collectapi.com/weather/getWeather?data.lang=tr&data.city=$city";
    const Map<String, dynamic> headers = {
      "authorization": "apikey 6xK4e9IOhMv0YwQ1fMdsbV:4BcGCNRC402UzTdHmnzgAU",
      "content-type": "application/json"
    };

    final dio = Dio();

    final response = await dio.get(url, options: Options(headers: headers));

    if (response.statusCode != 200) {
      return Future.error("Bir sorun Oluştu");
    }

    final List list = response.data['result'];

    final List<WeatherModel> weatherList =
        list.map((e) => WeatherModel.fromJson(e)).toList();

    return weatherList;
  }
}
