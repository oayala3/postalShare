import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "package:path/path.dart";
import "package:scoped_model/scoped_model.dart";
import "package:image_picker/image_picker.dart";
import '../avatar.dart';
import "../utils.dart" as utils;
import 'package:location/location.dart';
import 'map.dart';
import "postals_db_worker.dart";
import "postals_model.dart" show PostalsModel, postalsModel;
import 'package:image/image.dart' as img;


class PostalsEntry extends StatelessWidget {

  var _newCameraPosition=CameraPosition(
    target: LatLng(370,-122),
    zoom: 11.5,);

  GoogleMapController _googleMapController;
  Marker _origin;
  Marker _destination;
  @override
  void dispose(){
    _googleMapController.dispose();
  }
  final TextEditingController _locationEditingController = TextEditingController();
  final TextEditingController _descriptionEditingController = TextEditingController();
  final TextEditingController _timeEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _locationData;
  var _location;

  PostalsEntry() {
    _descriptionEditingController.addListener(() {
      postalsModel.entityBeingEdited.description = _descriptionEditingController.text;
    });
    _locationEditingController.addListener(() {
      postalsModel.entityBeingEdited.location = _locationData;
    });
    _timeEditingController.addListener(() {
      postalsModel.entityBeingEdited.time = _timeEditingController.text;
    });
  }
  ///Update the Location and check if there is permission

