import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

main() {
	runApp(MaterialApp(
		home: Home(),
	));
}


class Home extends StatefulWidget {
	@override
	_HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
	var _toDoController = TextEditingController();
	var _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  var _lastRemovedPos;

	@override
	initState() {
		super.initState();

		_readData().then((data) => {
			setState((){
				_toDoList = json.decode(data);
			})
		});
	}
	
	_addToDo(){
		setState(() {
		  Map<String, dynamic> newToDo = Map();
			newToDo['title'] = _toDoController.text;
			_toDoController.text = '';
			newToDo['ok'] = false;
			_toDoList.add(newToDo);
			_saveData();
		});
	}

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if (a['ok'] && !b['ok']) return 1;
        else if (!a['ok'] && b['ok']) return -1;
        else return 0;
      });
      _saveData();
    });

    return null;
  }

  _clearList() {
    setState(() {
      _toDoList = [];
      _saveData();
    });
  }
	
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: Text("Lista de tarefas"),
				backgroundColor: Colors.blueAccent,
				centerTitle: true,
			),
			body: Column(
				children: <Widget>[
					Container(
						padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
						child: Row(
							children: <Widget>[
								Expanded(
									child: TextField(
										decoration: InputDecoration(
											labelText: "Nova tarefa 😏",
											labelStyle: TextStyle(color: Colors.blueAccent)
										),
										controller: _toDoController,
									),
								),
								RaisedButton(
									color: Colors.blueAccent,
									child: Text("ADD"),
									textColor: Colors.white,
									onPressed: _addToDo,
								),
								RaisedButton(
									color: Colors.redAccent,
									child: Text("Clear"),
									textColor: Colors.white,
									onPressed: _clearList,
								),
							],
						),
					),
					Expanded(
						child: RefreshIndicator(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 10),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
						  ),
              onRefresh: _refresh
            )
					)
				],
			),
		);
	}

	Widget buildItem(context, index){
		return Dismissible(
			key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
			background: Container(
				color: Colors.red,
				child: Align(
					alignment: Alignment(-0.9, 0),
					child: Icon(Icons.delete, color: Colors.white),
				),
			),
			direction: DismissDirection.startToEnd,
			child: CheckboxListTile(
				title: Text(_toDoList[index]['title']),
				value: _toDoList[index]['ok'],
				secondary: CircleAvatar(
					child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
				),
				onChanged: (c){
					setState(() {
					_toDoList[index]['ok'] = c;
					_saveData();
					});
				},
			),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("A tarefa \"${_lastRemoved["title"]}\" foi removida"),
            action: SnackBarAction(label: "Desfazer", onPressed: (){
              setState(() {
                _toDoList.insert(_lastRemovedPos, _lastRemoved);
                _saveData();
              });
              },
            ),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).showSnackBar(snack);
        });
      },
		);
	}
		
	
	Future<File> _getFile() async{
		final directory = await getApplicationDocumentsDirectory();
		return File("${directory.path}/data.json");
	}

	Future<File> _saveData() async {
		var data = json.encode(_toDoList);
		final file = await _getFile();
		return file.writeAsString(data);
	}

	Future<String> _readData() async {
		try {
			final file = await _getFile();
			return file.readAsString();
		} catch (e) {
			return null;
		}
	}
}
