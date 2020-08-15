import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
class entites extends StatefulWidget {
  @override
  _entitesState createState() => _entitesState();
}
class _entitesState extends State<entites> {
  var url = 'http://192.168.137.1:8090/api/Entreprise';
  TextEditingController mycontrolleur = TextEditingController();
   List<dynamic> list = List();

  @override
  void initState() {
    super.initState();
    getEntites("").then((value) {
      setState(() =>  list= value);
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyanAccent,
        title: TextField(
          cursorColor: Colors.white,
          decoration: new InputDecoration(
              hintText: "Searche"),
          controller: mycontrolleur,
          style:
          TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
          onChanged: (text) {
            getEntites(text).then((resultat){
              setState(() {
                list = resultat;
                listview();
              });
              });
            }
        ),
        elevation: 0,
      ),
      body:listview()
      );
  }
Widget listview(){
    return  ListView.builder(
        itemCount: list.length,
        itemBuilder:(context,index){
          return Card(
            child: ListTile(
              title: Text(list[index]["nom"]),
              onTap: (){
                Navigator.pop(context, list[index]["id"]);
              },
            ),
          );
        });
}
  Future<dynamic> getEntites(String start) async{
   var json;
   var response = await http.get(url);
   if (response.statusCode == 200) {
     json = convert.jsonDecode(response.body);
   } else {
     print('Request failed with status: ${response.statusCode}.');
   }
   if(identical(start,"")){
     return json;
   }
   else{
     List<dynamic> list2 = List();
     for(int i=0;i<json.length;i++){
       if(json[i]["nom"].toString().length >= start.length)
       if(json[i]["nom"].substring(0,start.length).toString().compareTo(start.toLowerCase())==0){
         list2.add(json[i]);
       }
     }
     return list2;
   }
  }
  }

