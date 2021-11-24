import "../BaseModel.dart";

class Postal {
  int id;
  String description;
  String location;
  String time;

  String toString() {
    return "{ id=$id, location=$location, description=$description, time=$time}";
  }
}

class PostalsModel extends BaseModel {
  get time => null;
  void triggerRebuild() {
    notifyListeners();
  }
}

PostalsModel postalsModel = PostalsModel();