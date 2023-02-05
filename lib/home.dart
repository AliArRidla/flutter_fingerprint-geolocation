import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' show Client;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var latitude, longitude;
  @override
  Widget build(BuildContext context) {
    String location = 'Belum Mendapatkan Lat dan long, Silahkan tekan button';
    String address = 'Mencari lokasi...';
    Client client = Client();

    //posToServer
    Future<bool> posToServer(
        String checkInDate, String checkInTime, String lat, String long) async {
      final response = await client.post(
        Uri.parse("https://interactive.co.id/expe/get_test20230130.php"),
        body: {
          "apikey": "ali",
          "checkin_date": checkInDate,
          "checkin_time": checkInTime,
          "lat": lat,
          "long": long
        },
      );
      if (response.statusCode == 200) {
        print(response.body);
        print("sukses");
        return true;
      } else {
        print(response.body);
        print("gagal");
        return false;
      }
    }

    //getLongLAT
    Future<Position> _getGeoLocationPosition() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      //location service not enabled, don't continue
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return Future.error('Location service Not Enabled');
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permission denied');
        }
      }

      //permission denied forever
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
          'Location permission denied forever, we cannot access',
        );
      }
      //continue accessing the position of device
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    }

    final auth = LocalAuthentication();
    String authorized = " not authorized";
    bool _canCheckBiometric = false;
    late List<BiometricType> _availableBiometric;

    Future<void> _authenticate() async {
      bool authenticated = false;

      try {
        authenticated = await auth.authenticateWithBiometrics(
            localizedReason: "Scan your finger to authenticate",
            useErrorDialogs: true,
            stickyAuth: true);
      } on PlatformException catch (e) {
        print(e);
      }

      setState(() {
        authorized = authenticated ? "Test Berhasil" : "Test Gagal";
        print(authorized);
      });
    }

    Future<void> _checkBiometric() async {
      bool canCheckBiometric = false;

      try {
        canCheckBiometric = await auth.canCheckBiometrics;
      } on PlatformException catch (e) {
        print(e);
      }

      if (!mounted) return;

      setState(() {
        _canCheckBiometric = canCheckBiometric;
      });
    }

    Future _getAvailableBiometric() async {
      List<BiometricType> availableBiometric = [];

      try {
        availableBiometric = await auth.getAvailableBiometrics();
      } on PlatformException catch (e) {
        print(e);
      }

      setState(() {
        _availableBiometric = availableBiometric;
      });
    }

    @override
    void initState() {
      _checkBiometric();
      _getAvailableBiometric();
      super.initState();
    }

    return Scaffold(
      // backgroundColor: Colors.blueGrey.shade600,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                "Login",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 50.0),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15.0),
                    child: const Text(
                      "Login menggunakan fingerprint menggunakan library local_auth biometric",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green, height: 1.5),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Latitude  : $latitude"),
                        Text("Longitude : $longitude"),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CupertinoButton(
                      color: Colors.green,
                      // onPressed: _authenticate,
                      onPressed: () async {
                        Position position = await _getGeoLocationPosition();
                        setState(() {
                          latitude = position.latitude;
                          longitude = position.longitude;
                          if (latitude != null && longitude != null) {
                            _authenticate();
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.hand_raised_fill),
                          SizedBox(
                            width: 10,
                          ),
                          const Text('FINGERPRINT'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CupertinoButton(
                      color: Colors.green,
                      onPressed: () async {
                        Position position = await _getGeoLocationPosition();
                        var now = DateTime.now();
                        var tanggal = DateFormat('y-Md-d').format(now);
                        var waktu = DateFormat('H:mm:s').format(now);
                        posToServer(tanggal, waktu, '${position.latitude}',
                            '${position.longitude}');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.square_arrow_right_fill),
                          SizedBox(
                            width: 10,
                          ),
                          const Text('POST SERVER'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
