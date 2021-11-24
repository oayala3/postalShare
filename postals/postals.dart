import "package:flutter/material.dart";
import "package:scoped_model/scoped_model.dart";
import "postals_db_worker.dart";
import "postals_list.dart";
import "postals_entry.dart";
import "postals_model.dart" show PostalsModel, postalsModel;

///Postals creation
class Postals extends StatelessWidget{
  Postals(){
    postalsModel.loadData("appointments",PostalsDBWorker.db);
  }

  @override
  Widget build(BuildContext inContext) {
    return ScopedModel<PostalsModel>(
        model : postalsModel,
        child : ScopedModelDescendant<PostalsModel>(
            builder : (BuildContext inContext, Widget inChild, PostalsModel inModel) {
              return IndexedStack(
                  index : inModel.stackIndex,
                  children : [
                    PostalsList(),
                    PostalsEntry()
                  ]
              );
            }
        )
    );
  }
}