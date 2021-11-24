import "package:path/path.dart";
import "package:sqflite/sqflite.dart";
import '../avatar.dart';
import "../utils.dart" as utils;
import "postals_model.dart";
class PostalsDBWorker {

  PostalsDBWorker._();
  static final PostalsDBWorker db = PostalsDBWorker._();
  Database _db;
  Future get database async {
    if (_db == null) {
      _db = await init();
    }
    return _db;
  }

  Future<Database> init() async {
    String path = join(Avatar.docsDir.path, "postals.db");
    Database db = await openDatabase(path, version : 1, onOpen : (db) { },
        onCreate : (Database inDB, int inVersion) async {
          await inDB.execute(
              "CREATE TABLE IF NOT EXISTS postals ("
                  "id INTEGER PRIMARY KEY,"
                  "description TEXT,"
                  "time TEXT,"
                  "location TEXT"
                  ")"
          );
        }
    );
    return db;
  }

  Postal postalFromMap(Map inMap) {
    Postal postal = Postal();
    postal.id = inMap["id"];
    postal.description = inMap["description"];
    postal.time = inMap["time"];
    postal.location = inMap["location"];
    return postal;
  }

  Map<String, dynamic> postalToMap(Postal inPostal) {
    Map<String, dynamic> map = Map<String, dynamic>();
    map["id"] = inPostal.id;
    map["description"] = inPostal.description;
    map["time"] = inPostal.time;
    map["location"] = inPostal.location;
    return map;
  }
/// Create postal in database
  Future create(Postal inPostal) async {
    Database db = await database;
    var val = await db.rawQuery("SELECT MAX(id) + 1 AS id FROM postals");
    int id = val.first["id"];
    if (id == null) { id = 1; }
    return await db.rawInsert(
        "INSERT INTO postals (id, description, time, location) VALUES ( ?, ?, ?, ?)",
        [
          id,
          inPostal.description,
          inPostal.time,
          inPostal.location
        ]
    );
  }
/// Get postal from database with ID
  Future<Postal> get(int inID) async {
    Database db = await database;
    var rec = await db.query("postals", where : "id = ?", whereArgs : [ inID ]);
    return postalFromMap(rec.first);
  }
/// Get all postals from database
  Future<List> getAll() async {
    Database db = await database;
    var recs = await db.query("postals");
    var list = recs.isNotEmpty ? recs.map((m) => postalFromMap(m)).toList() : [ ];
    return list;

  }
///Update a postal with ID
  Future update(Postal inAppointment) async {
    Database db = await database;
    return await db.update(
        "postals", postalToMap(inAppointment), where : "id = ?", whereArgs : [ inAppointment.id ]
    );

  }
///Delete a postal with ID
  Future delete(int inID) async {
    Database db = await database;
    return await db.delete("postals", where : "id = ?", whereArgs : [ inID ]);
  }
}