import "dart:io";
import "package:flutter/material.dart";
import "package:scoped_model/scoped_model.dart";
import "package:flutter_slidable/flutter_slidable.dart";
import "package:intl/intl.dart";
import "package:path/path.dart";
import '../avatar.dart';
import "../utils.dart" as utils;
import "postals_db_worker.dart";
import "postals_model.dart" show Postal, PostalsModel, postalsModel;
class PostalsList extends StatelessWidget {
  Widget build(BuildContext inContext) {
    return ScopedModel<PostalsModel>(
        model : postalsModel,
        child : ScopedModelDescendant<PostalsModel>(
            builder : (BuildContext inContext, Widget inChild, PostalsModel inModel) {
              return Scaffold(
                  floatingActionButton : FloatingActionButton(
                      child : Icon(Icons.add, color : Colors.white),
                      onPressed : () async {
                        File image = File(join(Avatar.docsDir.path, "image"));
                        if (image.existsSync()) {
                          image.deleteSync();
                        }
                        postalsModel.entityBeingEdited = Postal();
                        postalsModel.setChosenDate(null);
                        postalsModel.setStackIndex(1);
                      }
                  ),
                  body : ListView.builder(
                      itemCount : postalsModel.entityList.length,
                      itemBuilder : (BuildContext inBuildContext, int inIndex) {
                        Postal postal = postalsModel.entityList[inIndex];
                        File image = File(join(Avatar.docsDir.path, postal.id.toString()));
                        bool imageExists = image.existsSync();
                        return Column(
                            children : [
                              Slidable(
                                  actionPane: SlidableDrawerActionPane(),
                                  actionExtentRatio : .25,
                                  child : ListTile(
                                      leading : Image.file(
                                          File(join(Avatar.docsDir.path, postal.id.toString()))
                                      ),
                                      title : Text("${postal.description}"),
                                      subtitle : postal.location.toString() == null ? null : Text("Location ${postal.location.toString()}"),
                                      onTap : () async {
                                        File avatarFile = File(join(Avatar.docsDir.path, "image"));
                                        if (avatarFile.existsSync()) {
                                          avatarFile.deleteSync();
                                        }
                                        postalsModel.entityBeingEdited = await PostalsDBWorker.db.get(postal.id);
                                        if (postalsModel.entityBeingEdited.time == null) {
                                          postalsModel.setChosenDate(null);
                                        } else {
                                          List dateParts = postalsModel.entityBeingEdited.time.split(",");
                                          DateTime time = DateTime(
                                              int.parse(dateParts[0]), int.parse(dateParts[1]), int.parse(dateParts[2])
                                          );
                                          postalsModel.setChosenDate(DateFormat.yMMMMd("en_US").format(time.toLocal()));
                                        }
                                        postalsModel.setStackIndex(1);
                                      }
                                  ),
                                  secondaryActions : [
                                    IconSlideAction(
                                        caption : "Delete",
                                        color : Colors.red,
                                        icon : Icons.delete,
                                        onTap : () => _deleteContact(inContext, postal)
                                    )
                                  ]
                              ),
                              Divider()
                            ]
                        );
                      }
                  )
              );
            }
        )
    );

  }
///Re use of the delete code
  Future _deleteContact(BuildContext inContext, Postal inContact) async {
    return showDialog(
        context : inContext,
        barrierDismissible : false,
        builder : (BuildContext inAlertContext) {
          return AlertDialog(
              title : Text("Delete Postal"),
              content : Text("Are you sure you want to delete ${inContact.location}?"),
              actions : [
                FlatButton(child : Text("Cancel"),
                    onPressed: () {
                      // Just hide dialog.
                      Navigator.of(inAlertContext).pop();
                    }
                ),
                FlatButton(child : Text("Delete"),
                    onPressed : () async {
                      File avatarFile = File(join(Avatar.docsDir.path, inContact.id.toString()));
                      if (avatarFile.existsSync()) {
                        avatarFile.deleteSync();
                      }
                      await PostalsDBWorker.db.delete(inContact.id);
                      Navigator.of(inAlertContext).pop();
                      Scaffold.of(inContext).showSnackBar(
                          SnackBar(
                              backgroundColor : Colors.red,
                              duration : Duration(seconds : 2),
                              content : Text("Postal deleted")
                          )
                      );
                      postalsModel.loadData("contacts", PostalsDBWorker.db);
                    }
                )
              ]
          );
        }
    );
  }
}