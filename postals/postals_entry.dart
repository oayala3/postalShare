import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import "package:path/path.dart";
import "package:scoped_model/scoped_model.dart";
import "package:image_picker/image_picker.dart";
import '../avatar.dart';
import "../utils.dart" as utils;
import 'package:location/location.dart';
import "postals_db_worker.dart";
import "postals_model.dart" show PostalsModel, postalsModel;

class PostalsEntry extends StatelessWidget {

  final TextEditingController _locationEditingController = TextEditingController();
  final TextEditingController _descriptionEditingController = TextEditingController();
  final TextEditingController _timeEditingController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _locationData;

  PostalsEntry() {
    _descriptionEditingController.addListener(() {
      postalsModel.entityBeingEdited.description = _descriptionEditingController.text;
    });
    _descriptionEditingController.addListener(() {
      postalsModel.entityBeingEdited.location = _locationData;
    });
    _timeEditingController.addListener(() {
      postalsModel.entityBeingEdited.time = _timeEditingController.text;
    });
  }
  ///Update the Location and check if there is permission
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
    _locationData="Longitud ${locationData.longitude}. Latitude ${locationData.latitude} ";
    print(_locationData);
  }

  Widget build(BuildContext inContext) {
    if (postalsModel.entityBeingEdited != null) {
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
                                onPressed : () { _delete(inContext, inModel); }
                            )
                          ]
                      )),
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
                                onPressed : () { _updateLocation(); }
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
                              var cameraImage = await ImagePicker.pickImage(source: ImageSource.camera);
                              if (cameraImage != null) {
                                cameraImage.copySync(
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