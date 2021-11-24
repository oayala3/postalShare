import "dart:io";
import "package:flutter/material.dart";
import 'appointments/appointments.dart';
import 'avatar.dart';
import "notes/notes.dart";
import "tasks/tasks.dart";
import "contacts/contacts.dart";
import "postals/postals.dart";
import "utils.dart" as utils;
import 'package:path_provider/path_provider.dart';


void main() async {
  startMeUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    Avatar.docsDir = await getApplicationDocumentsDirectory();
    runApp(FlutterBook());
  }
  startMeUp();
}


class _Dummy extends StatelessWidget {
  final _title;

  _Dummy(this._title);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(_title));
  }
}

class FlutterBook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.blue),
        home: DefaultTabController(
            length: 5,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Oscar Ayala FlutterBook'),
                    bottom: TabBar(
                        tabs: [
                          Tab(icon: Icon(Icons.date_range), text: 'Appointments'),
                          Tab(icon: Icon(Icons.contacts), text: 'Contacts'),
                          Tab(icon: Icon(Icons.note), text: 'Notes'),
                          Tab(icon: Icon(Icons.assignment_turned_in), text: 'Tasks'),
                          Tab(icon: Icon(Icons.assignment_turned_in), text: 'Postals'),
                        ]
                    )
                ),
                body: TabBarView(
                    children: [
                      Appointments(),
                      Contacts(),
                      Notes(),
                      Tasks(),
                      Postals(),
                    ]
                )
            )
        )
    ); }  }


