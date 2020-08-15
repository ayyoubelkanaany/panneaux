import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'entites.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/' : (context) => MyHomePage(),
        '/ajouter_panneau' : (context) => entites(),
      },
    );
}}
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}
class _MyHomePageState extends State<MyHomePage> {
  var url = 'http://192.168.137.1:8090/api/';
  int o=3;
  List<dynamic> list = List();
  List<Marker> markers = List<Marker>();
  TextEditingController mycontrolleur1 = TextEditingController();
  LatLng currentLatLng;
  List<LatLng> tappedPoints = [];
  LocationData _currentLocation;
  MapController _mapController;
  LatLng guide_position;
  bool _liveUpdate = true;
  bool _permission = false;

  String _serviceError = '';
  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    initLocationService();
    getPanneaux();
  }
  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.HIGH,
      interval: 1000,
    );
    LocationData location;
    bool serviceEnabled;
    bool serviceRequestResult;
    try {
      serviceEnabled = await _locationService.serviceEnabled();
      if (serviceEnabled) {
        var permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.GRANTED;
        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationService
              .onLocationChanged()
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;

                // If Live Update is enabled, move map center
                if (_liveUpdate) {
                _mapController.move(LatLng(_currentLocation.latitude, _currentLocation.longitude), 20);
               }
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      print(e);
      if (e.code == 'PERMISSION_DENIED') {
        ///print("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk8");
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        ///print("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk9");
        _serviceError = e.message;
      }
      location = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation.latitude, _currentLocation.longitude);
    } else {
      currentLatLng = LatLng(0, 0);
    }
    var marker = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: currentLatLng,
        builder: (ctx) =>
            Container(
              child: Icon(
                Icons.accessibility, color: Colors.redAccent, size: 60,),
            )
      ),
    ];

    return  Scaffold(
        body: Column(
          children: [
            Flexible(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                    center: LatLng(
                        currentLatLng.latitude, currentLatLng.longitude),
                    zoom: 16,
                    onLongPress: _handleTap,

                ),
                layers: [
                  new TileLayerOptions(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c']
                  ),
                  MarkerLayerOptions(markers: marker),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
    );
  }
  void _handleTap(LatLng latlng) {
    Navigator.pushNamed(context, "/ajouter_panneau").then((value) async {
      if(!(value.toString().compareTo("null") == 0)) {
        ////ajout de panneau
        Map<String, String> headers1 = {"Content-type": "application/json"};
        String panneau = '{"etat":${2}, "latitude": ${currentLatLng
            .latitude}, "longitude": ${currentLatLng.longitude}}';
        var response1 = await http.post(
            url + 'new/Panneau', headers: headers1, body: panneau);
        if (response1.statusCode == 200) {
          ////ajout de location
          String location = '{"date_debut": null , "date_fin" : null, "entreprise" :$value ,"panneau" : ${response1.body}}';
          var response2 = await http.post(
              url + 'new/Location', headers: headers1, body: location);
          if (response2.statusCode == 200) {
            confirmation(context, "le panneau est bien ajouter",Colors.cyanAccent);
          }

        }else {
          confirmation(context, "le panneau n'est pas ajouter",Colors.redAccent);
        }
        getPanneaux();
      }
    });
  }
  Future<dynamic> getPanneaux() async {
    var response = await http.get(url+'Location');
    if (response.statusCode == 200) {
      var json = jsonDecode(response.body);
      print(json);
        for (int i = 0; i < json.length; i++) {
          String panneau;
          if(json[i]["panneau"]["etat"] == 1){
            panneau = "assets/Images/green.jpg";
          }
          else if(json[i]["panneau"]["etat"] == 0){
            panneau = "assets/Images/red.jpg";
          }
          else{
            panneau = "assets/Images/black.jpeg";
          }
          markers.add(
              new Marker(
                  width: 100.0,
                  height: 100.0,
                  point: LatLng(json[i]["panneau"]["latitude"], json[i]["panneau"]["longitude"]),
                  builder: (ctx) =>
                    Container(
                          child: IconButton(
                             icon: Image.asset(panneau),
                             onPressed: (){
                               change_entite(context,json[i]["panneau"]["id"]);
                            },
                          )
                    )
              ));
        }
    }
  }
  Future<String> change_entite(BuildContext context,int id) async {
    var response = await http.get(url+'Location/1/$id');
    var json;
    if (response.statusCode == 200) {
      json = jsonDecode(response.body);
      //print(json["entreprise"]["nom"]);
    return showDialog(context: context,builder:(contextd){
      return AlertDialog(
        title: Text("Entite",style: TextStyle(color: Colors.black54,),),
        content: TextField(
          controller: mycontrolleur1..text = json != null ? '${json["entreprise"]["nom"]}': 'introvable',
        ),
        actions: [
          MaterialButton(
            onPressed: () async {
              Navigator.of(context).pop();
              Navigator.pushNamed(contextd, "/ajouter_panneau").then((value) async {
                if(!(value.toString().compareTo("null") == 0)) {
                  ////ajout de panneau
                  Map<String, String> headers1 = {"Content-type": "application/json"};
                  String location = '{"date_debut": null , "date_fin" : null, "entreprise" :$value ,"panneau" : ${json["panneau"]["id"]}}';

                  var response1 = await http.put(
                      url + 'update/Location', headers: headers1, body: location);
                  if (response1.statusCode == 200) {
                    confirmation(context, "panneau bien modifier", Colors.cyanAccent);

                }
                  else{
                    confirmation(context, "panneau bien modifier", Colors.redAccent);
                  }
                }
              });
              getPanneaux();
            },
            child: Text("Modifier",style: TextStyle(color: Colors.black54,),),
          ),
          MaterialButton(
              onPressed: (){
                Navigator.of(contextd).pop();
              },
              child: Text("Annuler",style: TextStyle(color: Colors.black54,),)
          ),
        ],
      );
    });
  }
  }
  Future<String> confirmation(BuildContext context,String text,Color color){
    return showDialog(context: context,builder:(context){
      return AlertDialog(
        backgroundColor: color,
        title: Text("confirmation",style: TextStyle(color: Colors.white,),),
        content: Text(text,style: TextStyle(color: Colors.white,),),
        actions: [
          MaterialButton(
            onPressed: (){
              Navigator.of(context).pop(mycontrolleur1.text.toString());
            },
            child: Text("fermer",style: TextStyle(color: Colors.white),),
          ),
        ],
      );
    });
  }
}

