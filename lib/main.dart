import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'ZU2miFaAvBlBFdfkmyemNT3cNHiCwkoRme9SM6aM';
  final keyClientKey = 'QD27DmmeOsv1GYEoR7wISJZ9oV2lVvcpVHyakIHD';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(
    home: Home(),

  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final todoController = TextEditingController();
  final descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void addToDo() async {
    if (todoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
    }
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty description"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTodo(todoController.text, descriptionController.text);
    setState(() {
      todoController.clear();
      descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow,
      appBar: AppBar(
        title: Text("To-Do App",style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[700],
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.yellow,
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child:
              TextField(
                autocorrect: true,
                textCapitalization: TextCapitalization.sentences,
                controller: todoController,
                decoration: InputDecoration(
                    labelText: "To-Do",
                    labelStyle: TextStyle(color: Colors.black)),
              )),
          Container(
            color: Colors.yellow,
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child:
              TextField(
                autocorrect: true,
                textCapitalization: TextCapitalization.sentences,
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(color: Colors.black)),
                )),
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child:
              ElevatedButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.white,
                primary: Colors.brown,
              ),
              onPressed: addToDo,
              child: Text("ADD")
            )),
          Expanded(
              child: FutureBuilder<List<ParseObject>>(
                  future: getTodo(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: Container(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator()),
                        );
                      default:
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error..."),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("No Data..."),
                          );
                        } else {
                          return Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              padding: EdgeInsets.only(top: 10.0),
                              controller: _scrollController,
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                //*************************************
                                //Get Parse Object Values
                                final varTodo = snapshot.data![index];
                                String varTitle = varTodo.get<String>('title')!;
	                              String varDescription = varTodo.get<String>('description')!;
                                final varDone =  varTodo.get<bool>('done')!;
                                //*************************************

                                return ListTile(
                                  title: Text(varTitle),
                                  subtitle: Text(varDescription),
                                  leading: CircleAvatar(
                                    child: Icon(
                                        varDone ? Icons.check : Icons.assignment),
                                    backgroundColor:
                                        varDone ? Colors.green : Colors.black,
                                    foregroundColor: Colors.white,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                      ),
                                      onPressed: varDone ? null : () async {
                                        // Copy title and description to the TextFields
                                        todoController.text = varTitle;
                                        descriptionController.text = varDescription;
                                        await deleteTodo(varTodo.objectId!);
                                        setState(() {
                                          final snackBar = SnackBar(
                                            content: Text("Todo being edited!"),
                                            duration: Duration(seconds: 2),
                                          );
                                          ScaffoldMessenger.of(context)
                                            ..removeCurrentSnackBar()
                                            ..showSnackBar(snackBar);
                                        });
                                      },
                                      ),
                                      Checkbox(
                                          value: varDone,
                                          onChanged: (value) async {
                                            await updateTodo(
                                                varTodo.objectId!, value!);
                                            setState(() {
                                              //Refresh UI
                                            });
                                          }),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.black,
                                        ),
                                        onPressed: () async {
                                          await deleteTodo(varTodo.objectId!);
                                          setState(() {
                                            final snackBar = SnackBar(
                                              content: Text("Todo deleted!"),
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                );
                              }));
                        }
                    }
                  }))
        ]
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 50.0,
          color: Colors.yellow[700],
          child: Center(child: Text("Submission by Girish D Prabhu [2022MT93518]"))
          ),
      )
    );
  }

  Future<void> saveTodo(String title, String description) async {
    final todo = ParseObject('ToDoList')..set('title', title)..set('description', description)..set('done', false);
    await todo.save();
  }

  Future<List<ParseObject>> getTodo() async {
    QueryBuilder<ParseObject> queryTodo =
        QueryBuilder<ParseObject>(ParseObject('ToDoList'));
        queryTodo.orderByAscending('done');
    final ParseResponse apiResponse = await queryTodo.query();

    if (apiResponse.success && apiResponse.results != null) {
      print("results");
      print(apiResponse.results);
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> updateTodo(String id, bool done) async {
  var todo = ParseObject('ToDoList')
    ..objectId = id
    ..set('done', done);
  await todo.save();
  }

  Future<void> deleteTodo(String id) async {
  var todo = ParseObject('ToDoList')..objectId = id;
  await todo.delete();
  }

  Future<void> editTodo(String id, String title, String description) async {
  final todo = ParseObject('ToDoList')..objectId = id ..set('title', title)..set('description', description);
  await todo.save();
  }
}
