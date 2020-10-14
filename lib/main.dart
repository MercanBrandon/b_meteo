import 'package:b_meteo/Temperatures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:geocoder/geocoder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttericon/meteocons_icons.dart';
import 'package:fluttericon/entypo_icons.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  String title = 'B-Météo';
  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);

    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String key = "villes";
  List<String> villes = [];
  String villeChoisi ;
  Coordinates coordsVilleChoisi;
  Color uiColor;

  Temperature temperature;

  Location location;
  LocationData locationData;
  Stream<LocationData> stream;
  String nameCurrent;

  AssetImage night = AssetImage('assets/n.jpg');
  AssetImage sun = AssetImage('assets/d1.jpg');
  AssetImage rain = AssetImage('assets/d2.jpg');



  @override
  void initState() {
    super.initState();
    obtenir();
    location = new Location();
    getFirstLocation();
    listenToStream();
    uiColor = Colors.amber;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: uiColor,
        centerTitle: true,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: Container(
          color: uiColor,
          child: ListView.builder(
            itemCount: villes.length+2,
              itemBuilder: (context, i) {
                if(i == 0){
                  return DrawerHeader(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Mes villes', textScaleFactor: 1.2, style: TextStyle(color: Colors.white)),
                        RaisedButton(
                          child: Text('Ajouter une ville', style: TextStyle(color: uiColor)),
                            color: Colors.white,
                            elevation: 8.0,
                            onPressed: ajoutVille
                        )
                      ],
                    ),
                  );
                }else if (i == 1 ){
                  return ListTile(
                    title: Text("Ma ville actuelle ($nameCurrent)", style: TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        villeChoisi = null;
                        coordsVilleChoisi = null;
                        getFirstLocation();
                        Navigator.pop(context);
                      });
                    },
                  );
                }else{
                  String ville = villes[i-2];
                  return ListTile(
                    title: Text(ville, style: TextStyle(color: Colors.white),),
                    onTap: () {
                      setState(() {
                        villeChoisi = ville;
                        coordsFromCity();
                        Navigator.pop(context);
                      });
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white,),
                      onPressed: (() => supprimer(ville)),
                    ),
                  );
                }
              }),
        ),
      ),
      body: Center(
        child: (temperature == null)
        ? Text((villeChoisi == null)? "Ville Actuelle" : villeChoisi)
        : Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            image: DecorationImage(image: getBackground(), fit: BoxFit.cover)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (villeChoisi == null) ? "Ville Actuelle " : villeChoisi,
                    textScaleFactor: 2.0,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                    (villeChoisi == null) ? '(${nameCurrent})' : '',
                    textScaleFactor: 1.5,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold
                    ),
                  )
                ],
              ),
              Text(
                temperature.description,
                textScaleFactor: 1.7,
                style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  new Image(image: getIcon(),),
                  Text(
                    '${temperature.temp} °C',
                    textScaleFactor: 3.5,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.white, size: 30,),
                      Padding(padding: EdgeInsets.all(7),),
                      Text(
                        '${temperature.temp_min} °C',
                          textScaleFactor: 1.5,
                          style: TextStyle(color: Colors.white,)
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.white, size: 30,),
                      Padding(padding: EdgeInsets.all(7),),
                      Text(
                        '${temperature.temp_max} °C',
                          textScaleFactor: 1.5,
                          style: TextStyle(color: Colors.white,)
                      )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Meteocons.temperature, color: Colors.white, size: 30,),
                      Padding(padding: EdgeInsets.all(7),),
                      Text(
                        '${temperature.pressure} hPa',
                        textScaleFactor: 1.5,
                        style: TextStyle(color: Colors.white,)
                        )
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Entypo.droplet, color: Colors.white, size: 30,),
                      Padding(padding: EdgeInsets.all(7),),
                      Text(
                        '${temperature.humidity} %',
                        textScaleFactor: 1.5,
                        style: TextStyle(color: Colors.white, ),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> ajoutVille() async{
    return showDialog(
        context: context,
      barrierDismissible: true,
      builder: (BuildContext buildcontext) {
          return new SimpleDialog(
            contentPadding: EdgeInsets.all(20),
            title: Text("Ajouter une ville", style: TextStyle(color: Colors.blue, fontSize: 22),),
            children: [
              TextField(
                decoration: InputDecoration(labelText: "ville:"),
                onSubmitted: (String str) {
                  ajouter(str);
                  Navigator.pop(buildcontext);
                },
              )
            ],
          );
      }
    );
  }

  // SharePreferences
  void obtenir() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    List<String> liste = await sharedPreferences.getStringList(key);
    if(liste != null){
      setState(() {
        villes = liste;
      });
    }
  }

  void ajouter(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.add(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
  }

  void supprimer(String str) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    villes.remove(str);
    await sharedPreferences.setStringList(key, villes);
    obtenir();
  }



  // User Interface
  void setUiColor(){
    if (temperature.icon.contains("n")){
      setState(() {
        uiColor = Colors.blue[800];
      });
    }else{
      if((temperature.icon.contains("01")) || (temperature.icon.contains("02")) || (temperature.icon.contains("03"))){
        setState(() {
          uiColor = Colors.deepOrange;
        });
      }else{
        setState(() {
          uiColor = Colors.teal;
        });
      }
    }
  }

  AssetImage getBackground() {
    print(temperature.icon);
    if (temperature.icon.contains("n")){
      return night;
    }else {
      if ((temperature.icon.contains("01")) ||  (temperature.icon.contains("02")) || (temperature.icon.contains("03"))) {
          return sun;
      }else{
        return rain;
      }
    }
  }

  AssetImage getIcon() {
    String icon = temperature.icon.replaceAll('d', '').replaceAll('n', '');
    return AssetImage("assets/${icon}.png");
  }


  // Location
  getFirstLocation() async{
    try{
      locationData = await location.getLocation();
      locationToString();
    }catch(e){
      print('Nous avons une erreur : $e');
    }
  }

  listenToStream() {
    stream = location.onLocationChanged;
    stream.listen((newPosition) {
      if((locationData == null) || (newPosition.longitude == locationData.longitude) && (newPosition.latitude == locationData.latitude)){
        print("New  => ${newPosition.latitude} ------- ${newPosition.longitude}");
        locationData = newPosition;
        locationToString();
      }
    });
  }


  // Geocoder
  locationToString() async {
    if(locationData != null) {
      Coordinates coordinates = new Coordinates(locationData.latitude, locationData.longitude);
      final cityName = await Geocoder.local.findAddressesFromCoordinates(coordinates);
      setState(() {
        nameCurrent = cityName.first.locality;
      });
      api();

    }
  }

  coordsFromCity() async {
    if (villeChoisi != null) {
      List<Address> addresses = await Geocoder.local.findAddressesFromQuery(villeChoisi);
      if(addresses.length > 0){
        Address first = addresses.first;
        Coordinates coords = first.coordinates;
        print(coords);
        setState(() {
          coordsVilleChoisi = coords;
          api();
        });
      }
    }
  }

  api() async {
    double lat;
    double lon;
    if (coordsVilleChoisi != null){
      lat = coordsVilleChoisi.latitude;
      lon = coordsVilleChoisi.longitude;
    }else if(locationData != null){
      lat = locationData.latitude;
      lon = locationData.longitude;
    }

    if(lat != null && lon != null) {
      // http://api.openweathermap.org/data/2.5/weather?lat=48,8392874&lon=2,4952678&units=metrics&lang=en&appid=25b113a99214d1d4e8cf13381fa50009
      String baseApi = 'http://api.openweathermap.org/data/2.5/weather?';
      final key = '&appid=25b113a99214d1d4e8cf13381fa50009';
      String lang = '&lang=${Localizations.localeOf(context).languageCode}';
      String coordsString = 'lat=$lat&lon=$lon&units=metric';
      String URI = baseApi+coordsString+lang+key;

      print(URI);

      final response = await http.get(URI);
      if (response.statusCode == 200){
        Map map = json.decode(response.body);
        setState(() {
          temperature = new Temperature(map);
          setUiColor();
          print(temperature.description);
        });
      }
    }
  }
}