  CameraPosition _initialPosition(){
    var start;
    print(postalsModel.entityBeingEdited.location.toString());
    if(postalsModel.entityBeingEdited.location!=null){
      print("not null");
      start = CameraPosition(
          target: LatLng(double.parse(postalsModel.entityBeingEdited.location.split(":")[3]),double.parse(postalsModel.entityBeingEdited.location.split(":")[1])),
          zoom: 11.5);
    }else{
      print("VERY null");
      start = CameraPosition(
          target: LatLng(37,-122),
          zoom: 11.5);
    }
    return start;
  }
  _updateLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
      }
    }
    var locationData = await location.getLocation();
    _location = locationData;
    _locationData="Longitud: ${locationData.longitude}: Latitude: ${locationData.latitude}:";
    print(_locationData);
    var newPosition = CameraPosition(
        target: LatLng(locationData.latitude, locationData.longitude),
        zoom: 16);
    CameraUpdate update =CameraUpdate.newCameraPosition(newPosition);
    CameraUpdate zoom = CameraUpdate.zoomTo(16);

    _googleMapController.moveCamera(update);
  }

  Widget build(BuildContext inContext) {
    if (postalsModel.entityBeingEdited != null) {
      print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");print("HERE");
      print("printing location of postal model ${postalsModel.entityBeingEdited.location.toString()}");
      _descriptionEditingController.text = postalsModel.entityBeingEdited.description;
      _locationData = postalsModel.entityBeingEdited.location;
      _timeEditingController.text = postalsModel.entityBeingEdited.time;
    }
    return ScopedModel(
        model : postalsModel,
        child : ScopedModelDescendant<PostalsModel>(
            builder : (BuildContext inContext, Widget inChild, PostalsModel inModel) {
              File image = File(join(Avatar.docsDir.path, "image"));
              if (image.existsSync() == false) {
                if (inModel.entityBeingEdited != null && inModel.entityBeingEdited.id != null) {
                  image = File(join(Avatar.docsDir.path, inModel.entityBeingEdited.id.toString()));
                }
              }
              return Scaffold(
                  bottomNavigationBar : Padding(
                      padding : EdgeInsets.symmetric(vertical : 0, horizontal : 10),
                      child : Row(
                          children : [
                            FlatButton(
                                child : Text("Cancel"),
                                onPressed : () {
                                  File image = File(join(Avatar.docsDir.path, "image"));
                                  if (image.existsSync()) {
                                    image.deleteSync();
                                  }
                                  FocusScope.of(inContext).requestFocus(FocusNode());
                                  inModel.setStackIndex(0);
                                }
                            ),
                            Spacer(),
                            FlatButton(
                                child : Text("Save"),
                                onPressed : () { _save(inContext, inModel); }
                            ),
                            FlatButton(
                                child : Text("Delete"),
                                onPressed : () {},
                            ),

                          ]
                      ),
                   ),
                  body : Form(
                      key : _formKey,
                      child : ListView(
                          children : [
                            ListTile(
                                title : image.existsSync() ? Image.file(image) : Text("No image for this the Postal"),
                                trailing : IconButton(
                                    icon : Icon(Icons.edit),
                                    color : Colors.blue,
                                    onPressed : () => _selectImage(inContext)
                                )
                            ),
                            ListTile(
                                leading : Icon(Icons.description),
                                title : TextFormField(
                                    keyboardType : TextInputType.multiline,
                                    maxLines : 4,
                                    decoration : InputDecoration(hintText : "Description"),
                                    controller : _descriptionEditingController,
                                    validator : (String inValue) {
                                      if (inValue.length == 0) { return "Please enter a description"; }
                                      return null;
                                    }
                                )
                            ),
                            ListTile(
                                leading : Icon(Icons.today),
                                title : Text("Date Taken"),
                                subtitle : Text(postalsModel.chosenDate == null ? "" : postalsModel.chosenDate),
                                trailing : IconButton(
                                    icon : Icon(Icons.edit), color : Colors.blue,
                                    onPressed : () async {
                                      String chosenDate = await utils.selectDate(
                                          inContext, postalsModel, postalsModel.entityBeingEdited.time
                                      );
                                      if (chosenDate != null) {
                                        postalsModel.entityBeingEdited.time = chosenDate;
                                      }
                                    }
                                )
                            ),
                            FlatButton(
                                child : Text("UpedateLocation"),
                                onPressed : (){
                                  //Navigator.push(
                                   // inContext,
                                   // MaterialPageRoute(builder: (context) => MapScreen()),
                                 // );
                                _updateLocation();
                                print("updatingLocaion");
                                ()=>_googleMapController.animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
                                }
                            ),
                            SizedBox(
                                width: 500,  // or use fixed size like 200
                                height: 300,
                                child : GoogleMap(
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    initialCameraPosition: _initialPosition(),
                                    onMapCreated: (controller) =>_googleMapController= controller,
                                    markers:{
                                      if(_origin != null) _origin,
                                      if(_destination != null) _destination
                                    },
                                )
                            ),
                          ]
                      )
                  )
              );
            }
        )
    );

  }
  ///Take picture and join with the Postal
  Future _selectImage(BuildContext inContext) {
    return showDialog(context: inContext,
        builder: (BuildContext inDialogContext) {
          return AlertDialog(
              content: SingleChildScrollView(
                  child: ListBody(
                      children: [
                        GestureDetector(
                            child: Text("Take a picture"),
                            onTap: () async {
                              final _picker = ImagePicker();
                              PickedFile image = await _picker.getImage(source: ImageSource.camera);
                              File file = File(image.path);
                              if (image != null) {
                                file.copySync(
                                    join(Avatar.docsDir.path, "image"));
                                postalsModel.triggerRebuild();
                              }
                              Navigator.of(inDialogContext).pop();
                            }
                        ),
                      ]
                  )
              )
          );
        }
    );
  }
  ///Save the postal by sending the recorded parameters to databse
  void _save(BuildContext inContext, PostalsModel inModel) async {
    _updateLocation();
    if (!_formKey.currentState.validate()) { return; }
    var id;
    if (inModel.entityBeingEdited.id == null) {
      postalsModel.entityBeingEdited.location = _locationData;
      id = await PostalsDBWorker.db.create(postalsModel.entityBeingEdited);
    } else {
      id = postalsModel.entityBeingEdited.id;
      postalsModel.entityBeingEdited.location = _locationData;
      await PostalsDBWorker.db.update(postalsModel.entityBeingEdited);

    }
    File image = File(join(Avatar.docsDir.path, "image"));
    if (image.existsSync()) {
      image.renameSync(join(Avatar.docsDir.path, id.toString()));
    }
    postalsModel.loadData("Postals", PostalsDBWorker.db);
    inModel.setStackIndex(0);
    Scaffold.of(inContext).showSnackBar(
        SnackBar(
            backgroundColor : Colors.green,
            duration : Duration(seconds : 2),
            content : Text("Postal saved")
        )
    );
  }
  ///call delete from database
  void _delete(BuildContext inContext, PostalsModel inModel) async {
    var id;
    if (inModel.entityBeingEdited.id == null) {
      await PostalsDBWorker.db.delete(postalsModel.entityBeingEdited.id);
      print("delete");
    } else {
      id = postalsModel.entityBeingEdited.id;
      postalsModel.entityBeingEdited.location = _locationData;
      await PostalsDBWorker.db.delete(postalsModel.entityBeingEdited.id);
      print("delete2");

    }
    Scaffold.of(inContext).showSnackBar(
        SnackBar(
            backgroundColor : Colors.green,
            duration : Duration(seconds : 2),
            content : Text("Postal Deleted")
        )
    );
  }
}